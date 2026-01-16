import Videohistory from "../models/videoHistory.model.js";
import { badgeService } from "./badge.service.js";

export const historyService={

// async createHistory(data){
//  const history= await Videohistory.findOne({userId:data.userId,videoId:data.videoId});
//  if (history){
//       history.watchedAt = new Date();
//      const saved = await history.save();   
//          await badgeService.checkVideoWatchBadges(data.userId); 
//           return saved;
//  }
//    const newHistory=new Videohistory({...data,watchedAt:new Date()});
//   const saved = await newHistory.save();
//   await badgeService.checkVideoWatchBadges(data.userId);
//   return saved;
// },
  async createHistory(data) {
    try {
      // Check if user already watched this video
      let history = await Videohistory.findOne({ userId: data.userId, videoId: data.videoId });

      if (history) {
        history.watchedAt = new Date();
        const saved = await history.save();

        // Check badges
        await badgeService.checkVideoWatchBadges(data.userId);
        return saved;
      }

      // Create new history
      const newHistory = new Videohistory({
        ...data,
        watchedAt: new Date(),
      });
      const saved = await newHistory.save();

      // Check badges
      await badgeService.checkVideoWatchBadges(data.userId);

      return saved;
    } catch (error) {
      console.error("❌ createHistory error:", error.message);
      throw error;
    }
  },


async getHistory(userId){
return await Videohistory.find({userId:userId}).populate("videoId").sort({watchedAt:-1});
},

async getLastWatch(userId, limit=10){
return await Videohistory.find({userId:userId}).populate("videoId").sort({watchedAt:-1}).limit(limit);

},

  async clearHistory(userId) {
    return await Videohistory.deleteMany({ userId });
  },
  

  // Update duration watched
  async updateDuration(historyId, durationWatched) {
    return await Videohistory.findByIdAndUpdate(
      historyId,
      { durationWatched:durationWatched },
      { new: true }
    );
  }



}