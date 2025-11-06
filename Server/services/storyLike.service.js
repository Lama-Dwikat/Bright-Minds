import StoryLike from "../models/StoryLike.js";
import Story from "../models/Story.js";
import { mongo } from "mongoose";


export const StoryLike ={

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

export default StoryLike;