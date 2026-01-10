import cloudinaryService from "../services/cloudinary.service.js";
import DrawingActivity from "../models/drawingActivity.model.js";
import { generateCopyDrawingBase64 } from "../services/drawingCopyAi.service.js";

export const drawingCopyAiController = {
  async generateCopyDrawing(req, res) {
    try {
      const { q } = req.body;

      if (!q?.trim()) {
        return res.status(400).json({ error: "q is required" });
      }

      if (!req.user?.ageGroup) {
        return res.status(400).json({ error: "Supervisor age group is missing" });
      }

      const b64 = await generateCopyDrawingBase64(q.trim());
      const buffer = Buffer.from(b64, "base64");

      const cloudUrl = await cloudinaryService.uploadBuffer(
        buffer,
        "drawing-activities"
      );

      const activity = await DrawingActivity.create({
        title: `${q.trim()} copy drawing`,
        // ✅ نخليها colorByNumber عشان الـ enum عندك
        type: "colorByNumber",
        ageGroup: req.user.ageGroup,
        supervisorId: req.user._id,
        imageUrl: cloudUrl,
        source: "ai-copy",
        isActive: true,
      });

      return res.status(201).json(activity);
    } catch (e) {
      console.error("generateCopyDrawing error:", e);
      return res.status(500).json({ error: e.message });
    }
  },
};
