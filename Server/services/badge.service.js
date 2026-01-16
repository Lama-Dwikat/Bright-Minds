import mongoose from "mongoose";
import StoryView from "../models/storyView.model.js";
import Badge from "../models/badge.model.js";
import Story from "../models/story.model.js"; // ✅ ضروري لعدّ القصص
import Game from "../models/game.model.js";


export const badgeService = {
  // 🥇 بادج: أول قصة / قصص الطفل
  async checkBadgesForStory(childId) {
    try {
      // نعدّ كم قصة للطفل
      const storyCount = await Story.countDocuments({ childId });

      console.log("📚 Story count for badges =", storyCount);

      // مثال: لو هاي أول قصة إله
      if (storyCount === 1) {
        await this.giveBadge(childId, "First Story");
      }

      // ممكن تزيدي منطق تاني زي:
      // if (storyCount >= 5) await this.giveBadge(childId, "Story Writer");
      // if (storyCount >= 10) await this.giveBadge(childId, "Pro Story Teller");

    } catch (error) {
      console.error("❌ Story Badge error:", error.message);
    }
  },

  // 📖 بادجات القراءة
  async checkReadingBadges(childId) {
    try {
      console.log("📌 BADGE CHECK START for:", childId);

      const childObjectId = new mongoose.Types.ObjectId(childId);

      // ✅ count with await
      const readCount = await StoryView.countDocuments({
        childId: childObjectId,
      });

      console.log("📌 Total reads =", readCount);

      // 🎯 منطق البادجات حسب عدد القصص المقروءة
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

  // 🏅 دالة مشتركة لإعطاء بادج (تمنع التكرار)
  async giveBadge(childId, type) {
    const exists = await Badge.findOne({ childId, type });
    if (exists) return;

    await Badge.create({ childId, type, earnedAt: new Date() });
    console.log(`🏅 Badge earned: ${type} by child ${childId}`);
  },



async checkGameCompletionBadges(childId) {
  try {
    const completedGamesCount = await Game.countDocuments({
      "playedBy.userId": childId,
      "playedBy.complete": true,
    });

    console.log(`🎮 User ${childId} has completed ${completedGamesCount} games`);

    if (completedGamesCount >= 2) {
      await this.giveBadge(childId, "Champion Gamer"); // only saves if not exists
    }

  } catch (error) {
    console.error("❌ Game Completion Badge error:", error.message);
  }
}

};

export default badgeService;
