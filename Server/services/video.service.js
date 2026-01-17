

import Video from "../models/video.model.js";
import axios from "axios";
import dotenv from 'dotenv';
import mongoose from "mongoose";
import { Notification } from "../models/notification.model.js";
import User from "../models/user.model.js"; // add this at the top

dotenv.config();

export const videoService={


    async fetchVideoFromAPI(topic){
     
 const response = await axios.get("https://www.googleapis.com/youtube/v3/search", {
    params:{
        q:topic,
        key: process.env.YOUTUBE_API_KEY,
        part: "snippet",
        maxResults: 50,}
      // pageToken:nextPageToken|| undefined },
       });

      return  response.data;
        
    },



    async addVideo(videoData){
       const existingVideo= await Video.findOne({url:videoData.url})
       if(existingVideo)
        throw new Error("This video already exists")
      
        const newVideo= new Video(videoData)
        return await newVideo.save();
       
    },

    async getVideoById(id){
        return await Video.findById(id);
        
    },

      async  getVideoByTitle(videoTitle){
     return  await Video.find({title:videoTitle});
          },

    async getVideosByAge(group){
     return await Video.find({ageGroup:group,isPublished:true});
    },

        async getVideosByCategory(cat){
        return await Video.find({category:cat});
      },
          async getSupervisorVideos(supervisorId){
        return await Video.find({createdBy:supervisorId});
      },

       async getPublishedVideos(age){
        return await Video.find({isPublished:true,ageGroup:age});
       },

    async getAllVideos(){
     return await Video.find();
    },


    async updateVideoById(videoId,updateData){
      return await Video.findByIdAndUpdate(videoId, updateData,{new:true});
    },
  
    // async publishVideo(id , isPublished){
    //    return await Video.findByIdAndUpdate(id , {isPublished:isPublished},{new:true})
    // },

      async publishVideo(id, isPublished) {
    const video = await Video.findByIdAndUpdate(
      id,
      { isPublished: isPublished },
      { new: true }
    );

    if (!video) throw new Error("Video not found");

    // ✅ Only send notification if video is now published
    if (isPublished) {
      // Send notification to all users in the relevant age group
      // (Or to a custom list based on your app logic)
      await this.sendVideoNotification(video);
    }

    return video;
  },

  async sendVideoNotification(video) {
    try {
      // Example: find all users in the video's age group
      // Assuming you have a User model:
      const users = await User.find({ ageGroup: video.ageGroup });

      const notifications = users.map((user) => ({
        userId: user._id,
        title: "New Video Published 🎬",
        message: `A new video "${video.title}" is available for you!`,
        type: "video",
        storyId: null,
        drawingId: null,
        activityId: null,
        fromUserId: video.createdBy,
        isRead: false,
      }));

      await Notification.insertMany(notifications);

      console.log(`Notifications sent for video: ${video.title}`);
    } catch (err) {
      console.error("Error sending video notifications:", err);
    }
  },
    async deleteVideoById(id){
     return await Video.findByIdAndDelete(id);
    },

      async deleteAllVideos(){
        return await Video.deleteMany();

    },   

 
  async incrementViews(videoId, userId) {
  const video = await Video.findById(videoId);
  if (!video) throw new Error("Video not found");

  // Only increment if user hasn't viewed yet
  if (!video.viewedBy.includes(userId)) {
    video.views += 1;
    video.viewedBy.push(userId);
    await video.save();
  }

  return video;
},

  async setRecommend(id ,rec){
    return await Video.findByIdAndUpdate(id,{recommended:rec},{new:true});
  },
 async getRecommendedVideos(age){
  return await Video.find({recommended:true,ageGroup:age})
 },




async  getVideosNumbers(supervisorId = null) {
  let filter = { isPublished: true };

  if (supervisorId && mongoose.Types.ObjectId.isValid(supervisorId)) {
    filter.createdBy = new mongoose.Types.ObjectId(supervisorId);
  }

  return await Video.countDocuments(filter);
},



async getTotalVideos(supervisorId = null) {
  let filter = {};

  if (supervisorId && mongoose.Types.ObjectId.isValid(supervisorId)) {
    filter.createdBy = new mongoose.Types.ObjectId(supervisorId);
  }

  return await Video.countDocuments(filter);
},

// Get total views
async getViewsNumbers(supervisorId = null) {
  let matchStage = {};

  if (supervisorId && mongoose.Types.ObjectId.isValid(supervisorId)) {
    matchStage.createdBy = new mongoose.Types.ObjectId(supervisorId);
  }

  const result = await Video.aggregate([
    { $match: matchStage },
    { $group: { _id: null, totalViews: { $sum: "$views" } } },
    { $project: { _id: 0, totalViews: 1 } },
  ]);

  return result.length > 0 ? result[0].totalViews : 0;
},


// Get top 5 videos by views
async getTopViews(supervisorId = null) {
  let filter = {};

  if (supervisorId && mongoose.Types.ObjectId.isValid(supervisorId)) {
    filter.createdBy = new mongoose.Types.ObjectId(supervisorId);
  }

  return await Video.find(filter)
    .sort({ views: -1 })
    .limit(5)
    .select("title views -_id");
},

// Get videos distribution by category
async getVideosDistribution(supervisorId = null) {
  let matchStage = {};

  if (supervisorId && mongoose.Types.ObjectId.isValid(supervisorId)) {
    matchStage.createdBy = new mongoose.Types.ObjectId(supervisorId);
  }

  return await Video.aggregate([
    { $match: matchStage },
    { $group: { _id: "$category", count: { $sum: 1 } } },
    { $project: { _id: 0, category: "$_id", count: 1 } },
  ]);
},


       async getPublishSupervisorVideos(supervisorId){
        return await Video.find({createdBy:supervisorId,isPublished:true});
      },



}