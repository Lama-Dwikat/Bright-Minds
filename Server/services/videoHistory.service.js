import Videohistory from "../models/videoHistory.model.js";


export const historyService={

async createHistory(data){
 const history= await Videohistory.findOne({userId:data.userId,videoId:data.videoId});
 if (history){
      history.watchedAt = new Date();
      return await history.save();
 }
   const newHistory=new Videohistory({...data,watchedAt:new Date()});
   return await newHistory.save();

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