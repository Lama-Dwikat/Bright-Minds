import reviewStoryService from "../services/reviewStory.service.js";
import mongoose from "mongoose";
import { v2 as cloudinary } from "cloudinary";
import fs from "fs";
import cloudinaryService from "../services/cloudinary.service.js";
import jwt from "jsonwebtoken";


export const reviewStoryController ={
 async createReview(req, res) {
    try {
      const { storyId, rating, comment } = req.body;
      const supervisorId = req.user._id; 
      if (!storyId) {
        return res.status(400).json({ success: false, message: "storyId is required" });
      }

      const review = await reviewStoryService.createReview({
        storyId,
        supervisorId,
        rating,
        comment
      });

      res.status(201).json({
        success: true,
        message: "Review created successfully",
        data: review
      });

    } catch (error) {
      console.error("Error in createReview:", error.message);
      res.status(500).json({
        success: false,
        message: error.message || "Failed to create review"
      });
    }
  },


  async getReviewsByStory(req, res) {
    try {
      const { storyId } = req.params;
      const { latestOnly } = req.query; 
      if (!mongoose.Types.ObjectId.isValid(storyId)) {
        return res.status(400).json({ success: false, message: "Invalid storyId" });
      }

      const reviews = await reviewStoryService.getReviewsByStory(storyId, latestOnly === "true");
      res.json({
        success: true,
        data: reviews
      });

    } catch (error) {
      console.error("Error in getReviewsByStory:", error.message);
      res.status(500).json({
        success: false,
        message: error.message || "Failed to fetch story reviews"
      });
    }
  },


  async getReviewsBySupervisor(req, res) {
    try {
      const supervisorId = req.user._id;
      const reviews = await reviewStoryService.getReviewsBySupervisor(supervisorId);

      res.json({
        success: true,
        data: reviews
      });

    } catch (error) {
      console.error("Error in getReviewsBySupervisor:", error.message);
      res.status(500).json({
        success: false,
        message: error.message || "Failed to fetch supervisor reviews"
      });
    }
  },


  async deleteReview(req, res) {
    try {
      const { reviewId } = req.params;
      const supervisorId = req.user._id;

      if (!mongoose.Types.ObjectId.isValid(reviewId)) {
        return res.status(400).json({ success: false, message: "Invalid reviewId" });
      }

      const result = await reviewStoryService.deleteReview({ reviewId, supervisorId });
      res.json({
        success: true,
        message: result.message
      });

    } catch (error) {
      console.error("Error in deleteReview:", error.message);
      res.status(500).json({
        success: false,
        message: error.message || "Failed to delete review"
      });
    }
  }


};
export default reviewStoryController;