/*import Badge from "../models/badge.model.js";
import Story from "../models/story.model.js";
import StoryLike from "../models/storyLike.model.js";
import mongoose from "mongoose";
import StoryView from "../models/storyView.model.js";

export const badgeService = {


  async giveBadge(childId, type) {
    const exists = await Badge.findOne({ childId, type });
    if (exists) return;

    await Badge.create({ childId, type });
    console.log(`🏅 Badge earned: ${type} by child ${childId}`);
  },

  // 🥇 أول قصة
  async checkBadgesForStory(childId) {
    const storyCount = await Story.countDocuments({ childId });

    if (storyCount === 1) {
      await this.giveBadge(childId, "First Story");
    }
  },

  // ❤️ نظام لايكات
  async checkBadgesForLikes(storyId) {
    const story = await Story.findById(storyId);
    if (!story) return;

    const likes = await StoryLike.countDocuments({ storyId });

    if (likes >= 10) {
      await this.giveBadge(story.childId, "Loved Story");
    }
  },

  
// 📚 قارئ قصص
async checkReadingBadges(userId) {
  try {
    console.log("📌 BADGE CHECK START for:", userId);

    const userObjectId = new mongoose.Types.ObjectId(userId);

    const readCount = StoryView.countDocuments({
  childId: new mongoose.Types.ObjectId(userId)
})


    console.log("📌 StoryView count =", readCount);

    let earnedBadges = [];

    if (readCount >= 5) {
      const badge = await Badge.findOne({ type: "first_reader" });

      if (badge) {
        const exists = await UserBadge.findOne({
          userId: userObjectId,
          badgeId: badge._id,
        });

        if (!exists) {
          await UserBadge.create({
            userId: userObjectId,
            badgeId: badge._id,
            awardedAt: new Date()
          });

          earnedBadges.push(badge);
          console.log("🏅 Badge granted --> first_reader");
        }
      }
    }

    return earnedBadges;

  } catch (error) {
    console.error("❌ Badge check error:", error.message);
    return [];
  }
}








};

export default badgeService;
*/
import mongoose from "mongoose";
import StoryView from "../models/storyView.model.js";
import Badge from "../models/badge.model.js";

export const badgeService = {

  async checkReadingBadges(childId) {
    try {
      console.log("📌 BADGE CHECK START for:", childId);

      const childObjectId = new mongoose.Types.ObjectId(childId);

      // ✅ count with await
      const readCount = await StoryView.countDocuments({
        childId: childObjectId
      });

      console.log("📌 Total reads =", readCount);

      // 🎯 Badge trigger logic
      if (readCount >= 1) {
        await this.giveBadge(childId, "First Read");
      }

      if (readCount >= 5) {
        await this.giveBadge(childId, "Story Explorer");
      }

      if (readCount >= 10) {
        await this.giveBadge(childId, "Book Worm");
      }

    } catch (error) {
      console.error("❌ Reading Badge error:", error.message);
    }
  },

  async giveBadge(childId, type) {
    // Avoid duplicates
    const exists = await Badge.findOne({ childId, type });
    if (exists) return;

    await Badge.create({ childId, type, earnedAt: new Date() });
    console.log(`🏅 Badge earned: ${type} by child ${childId}`);
  }
};

export default badgeService;

