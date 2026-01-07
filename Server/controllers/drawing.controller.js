import { imageSearchService } from "../services/imageSearch.service.js";
import cloudinaryService from "../services/cloudinary.service.js";
import axios from "axios";
import DrawingActivity from "../models/drawingActivity.model.js";

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

      const activity = await DrawingActivity.findOneAndUpdate(
        { _id: activityId, supervisorId: req.user._id },
        { isActive: false },
        { new: true }
      );

      if (!activity) {
        return res
          .status(404)
          .json({ error: "Activity not found or not yours" });
      }

      return res.status(200).json(activity);
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
  

};
