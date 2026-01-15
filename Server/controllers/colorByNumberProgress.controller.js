import ChildColorByNumberProgress from "../models/childColorByNumberProgress.model.js";
import DrawingActivity from "../models/drawingActivity.model.js";

function isHexColor(s) {
  return typeof s === "string" && /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})$/.test(s);
}

function computePercent(fillsCount, regionsCount) {
  if (!regionsCount) return 0;
  const p = Math.floor((fillsCount / regionsCount) * 100);
  return Math.max(0, Math.min(100, p));
}

export const colorByNumberProgressController = {
  async getMyProgress(req, res) {
    try {
      if (req.user?.role !== "child") {
        return res.status(403).json({ error: "Only child can access progress" });
      }

      const { activityId } = req.params;
      if (!activityId) return res.status(400).json({ error: "activityId is required" });

      const activity = await DrawingActivity.findById(activityId).select(
        "_id type regionsCount ageGroup isActive"
      );
      if (!activity) return res.status(404).json({ error: "Activity not found" });
      if (activity.type !== "colorByNumber") {
        return res.status(400).json({ error: "Activity is not colorByNumber" });
      }
      if (!activity.isActive) return res.status(403).json({ error: "Activity is not active" });

      let progress = await ChildColorByNumberProgress.findOne({
        childId: req.user._id,
        activityId,
      });

      if (!progress) {
        const regionsCountSnapshot = Number(activity.regionsCount || 1);

        progress = await ChildColorByNumberProgress.create({
          childId: req.user._id,
          activityId,
          regionsCountSnapshot,
          fills: [],
          percent: 0,
          isCompleted: false,
          completedAt: null,
        });
      }

      return res.status(200).json(progress);
    } catch (e) {
      return res.status(500).json({ error: e.message });
    }
  },

  async upsertFill(req, res) {
    try {
      if (req.user?.role !== "child") {
        return res.status(403).json({ error: "Only child can update progress" });
      }

      const { activityId } = req.params;
      const { regionId, colorHex } = req.body;

      if (!activityId) return res.status(400).json({ error: "activityId is required" });
      if (!Number.isInteger(regionId) || regionId < 1) {
        return res.status(400).json({ error: "regionId must be an integer >= 1" });
      }
      if (!isHexColor(colorHex)) {
        return res.status(400).json({ error: "colorHex must be a hex string like #RRGGBB" });
      }

      const activity = await DrawingActivity.findById(activityId).select(
        "_id type regionsCount isActive"
      );
      if (!activity) return res.status(404).json({ error: "Activity not found" });
      if (activity.type !== "colorByNumber") {
        return res.status(400).json({ error: "Activity is not colorByNumber" });
      }
      if (!activity.isActive) return res.status(403).json({ error: "Activity is not active" });

      const regionsCount = Number(activity.regionsCount || 1);
      if (regionId > regionsCount) {
        return res.status(400).json({ error: "regionId exceeds regionsCount" });
      }

      let progress = await ChildColorByNumberProgress.findOne({
        childId: req.user._id,
        activityId,
      });

      if (!progress) {
        progress = await ChildColorByNumberProgress.create({
          childId: req.user._id,
          activityId,
          regionsCountSnapshot: regionsCount,
          fills: [],
          percent: 0,
          isCompleted: false,
          completedAt: null,
        });
      }

      const now = new Date();
      const idx = progress.fills.findIndex((f) => f.regionId === regionId);

      if (idx >= 0) {
        progress.fills[idx].colorHex = colorHex;
        progress.fills[idx].updatedAt = now;
      } else {
        progress.fills.push({ regionId, colorHex, updatedAt: now });
      }

      progress.percent = computePercent(progress.fills.length, progress.regionsCountSnapshot);

      if (progress.percent === 100 && !progress.isCompleted) {
        progress.isCompleted = true;
        progress.completedAt = now;
      }

      await progress.save();

      return res.status(200).json(progress);
    } catch (e) {
      return res.status(500).json({ error: e.message });
    }
  },

  async bulkSave(req, res) {
    try {
      if (req.user?.role !== "child") {
        return res.status(403).json({ error: "Only child can update progress" });
      }

      const { activityId } = req.params;
      const { fills } = req.body;

      if (!activityId) return res.status(400).json({ error: "activityId is required" });
      if (!Array.isArray(fills)) return res.status(400).json({ error: "fills must be an array" });

      const activity = await DrawingActivity.findById(activityId).select(
        "_id type regionsCount isActive"
      );
      if (!activity) return res.status(404).json({ error: "Activity not found" });
      if (activity.type !== "colorByNumber") {
        return res.status(400).json({ error: "Activity is not colorByNumber" });
      }
      if (!activity.isActive) return res.status(403).json({ error: "Activity is not active" });

      const regionsCount = Number(activity.regionsCount || 1);
      const now = new Date();

      const normalized = [];
      const seen = new Set();

      for (const item of fills) {
        const regionId = item?.regionId;
        const colorHex = item?.colorHex;

        if (!Number.isInteger(regionId) || regionId < 1 || regionId > regionsCount) continue;
        if (!isHexColor(colorHex)) continue;

        if (seen.has(regionId)) continue;
        seen.add(regionId);

        normalized.push({ regionId, colorHex, updatedAt: now });
      }

      let progress = await ChildColorByNumberProgress.findOne({
        childId: req.user._id,
        activityId,
      });

      if (!progress) {
        progress = await ChildColorByNumberProgress.create({
          childId: req.user._id,
          activityId,
          regionsCountSnapshot: regionsCount,
          fills: normalized,
          percent: computePercent(normalized.length, regionsCount),
          isCompleted: false,
          completedAt: null,
        });
      } else {
        progress.fills = normalized;
        progress.percent = computePercent(normalized.length, progress.regionsCountSnapshot);

        if (progress.percent === 100 && !progress.isCompleted) {
          progress.isCompleted = true;
          progress.completedAt = now;
        }
        if (progress.percent < 100) {
          progress.isCompleted = false;
          progress.completedAt = null;
        }

        await progress.save();
      }

      return res.status(200).json(progress);
    } catch (e) {
      return res.status(500).json({ error: e.message });
    }
  },

  async reset(req, res) {
    try {
      if (req.user?.role !== "child") {
        return res.status(403).json({ error: "Only child can reset progress" });
      }

      const { activityId } = req.params;
      if (!activityId) return res.status(400).json({ error: "activityId is required" });

      const progress = await ChildColorByNumberProgress.findOne({
        childId: req.user._id,
        activityId,
      });

      if (!progress) {
        return res.status(200).json({ message: "No progress to reset" });
      }

      progress.fills = [];
      progress.percent = 0;
      progress.isCompleted = false;
      progress.completedAt = null;

      await progress.save();

      return res.status(200).json({ message: "Reset done", progress });
    } catch (e) {
      return res.status(500).json({ error: e.message });
    }
  },
};
