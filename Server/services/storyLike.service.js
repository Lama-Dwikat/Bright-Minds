
/*import StoryLike from "../models/storyLike.model.js";
import Story from "../models/story.model.js";
import { Notification } from "../models/notification.model.js";
import { mongo } from "mongoose";


export const storyLikeService ={

    async addLike({ storyId, userId }) {
    try {
         const story = await Story.findById(storyId);
      if (!story) throw new Error("Story not found");

      const like = await StoryLike.create({ storyId, userId });
      return { message: "Liked successfully", like };
    } catch (error) {
      if (error.code === 11000) {
        throw new Error("User already liked this story");
      }
      throw new Error("Error adding like: " + error.message);
    }
  },

  
  
  async removeLike({ storyId, userId }) {
    try {
      const result = await StoryLike.findOneAndDelete({ storyId, userId });
      if (!result) throw new Error("Like not found");
      return { message: "Unliked successfully" };
    } catch (error) {
      throw new Error("Error removing like: " + error.message);
    }
  },

    async checkIfLiked({ storyId, userId }) {
    try {
      const like = await StoryLike.findOne({ storyId, userId });
      return !!like; // true أو false
    } catch (error) {
      throw new Error("Error checking like: " + error.message);
    }
  },


   async getLikesCount({ storyId }) {
    try {
      const count = await StoryLike.countDocuments({ storyId });
      return count;
    } catch (error) {
      throw new Error("Error fetching like count: " + error.message);
    }
  },

   async getUsersWhoLiked({ storyId }) {
    try {
      const likes = await StoryLike.find({ storyId })
        .populate("userId", "name email")
        .lean();
      return likes.map(like => like.userId);
    } catch (error) {
      throw new Error("Error fetching users who liked: " + error.message);
    }
  },




};

export default storyLikeService;
*/
// services/storyLike.service.js
import StoryLike from "../models/storyLike.model.js";
import Story from "../models/story.model.js";
import { Notification } from "../models/notification.model.js";

async function checkBadge(storyId) {
  // ✅ نتأكد إن StoryLike موجودة في نفس الملف (import فوق)
  const count = await StoryLike.countDocuments({ storyId });

  if (count === 5 || count === 10 || count === 20) {
    const story = await Story.findById(storyId).populate("childId", "name");

    if (!story) return;

    await Notification.create({
      childId: story.childId._id,
      storyId,
      message: `🏆 Congrats! Your story "${story.title}" reached ${count} likes!`,
    });
  }
}

const storyLikeService = {
  async addLike({ storyId, userId }) {
    // نتأكد ما في لايك سابق
    const existing = await StoryLike.findOne({ storyId, userId });
    if (existing) {
      throw new Error("User already liked this story");
    }

    const like = await StoryLike.create({ storyId, userId });

    // ⬅️ هنا استدعاء checkBadge
    await checkBadge(storyId);

    return {
      message: "Like added successfully",
      like,
    };
  },

  async removeLike({ storyId, userId }) {
    const deleted = await StoryLike.findOneAndDelete({ storyId, userId });
    if (!deleted) {
      throw new Error("Like not found");
    }

    return {
      message: "Like removed successfully",
    };
  },

  async checkIfLiked({ storyId, userId }) {
    const like = await StoryLike.findOne({ storyId, userId });
    return !!like;
  },

  async getLikesCount({ storyId }) {
    const count = await StoryLike.countDocuments({ storyId });
    return count;
  },

  async getUsersWhoLiked({ storyId }) {
    const likes = await StoryLike.find({ storyId }).populate("userId", "name");
    return likes.map((l) => l.userId);
  },
};

export default storyLikeService;
