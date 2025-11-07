import storyService from "../services/story.service.js";
import mongoose from "mongoose";
import { v2 as cloudinary } from "cloudinary";
import fs from "fs";
import cloudinaryService from "../services/cloudinary.service.js";
import jwt from "jsonwebtoken";



export const storyController ={

    async createStory (req, res) {
        try {
            const { title, templateId ,childId: childIdFromBody} = req.body;
            const { _id: userId, role } = req.user;
              let childId;
             if (role === "child") {
                childId = userId;
                }
                 else if (role === "supervisor") {
                   if (!childIdFromBody) {
                 throw new Error("Child ID is required when supervisor creates a story");
                   }
                  childId = childIdFromBody;
                  }
                   else {
                      throw new Error("You are not allowed to create stories");
                      }

            const story = await storyService.createStory({ title, childId, templateId, role });
            res.status(201).json(story);
        } catch (error) {
            res.status(400).json({ message: error.message });
        }
    },

     async updateStory (req, res)  {
        try {
            const { storyId } = req.params;
            const storyData = req.body;
            const userId = req.user._id;
            const role = req.user.role;
            if (!storyId) {
             return res.status(400).json({ message: "Story ID is required" });
             }
              if (!["child", "supervisor", "admin"].includes(role)) {
              return res.status(403).json({ message: "You are not allowed to update stories" });
               }


            const story = await storyService.updateStory({ storyId,  userId, role, storyData });
            res.status(200).json(story);
        } catch (error) {
            res.status(400).json({ message: error.message });
        }
    },


    async submitStory (req, res) {
        try {
            const { storyId } = req.params;
            const userId = req.user._id;
            const role = req.user.role;

              if (!storyId) {
      return res.status(400).json({ message: "Story ID is required" });
    }

     if (role !== "child") {
      return res.status(403).json({ message: "Only children can submit stories" });
    }

            const story = await storyService.submitStory({ storyId, userId, role });
            res.status(200).json({
      message: "Story submitted successfully",
      story,
    });
        } catch (error) {
            res.status(400).json({ message: error.message });
        }
    },

     async deleteStory (req, res)  {
        try {
            const { storyId } = req.params;
            const userId = req.user._id;
            const role = req.user.role;

             if (!storyId) {
      return res.status(400).json({ message: "Story ID is required" });
    }
     if (role === "parent") {
      return res.status(403).json({ message: "Parents are not allowed to delete stories" });
    }
            const result = await storyService.deleteStory({ storyId, userId, role });
            res.status(200).json({
      success: true,
      message: "Story deleted successfully",
      result,
    });
        } catch (error) {
            res.status(400).json({ message: error.message });
        }
    },


     async getStoryById (req, res)  {
        try {
            const { storyId } = req.params;
            const userId = req.user ? req.user._id : null;
            const role = req.user ? req.user.role : null;
            const story = await storyService.getStoryById({ storyId, userId , role });
            res.status(200).json(story);
        } catch (error) {
            res.status(400).json({ message: error.message });
        }
    },



     async getStoriesByChild(req, res) {
    try {
      const { childId } = req.params;
      const { status } = req.query; 
      const userId = req.user._id; 
      const role = req.user.role;

      const stories = await storyService.getStoriesByChild({ 
        childId, 
        status, 
        userId, 
        role 
      });

      res.status(200).json(stories);

    } catch (error) {
      res.status(400).json({ message: error.message });
    }
    },


    async addMediaToStory(req, res) {
    try {
      const { storyId } = req.params;
      let mediaUrl = req.body.mediaUrl;
      let mediaType = req.body.mediaType || "image";
      const pageIndex = req.body.pageIndex || 0;

      const { role, _id: userId } = req.user;
      const story = await Story.findById(storyId);
      if (!story) return res.status(404).json({ message: "Story not found" });

      if (req.file) {
        mediaUrl = await cloudinaryService.uploadFile(req.file.path, "stories");
        fs.unlinkSync(req.file.path);
      }

      if (!mediaUrl) {
        throw new Error("No media URL or file provided");
      }

      const updatedStory = await storyService.addMediaToStory({
        storyId,
        mediaUrl,
        mediaType,
        pageIndex,
        userId,
        role
      });

      res.status(200).json({ message: "Media added successfully", story: updatedStory });

    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  },

   async resubmitStory(req, res) {
  try {
    const { storyId } = req.params;
    const childId = req.user._id;

    const result = await storyService.resubmitStory({ storyId, childId });

    res.status(200).json(result);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
}






  /*  async uploadStoryMedia (req, res)  {
        try {
            const { storyId } = req.params;
            if (!req.file) throw new Error("No file uploaded");

            const url = await cloudinaryService.uploadFile(req.file.path, "stories");

            const updatedStory = await storyService.addMediaToStory({ storyId, mediaUrl: url });

             res.status(200).json({ url, story: updatedStory });
        } catch (error) {
            res.status(400).json({ message: error.message });
        }
    }
     */


};
export default storyController; 