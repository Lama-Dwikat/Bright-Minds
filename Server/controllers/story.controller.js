import storyService from "../services/story.service.js";
import mongoose from "mongoose";
import fs from "fs";
import cloudinaryService from "../services/cloudinary.service.js";
import jwt from "jsonwebtoken";
import ActivityLog from "../models/activityLog.model.js";
import StoryLike from "../models/storyLike.model.js";
import Story from "../models/story.model.js";
import { Notification } from "../models/notification.model.js";
import badgeService from "../services/badge.service.js";
import Badge from "../models/badge.model.js";




export const storyController ={

  async createStory(req, res) {

  try {
    const { title, templateId, pages, childId: childIdFromBody } = req.body;
    const { _id: userId, role } = req.user;

    let childId;
    if (role === "child") {
      childId = userId;
    } else if (role === "supervisor") {
      if (!childIdFromBody) {
        throw new Error("Child ID is required when supervisor creates a story");
      }
      childId = childIdFromBody;
    } else {
      throw new Error("You are not allowed to create stories");
    }

    // 🧩 إنشاء القصة في الـ service فقط
    const story = await storyService.createStory({
      title,
      childId,
      templateId,
      role,
    });

    console.log("✅ Created Story:", story);

       await badgeService.checkBadgesForStory(story.childId);


    // 🎯 الرد النهائي
    res.status(201).json({
      message: "Story created successfully",
      storyId: story.storyId || story._id,
      title: story.title,
      status: story.status,
    });


  } catch (error) {
    console.error("❌ Error creating story:", error);
    res.status(400).json({ message: error.message });
  }
},



  async updateStory(req, res) {
  try {
    const { storyId } = req.params;
    const storyData = req.body;
    const userId = req.user._id.toString(); // تحويل الـ ObjectId إلى string
    const role = req.user.role;

    if (!storyId) {
      return res.status(400).json({ message: "Story ID is required" });
    }
    if (!["child", "supervisor", "admin"].includes(role)) {
      return res.status(403).json({ message: "You are not allowed to update stories" });
    }

    const story = await storyService.updateStory({ storyId, userId, role, storyData });
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


 /*    async getStoryById (req, res)  {
        try {
            const { storyId } = req.params;
            const userId = req.user ? req.user._id : null;
            const role = req.user ? req.user.role : null;
            const story = await storyService.getStoryById({ storyId, userId , role });
            res.status(200).json(story);
        } catch (error) {
            res.status(400).json({ message: error.message });
        }
    },*/
    async getStoryById(req, res) {
  try {
    const { storyId } = req.params;
    const requesterId = req.user._id;
    const role = req.user.role;

    const story = await Story.findById(storyId)
      .populate("childId", "name parentId")
      .lean();

    if (!story)
      return res.status(404).json({ message: "Story not found" });

    const isOwner = story.childId?._id?.toString() === requesterId.toString();
    const isParent =
      story.childId?.parentId?.toString() === requesterId.toString();

    // 🔥 IMPORTANT FIX:
    // Allow access if story is published
    if (story.publicVisibility === true || story.status === "published") {
      return res.status(200).json(story);
    }

    // Normal rules for not published stories
    if (role === "child" && !isOwner)
      return res.status(403).json({
        message: "You are not allowed to view this story",
      });

    if (role === "parent" && !isParent)
      return res.status(403).json({
        message: "You are not allowed to view this story",
      });

await badgeService.checkReadingBadges(requesterId);

    // otherwise allow access
    return res.status(200).json(story);

  } catch (error) {
    res.status(500).json({
      message: `Error fetching story: ${error.message}`,
    });
  }
}
,



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
},

async getStoriesForSupervisor(req, res) {
  try {
    const supervisorId = req.user._id;
    const role = req.user.role;
    const { status } = req.query; 

    const stories = await storyService.getStoriesForSupervisor({
      supervisorId,
      role,
      status,
    });

    res.status(200).json(stories);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
},

async publishStory(req, res) {
  try {
    const { storyId } = req.params;
    const supervisorId = req.user._id;

    const story = await Story.findById(storyId);

    if (!story) {
      return res.status(404).json({ message: "Story not found" });
    }

    if (req.user.role !== "supervisor") {
      return res.status(403).json({ message: "Only supervisors can publish stories" });
    }

    // 🔥 هنا المشكلة.. لازم تحدث status أيضاً!
    story.status = "published";       // ← أضف هذا
    story.publicVisibility = true;    // ← ممتاز عندك
    story.publishedBy = supervisorId;
    story.publishedAt = new Date();   // ← optional but useful

    await story.save();

    await Notification.create({
      childId: story.childId,
      storyId: storyId,
      message: `🎉 Your story "${story.title}" has been published for other kids!`,
    });

    return res.status(200).json({ message: "Story published successfully" });

  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
},
async getPublishedStories(req, res) {
  try {
    const stories = await Story.find({ publicVisibility: true })
      .populate("childId", "name ageGroup")
      .sort({ createdAt: -1 });

    res.status(200).json(stories);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
},
async getTopStories(req, res) {
  try {
    const top = await StoryLike.aggregate([
      { $group: { _id: "$storyId", totalLikes: { $sum: 1 } } },
      { $sort: { totalLikes: -1 } },
      { $limit: 5 }
    ]);

    const storyIds = top.map(t => t._id);

    const stories = await Story.find({ _id: { $in: storyIds } })
      .populate("childId", "name");

    res.status(200).json(stories);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
} ,
async trackStoryRead(req, res) {
  try {
    const childId = req.user._id;
    const storyId = req.params.id;

    await StoryView.findOneAndUpdate(
      { storyId, childId },
      { viewedAt: new Date() },
      { upsert: true }
    );

    // 🟣 Check badges
    await badgeService.checkReadingBadges(childId);

    // 🟣 Fetch updated badges list
    const badges = await Badge.find({ childId });

    return res.json({
      success: true,
      message: "Story read tracked",
      badges,
    });

  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
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