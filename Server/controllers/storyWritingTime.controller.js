import storyWritingTimeService from "../services/storyWritingTime.service.js";

export const storyWritingTimeController = {
  // child
  async start(req, res) {
    try {
      const childId = req.user._id;
      if (req.user.role !== "child") return res.status(403).json({ message: "Only child can start timing" });

      const { storyId } = req.body;
      if (!storyId) return res.status(400).json({ message: "storyId is required" });

      const session = await storyWritingTimeService.startOrResumeSession({ childId, storyId });

      return res.status(200).json({
        success: true,
        sessionId: session._id,
        startAt: session.startAt,
      });
    } catch (e) {
      return res.status(500).json({ message: e.message });
    }
  },

  async ping(req, res) {
    try {
      const childId = req.user._id;
      if (req.user.role !== "child") return res.status(403).json({ message: "Only child can ping timing" });

      const { sessionId } = req.body;
      if (!sessionId) return res.status(400).json({ message: "sessionId is required" });

      const session = await storyWritingTimeService.pingSession({ sessionId, childId });

      return res.status(200).json({ success: true, sessionId: session._id, lastActiveAt: session.lastActiveAt });
    } catch (e) {
      return res.status(500).json({ message: e.message });
    }
  },

  async end(req, res) {
    try {
      const childId = req.user._id;
      if (req.user.role !== "child") return res.status(403).json({ message: "Only child can end timing" });

      const { sessionId, reason } = req.body;
      if (!sessionId) return res.status(400).json({ message: "sessionId is required" });

      const session = await storyWritingTimeService.endSession({ sessionId, childId, reason });

      return res.status(200).json({
        success: true,
        sessionId: session._id,
        durationSec: session.durationSec,
        endAt: session.endAt
      });
    } catch (e) {
      return res.status(500).json({ message: e.message });
    }
  },

  // parent
  async parentReport(req, res) {
    try {
      if (req.user.role !== "parent") return res.status(403).json({ message: "Only parent can view report" });

      const rangeDays = Number(req.query.rangeDays ?? 7);
      const report = await storyWritingTimeService.getParentReport({ parentId: req.user._id, rangeDays });

      return res.status(200).json({ success: true, data: report });
    } catch (e) {
      return res.status(500).json({ message: e.message });
    }
  }
};

export default storyWritingTimeController;
