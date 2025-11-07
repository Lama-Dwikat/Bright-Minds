import storyLikeService from "../services/storyLike.service.js";
import mongoose from "mongoose";

export const storyLikeController = {

  async addLike(req, res) {
    try {
      const { storyId } = req.body;
      const userId = req.user._id;

      if (!storyId || !mongoose.Types.ObjectId.isValid(storyId)) {
        return res.status(400).json({ success: false, message: "Invalid storyId" });
      }

      const result = await storyLikeService.addLike({ storyId, userId });
      res.status(201).json({
        success: true,
        message: result.message,
        data: result.like
      });

    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  },

  async removeLike(req, res) {
    try {
      const { storyId } = req.body;
      const userId = req.user._id;

      if (!storyId || !mongoose.Types.ObjectId.isValid(storyId)) {
        return res.status(400).json({ success: false, message: "Invalid storyId" });
      }

      const result = await storyLikeService.removeLike({ storyId, userId });
      res.json({ success: true, message: result.message });

    } catch (error) {
      res.status(400).json({ success: false, message: error.message });
    }
  },

  async checkIfLiked(req, res) {
    try {
      const { storyId } = req.params;
      const userId = req.user._id;

      if (!mongoose.Types.ObjectId.isValid(storyId)) {
        return res.status(400).json({ success: false, message: "Invalid storyId" });
      }

      const liked = await storyLikeService.checkIfLiked({ storyId, userId });
      res.json({ success: true, liked });

    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  },

  async getLikesCount(req, res) {
    try {
      const { storyId } = req.params;

      if (!mongoose.Types.ObjectId.isValid(storyId)) {
        return res.status(400).json({ success: false, message: "Invalid storyId" });
      }

      const count = await storyLikeService.getLikesCount({ storyId });
      res.json({ success: true, count });

    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  },

  async getUsersWhoLiked(req, res) {
    try {
      const { storyId } = req.params;

      if (!mongoose.Types.ObjectId.isValid(storyId)) {
        return res.status(400).json({ success: false, message: "Invalid storyId" });
      }

      const users = await storyLikeService.getUsersWhoLiked({ storyId });
      res.json({ success: true, users });

    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  }

};

export default storyLikeController;
