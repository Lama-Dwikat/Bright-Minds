import ChildDrawing from "../models/childDrawing.model.js";
import DrawingActivity from "../models/drawingActivity.model.js";

export const childDrawingController = {

  async saveChildDrawing(req, res) {
    try {
      const { activityId, drawingImage } = req.body;

      const activity = await DrawingActivity.findById(activityId);
      if (!activity) {
        return res.status(404).json({ error: "Activity not found" });
      }

      const drawing = new ChildDrawing({
        childId: req.user._id,
        activityId,
        drawingImage: {
          data: Buffer.from(drawingImage, "base64"),
          contentType: "image/png",
        },
      });

      await drawing.save();
      res.status(201).json(drawing);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async getChildDrawings(req, res) {
    try {
      const drawings = await ChildDrawing.find({
        childId: req.user._id,
      }).populate("activityId", "title");

      res.status(200).json(drawings);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },
};
