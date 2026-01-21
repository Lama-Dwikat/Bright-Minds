import { imageSearchService } from "../services/imageSearch.service.js";
import cloudinaryService from "../services/cloudinary.service.js";
import axios from "axios";
import DrawingActivity from "../models/drawingActivity.model.js";
import fs from "fs/promises";
import { extractMaskPaletteFromUrl } from "../services/maskPalette.service.js";
import {
  generateTracingBase64,
  generateColorByNumberOutlineBase64,
  generateColorByNumberMaskBase64,
} from "../services/drawingAi.service.js";
import { Notification } from "../models/notification.model.js";
import User from "../models/user.model.js";

function isHexColor(s) {
  return typeof s === "string" && /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})$/.test(s);
}

async function notifyKidsAndParents({
  supervisorId,
  ageGroup,
  titleForChild,
  msgForChild,
  titleForParent,
  msgForParent,
  activityId,
  fromUserId,
}) {
  const kids = await User.find({
    supervisorId,
    role: "child",
    ageGroup,
  }).select("_id name parentId");

  await Promise.all(
    kids.flatMap((kid) => {
      const notifs = [];

      notifs.push(
        Notification.create({
          userId: kid._id,
          title: titleForChild,
          message: typeof msgForChild === "function" ? msgForChild(kid) : msgForChild,
          type: "activity",
          activityId,
          fromUserId,
          isRead: false,
        })
      );

      if (kid.parentId) {
        notifs.push(
          Notification.create({
            userId: kid.parentId,
            title: titleForParent,
            message: typeof msgForParent === "function" ? msgForParent(kid) : msgForParent,
            type: "activity",
            activityId,
            fromUserId,
            isRead: false,
          })
        );
      }

      return notifs;
    })
  );
}

export const drawingController = {
  async searchExternal(req, res) {
    try {
      const { q, type } = req.query;
      if (!q) return res.status(400).json({ error: "q is required" });

      const extra =
        type === "tracing"
          ? " letter outline"
          : type === "colorByNumber"
          ? " color by number"
          : " line art";

      const results = await imageSearchService.searchImages(`${q}${extra}`);
      return res.status(200).json(results);
    } catch (error) {
      return res.status(500).json({ error: error.message });
    }
  },

  async addFromExternal(req, res) {
    try {
      const { imageUrl, title, type } = req.body;
      if (!imageUrl || !title || !type) {
        return res.status(400).json({ error: "imageUrl, title, type are required" });
      }

      if (!req.user?.ageGroup) {
        return res.status(400).json({ error: "Supervisor age group is missing" });
      }

      const response = await axios.get(imageUrl, { responseType: "arraybuffer" });
      const buffer = Buffer.from(response.data);

      const cloudUrl = await cloudinaryService.uploadBuffer(buffer, "drawing-activities");
const allowedTypes = ["coloring", "tracing", "colorByNumber", "surpriseColor"];
if (!allowedTypes.includes(type)) {
  return res.status(400).json({
    error: `Invalid type. Allowed: ${allowedTypes.join(", ")}`
  });
}

      const activity = await DrawingActivity.create({
        title,
        type,
        ageGroup: req.user.ageGroup,
        supervisorId: req.user._id,
        imageUrl: cloudUrl,
        source: "pixabay",
        isActive: true,
      });

      try {
        await notifyKidsAndParents({
          supervisorId: req.user._id,
          ageGroup: req.user.ageGroup,
          titleForChild: "New Drawing Activity",
          msgForChild: `New drawing activity added: ${activity.title} 🎨`,
          titleForParent: "New activity for your child",
          msgForParent: (kid) => `A new drawing activity was added for ${kid.name}: ${activity.title} 🎨`,
          activityId: activity._id,
          fromUserId: req.user._id,
        });
      } catch (_) {}

      return res.status(201).json(activity);
    } catch (error) {
      return res.status(500).json({ error: error.message });
    }
  },

  async getDrawingActivities(req, res) {
    try {
      const activities = await DrawingActivity.find({
        ageGroup: req.user.ageGroup,
        isActive: true,
      }).select(
        "title type ageGroup imageUrl maskUrl regionsCount maskPalette legend source supervisorId isActive createdAt updatedAt"
      );

      return res.status(200).json(activities);
    } catch (error) {
      return res.status(500).json({ error: error.message });
    }
  },

  async getSupervisorActivities(req, res) {
    try {
      const activities = await DrawingActivity.find({
        supervisorId: req.user._id,
      }).select(
        "title type ageGroup imageUrl maskUrl regionsCount maskPalette legend source supervisorId isActive createdAt updatedAt"
      );

      return res.status(200).json(activities);
    } catch (error) {
      return res.status(500).json({ error: error.message });
    }
  },

  async deactivateActivity(req, res) {
    try {
      const activityId = req.params.id;

      const activity = await DrawingActivity.findOne({
        _id: activityId,
        supervisorId: req.user._id,
      });

      if (!activity) {
        return res.status(404).json({ error: "Activity not found or not yours" });
      }

      activity.isActive = !activity.isActive;
      await activity.save();

      return res.status(200).json({
        message: activity.isActive ? "Activity activated ✅" : "Activity deactivated ✅",
        activity,
      });
    } catch (error) {
      return res.status(500).json({ error: error.message });
    }
  },

  async deleteActivity(req, res) {
    try {
      const activityId = req.params.id;

      const activity = await DrawingActivity.findOneAndDelete({
        _id: activityId,
        supervisorId: req.user._id,
      });

      if (!activity) {
        return res.status(404).json({ error: "Activity not found or not yours" });
      }

      return res.status(200).json({ message: "Activity deleted" });
    } catch (error) {
      return res.status(500).json({ error: error.message });
    }
  },

  async uploadFromDevice(req, res) {
    let localPath = null;

    try {
      const { title, type } = req.body;

      if (!title || !type) {
        return res.status(400).json({ error: "title and type are required" });
      }

      if (!req.user?.ageGroup) {
        return res.status(400).json({ error: "Supervisor age group is missing" });
      }

      if (!req.file) {
        return res.status(400).json({ error: "image file is required" });
      }

      localPath = req.file.path;

      const cloudUrl = await cloudinaryService.uploadFile(localPath, "drawing-activities");
const allowedTypes = ["coloring", "tracing", "colorByNumber", "surpriseColor"];
if (!allowedTypes.includes(type)) {
  return res.status(400).json({
    error: `Invalid type. Allowed: ${allowedTypes.join(", ")}`
  });
}

      const activity = await DrawingActivity.create({
        title,
        type,
        ageGroup: req.user.ageGroup,
        supervisorId: req.user._id,
        imageUrl: cloudUrl,
        source: "upload",
        isActive: true,
      });

      try {
        await notifyKidsAndParents({
          supervisorId: req.user._id,
          ageGroup: req.user.ageGroup,
          titleForChild: "New Drawing Activity",
          msgForChild: `New drawing activity added: ${activity.title} 🎨`,
          titleForParent: "New activity for your child",
          msgForParent: (kid) => `A new drawing activity was added for ${kid.name}: ${activity.title} 🎨`,
          activityId: activity._id,
          fromUserId: req.user._id,
        });
      } catch (_) {}

      return res.status(201).json(activity);
    } catch (error) {
      return res.status(500).json({ error: error.message });
    } finally {
      if (localPath) {
        try {
          await fs.unlink(localPath);
        } catch (_) {}
      }
    }
  },

  async generateTracing(req, res) {
    try {
      const { q } = req.body;

      if (!q?.trim()) return res.status(400).json({ error: "q is required" });
      if (!req.user?.ageGroup) return res.status(400).json({ error: "Supervisor age group is missing" });

      const b64 = await generateTracingBase64(q.trim());
      const buffer = Buffer.from(b64, "base64");

      const cloudUrl = await cloudinaryService.uploadBuffer(buffer, "drawing-activities");

      const activity = await DrawingActivity.create({
        title: `${q.trim()} tracing`,
        type: "tracing",
        ageGroup: req.user.ageGroup,
        supervisorId: req.user._id,
        imageUrl: cloudUrl,
        source: "ai",
        isActive: true,
      });

      try {
        await notifyKidsAndParents({
          supervisorId: req.user._id,
          ageGroup: req.user.ageGroup,
          titleForChild: "New Drawing Activity",
          msgForChild: `New drawing activity added: ${activity.title} 🎨`,
          titleForParent: "New activity for your child",
          msgForParent: (kid) => `A new drawing activity was added for ${kid.name}: ${activity.title} 🎨`,
          activityId: activity._id,
          fromUserId: req.user._id,
        });
      } catch (_) {}

      return res.status(201).json(activity);
    } catch (e) {
      return res.status(500).json({ error: e.message });
    }
  },

  async generateColorByNumber(req, res) {
    try {
      const { q, regionsCount } = req.body;

      if (!q?.trim()) return res.status(400).json({ error: "q is required" });
      if (!req.user?.ageGroup) return res.status(400).json({ error: "Supervisor age group is missing" });

      const n = Number(regionsCount);
      if (!Number.isInteger(n)) {
        return res.status(400).json({ error: "regionsCount must be an integer" });
      }

      const rules = req.user.ageGroup === "5-8" ? { min: 6, max: 10 } : { min: 10, max: 20 };
      if (n < rules.min || n > rules.max) {
        return res.status(400).json({
          error: `regionsCount out of range for ageGroup ${req.user.ageGroup} (${rules.min}-${rules.max})`,
        });
      }

      const outlineB64 = await generateColorByNumberOutlineBase64(q.trim(), n);
      const maskB64 = await generateColorByNumberMaskBase64(q.trim(), n);

      const outlineBuffer = Buffer.from(outlineB64, "base64");
      const maskBuffer = Buffer.from(maskB64, "base64");

      const outlineUrl = await cloudinaryService.uploadBuffer(outlineBuffer, "drawing-activities");
      const maskUrl = await cloudinaryService.uploadBuffer(maskBuffer, "drawing-activities");

      const maskPalette = await extractMaskPaletteFromUrl(maskUrl, n);

      const activity = await DrawingActivity.create({
        title: `${q.trim()} color-by-number`,
        type: "colorByNumber",
        ageGroup: req.user.ageGroup,
        supervisorId: req.user._id,
        imageUrl: outlineUrl,
        maskUrl,
        regionsCount: n,
        maskPalette,
        source: "ai",
        isActive: true,
        legend: [],
      });

      try {
        await notifyKidsAndParents({
          supervisorId: req.user._id,
          ageGroup: req.user.ageGroup,
          titleForChild: "New Drawing Activity",
          msgForChild: `New color-by-number activity added: ${activity.title} 🎨`,
          titleForParent: "New activity for your child",
          msgForParent: (kid) => `A new color-by-number activity was added for ${kid.name}: ${activity.title} 🎨`,
          activityId: activity._id,
          fromUserId: req.user._id,
        });
      } catch (_) {}

      return res.status(201).json(activity);
    } catch (e) {
      return res.status(500).json({ error: e.message });
    }
  },

  async updateColorByNumberLegend(req, res) {
    try {
      const { id } = req.params;
      const { legend } = req.body;

      if (!id) return res.status(400).json({ error: "activity id is required" });
      if (!Array.isArray(legend)) return res.status(400).json({ error: "legend must be an array" });

      const activity = await DrawingActivity.findOne({ _id: id, supervisorId: req.user._id });
      if (!activity) return res.status(404).json({ error: "Activity not found or not yours" });

      if (activity.type !== "colorByNumber") {
        return res.status(400).json({ error: "Activity is not colorByNumber" });
      }

      const n = Number(activity.regionsCount || 0);
      if (!Number.isInteger(n) || n < 1) {
        return res.status(400).json({ error: "Activity regionsCount is missing" });
      }

      if (legend.length !== n) {
        return res.status(400).json({ error: "legend length must equal regionsCount", regionsCount: n });
      }

      const seen = new Set();
      const normalized = [];

      for (const item of legend) {
        const num = Number(item?.number);
        const colorHex = String(item?.colorHex || "").trim();
        const label = typeof item?.label === "string" ? item.label : "";

        if (!Number.isInteger(num) || num < 1 || num > n) {
          return res.status(400).json({ error: "legend.number out of range" });
        }

        if (!isHexColor(colorHex)) {
          return res.status(400).json({ error: "legend.colorHex must be hex like #RRGGBB" });
        }

        if (seen.has(num)) {
          return res.status(400).json({ error: "legend numbers must be unique" });
        }

        seen.add(num);
        normalized.push({ number: num, colorHex, label });
      }

      normalized.sort((a, b) => a.number - b.number);

      activity.legend = normalized;
      await activity.save();

      return res.status(200).json({
        message: "Legend updated",
        activityId: activity._id,
        regionsCount: activity.regionsCount,
        legend: activity.legend,
      });
    } catch (e) {
      return res.status(500).json({ error: e.message });
    }
  },

  async getActivityById(req, res) {
    try {
      const { id } = req.params;
      if (!id) return res.status(400).json({ error: "id is required" });

      const activity = await DrawingActivity.findById(id).select(
        "title type ageGroup imageUrl maskUrl regionsCount maskPalette legend source supervisorId isActive createdAt updatedAt"
      );
      if (!activity) return res.status(404).json({ error: "Activity not found" });

      if (req.user?.role === "child") {
        if (activity.ageGroup !== req.user.ageGroup) return res.status(403).json({ error: "Not allowed" });
        if (!activity.isActive) return res.status(403).json({ error: "Activity is not active" });
      }

      if (req.user?.role === "parent") {
        if (!activity.isActive) return res.status(403).json({ error: "Activity is not active" });
      }

      if (req.user?.role === "supervisor") {
        if (activity.supervisorId.toString() !== req.user._id.toString()) {
          return res.status(403).json({ error: "Not allowed" });
        }
      }

      return res.status(200).json(activity);
    } catch (e) {
      return res.status(500).json({ error: e.message });
    }
  },

  async getSupervisorActivitiesCount(req, res) {
  try {
    const supervisorId = req.user._id;

    const count = await DrawingActivity.countDocuments({ supervisorId });

    return res.status(200).json({ count });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
},
async getAllActivitiesCount(req,res){
  const count = await DrawingActivity.countDocuments({});
  res.json({count});
},
async adminDrawingsAnalytics(req, res) {
  try {
    if (req.user?.role !== "admin") {
      return res.status(403).json({ message: "Forbidden" });
    }

    const totalActivities = await DrawingActivity.countDocuments({});
    const activeActivities = await DrawingActivity.countDocuments({ isActive: true });

    const byTypeAgg = await DrawingActivity.aggregate([
      { $group: { _id: "$type", count: { $sum: 1 } } },
      { $sort: { count: -1 } },
    ]);
    const activitiesByType = {};
    for (const r of byTypeAgg) activitiesByType[r._id || "unknown"] = r.count;

    const byAgeAgg = await DrawingActivity.aggregate([
      { $group: { _id: "$ageGroup", count: { $sum: 1 } } },
      { $sort: { count: -1 } },
    ]);
    const activitiesByAgeGroup = {};
    for (const r of byAgeAgg) activitiesByAgeGroup[r._id || "unknown"] = r.count;

    const latestActivities = await DrawingActivity.find({})
      .select("_id title type ageGroup source isActive createdAt")
      .sort({ createdAt: -1 })
      .limit(5)
      .lean();

    return res.status(200).json({
      totalActivities,
      activeActivities,
      activitiesByType,
      activitiesByAgeGroup,
      latestActivities,
    });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
},


};
