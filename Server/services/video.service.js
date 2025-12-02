

import Video from "../models/video.model.js";
import axios from "axios";
import dotenv from 'dotenv';
import mongoose from "mongoose";
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
  
    async publishVideo(id , isPublished){
       return await Video.findByIdAndUpdate(id , {isPublished:isPublished},{new:true})
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




// Get top 5 videos by views
// async  getTopViews(supervisorId = null) {
//   const filter = supervisorId
//     ? { createdBy: new mongoose.Types.ObjectId(supervisorId) }
//     : {}; // no filter => all supervisors

//   return await Video.find(filter)
//     .sort({ views: -1 })
//     .limit(5)
//     .select("title views -_id");
// },

// // Get videos distribution by category
// async  getVideosDistribution(supervisorId = null) {
//   const matchStage = supervisorId
//     ? { createdBy: new mongoose.Types.ObjectId(supervisorId) }
//     : {};

//   return await Video.aggregate([
//     { $match: matchStage },
//     { $group: { _id: "$category", count: { $sum: 1 } } },
//     { $project: { _id: 0, category: "$_id", count: 1 } },
//   ]);
// },

// // Get number of published videos
// async getVideosNumbers(supervisorId = null) {
//   const filter = {
//     isPublished: true,
//     ...(supervisorId && { createdBy: new mongoose.Types.ObjectId(supervisorId) }),
//   };

//   return await Video.countDocuments(filter);
// },
async  getVideosNumbers(supervisorId = null) {
  let filter = { isPublished: true };

  if (supervisorId && mongoose.Types.ObjectId.isValid(supervisorId)) {
    filter.createdBy = new mongoose.Types.ObjectId(supervisorId);
  }

  return await Video.countDocuments(filter);
},


// // Get total number of videos
// async getTotalVideos(supervisorId = null) {
//   const filter = supervisorId
//     ? { createdBy: new mongoose.Types.ObjectId(supervisorId) }
//     : {};
//   return await Video.countDocuments(filter);
// },

// Get total number of videos
// async getTotalVideos(supervisorId = null) {
//   let filter = {};

//   if (supervisorId && mongoose.Types.ObjectId.isValid(supervisorId)) {
//     filter.createdBy = new mongoose.Types.ObjectId(supervisorId);
//   }

//   return await Video.countDocuments(filter);
// },

// // Get total views
// async getViewsNumbers(supervisorId = null) {
//   const matchStage = supervisorId
//     ? { createdBy: new mongoose.Types.ObjectId(supervisorId) }
//     : {};

//   const result = await Video.aggregate([
//     { $match: matchStage },
//     { $group: { _id: null, totalViews: { $sum: "$views" } } },
//     { $project: { _id: 0, totalViews: 1 } },
//   ]);

//   return result.length > 0 ? result[0].totalViews : 0;
// },
// Get total number of videos
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