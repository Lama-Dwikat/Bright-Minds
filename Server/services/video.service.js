

import Video from "../models/video.model.js";
import axios from "axios";
import dotenv from 'dotenv';
dotenv.config();

export const videoService={


    async fetchVideoFromAPI(topic){
     
 const response = await axios.get("https://www.googleapis.com/youtube/v3/search", {
    params:{
        q:topic,
        key: process.env.YOUTUBE_API_KEY,
        part: "snippet",
        maxResults: 5,},
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
     return await Video.find({ageGroup:group});
    },

        async getVideosByCategory(cat){
        return await Video.find({category:cat});
      },
          async getSupervisorVideos(supervisorId){
        return await Video.find({createdBy:supervisorId});
      },

    async getAllVideos(){
     return await Video.find();
    },


  
    async updateVideoById(videoId,updateData){
      return await Video.findByIdAndUpdate(videoId, updateData,{new:true});
    },
  
    async deleteVideoById(id){
     return await Video.findByIdAndDelete(id);
    },

      async deleteAllVideos(){
        return await Video.deleteMany();

    },   


}