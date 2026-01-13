import { imageSearchService } from "../services/imageSearch.service.js";
import cloudinaryService from "../services/cloudinary.service.js";
import axios from "axios";
import DrawingActivity from "../models/drawingActivity.model.js";
import fs from "fs/promises";
import { generateTracingBase64 } from "../services/drawingAi.service.js";
import { Notification } from "../models/notification.model.js";
import User from "../models/user.model.js";

export const drawingController = {

  // 🔍 supervisor search external images
  async searchExternal(req, res) {
    try {
      const { q, type } = req.query;
      if (!q) return res.status(400).json({ error: "q is required" });

      const extra =
        type === "tracing" ? " letter outline" :
        type === "colorByNumber" ? " color by number" :
        " line art";

      const results = await imageSearchService.searchImages(`${q}${extra}`);
      return res.status(200).json(results);
    } catch (error) {
      return res.status(500).json({ error: error.message });
    }
  },

  // ➕ supervisor add image from pixabay
  async addFromExternal(req, res) {
    try {
      const { imageUrl, title, type } = req.body;
      if (!imageUrl || !title || !type) {
        return res.status(400).json({ error: "imageUrl, title, type are required" });
      }
if (!req.user.ageGroup) {
  return res.status(400).json({ error: "Supervisor age group is missing" });
}

      const response = await axios.get(imageUrl, { responseType: "arraybuffer" });
      const buffer = Buffer.from(response.data);

      const cloudUrl = await cloudinaryService.uploadBuffer(
        buffer,
        "drawing-activities"
      );

      const activity = await DrawingActivity.create({
        title,
        type,
        ageGroup: req.user.ageGroup,
        supervisorId: req.user._id,
        imageUrl: cloudUrl,
        source: "pixabay",
      });
      // 🔔 notify all supervisor kids + their parents about new activity
try {
  const kids = await User.find({
    supervisorId: req.user._id,
    role: "child",
    ageGroup: req.user.ageGroup,
  }).select("_id name parentId");

  await Promise.all(
    kids.flatMap((kid) => {
      const notifs = [];

      // للطفل
      notifs.push(
        Notification.create({
          userId: kid._id,
          title: "New Drawing Activity",
          message: `New drawing activity added: ${activity.title} 🎨`,
          type: "activity",
          activityId: activity._id,
          fromUserId: req.user._id,
          isRead: false,
        })
      );

      // للأهل
      if (kid.parentId) {
        notifs.push(
          Notification.create({
            userId: kid.parentId,
            title: "New activity for your child",
            message: `A new drawing activity was added for ${kid.name}: ${activity.title} 🎨`,
            type: "activity",
            activityId: activity._id,
            fromUserId: req.user._id,
            isRead: false,
          })
        );
      }

      return notifs;
    })
  );
} catch (e) {
  console.log("notify new activity error:", e.message);
}


      return res.status(201).json(activity);

    } catch (error) {
      return res.status(500).json({ error: error.message });
    }
  },

  // 👶 child get activities
  async getDrawingActivities(req, res) {
    try {
      const activities = await DrawingActivity.find({
        ageGroup: req.user.ageGroup,
        isActive: true,
      });
      res.status(200).json(activities);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // 👩‍🏫 supervisor get own activities
  async getSupervisorActivities(req, res) {
    try {
      const activities = await DrawingActivity.find({
        supervisorId: req.user._id,
      });
      res.status(200).json(activities);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

    // ================== DEACTIVATE ACTIVITY ==================
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

    // 2) Toggle
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


  // ================== DELETE ACTIVITY (HARD DELETE) ==================
  async deleteActivity(req, res) {
    try {
      const activityId = req.params.id;

      const activity = await DrawingActivity.findOneAndDelete({
        _id: activityId,
        supervisorId: req.user._id,
      });

      if (!activity) {
        return res
          .status(404)
          .json({ error: "Activity not found or not yours" });
      }

      return res.status(200).json({ message: "Activity deleted" });
    } catch (error) {
      return res.status(500).json({ error: error.message });
    }
  },
  

   // ⬆️ supervisor upload image from device
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

    // ✅ diskStorage -> path موجود
    localPath = req.file.path;

    // 1) upload to cloudinary from file path
    const cloudUrl = await cloudinaryService.uploadFile(
      localPath,
      "drawing-activities"
    );

    // 2) create activity
    const activity = await DrawingActivity.create({
      title,
      type,
      ageGroup: req.user.ageGroup,
      supervisorId: req.user._id,
      imageUrl: cloudUrl,
      source: "upload",
    });
// 🔔 notify all supervisor kids + their parents about new activity
try {
  const kids = await User.find({
    supervisorId: req.user._id,
    role: "child",
    ageGroup: req.user.ageGroup,
  }).select("_id name parentId");

  await Promise.all(
    kids.flatMap((kid) => {
      const notifs = [];

      // للطفل
      notifs.push(
        Notification.create({
          userId: kid._id,
          title: "New Drawing Activity",
          message: `New drawing activity added: ${activity.title} 🎨`,
          type: "activity",
          activityId: activity._id,
          fromUserId: req.user._id,
          isRead: false,
        })
      );

      // للأهل
      if (kid.parentId) {
        notifs.push(
          Notification.create({
            userId: kid.parentId,
            title: "New activity for your child",
            message: `A new drawing activity was added for ${kid.name}: ${activity.title} 🎨`,
            type: "activity",
            activityId: activity._id,
            fromUserId: req.user._id,
            isRead: false,
          })
        );
      }

      return notifs;
    })
  );
} catch (e) {
  console.log("notify new activity error:", e.message);
}

    return res.status(201).json(activity);

    
  } catch (error) {
    console.error("uploadFromDevice error:", error);
    return res.status(500).json({ error: error.message });
  } finally {
    // ✅ clean uploads folder
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
// 🔔 notify all supervisor kids + their parents about new activity
try {
  const kids = await User.find({
    supervisorId: req.user._id,
    role: "child",
    ageGroup: req.user.ageGroup,
  }).select("_id name parentId");

  await Promise.all(
    kids.flatMap((kid) => {
      const notifs = [];

      // للطفل
      notifs.push(
        Notification.create({
          userId: kid._id,
          title: "New Drawing Activity",
          message: `New drawing activity added: ${activity.title} 🎨`,
          type: "activity",
          activityId: activity._id,
          fromUserId: req.user._id,
          isRead: false,
        })
      );

      // للأهل
      if (kid.parentId) {
        notifs.push(
          Notification.create({
            userId: kid.parentId,
            title: "New activity for your child",
            message: `A new drawing activity was added for ${kid.name}: ${activity.title} 🎨`,
            type: "activity",
            activityId: activity._id,
            fromUserId: req.user._id,
            isRead: false,
          })
        );
      }

      return notifs;
    })
  );
} catch (e) {
  console.log("notify new activity error:", e.message);
}

    return res.status(201).json(activity);
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}


};
