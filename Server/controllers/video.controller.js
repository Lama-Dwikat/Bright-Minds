

import {videoService} from "../services/video.service.js"
import { Notification } from "../models/notification.model.js";


export const videoController={
 
    async fetchVediosFromAPI (req,res){
    try{
  const {topic}=req.query;
  if(!topic)
    return res.status(400).json({ message: "Topic is required" });
   const video= await videoService.fetchVideoFromAPI(topic)
    res.status(200).json(video);

    }catch(error){
    res.status(500).json({ error: error.message });

    }
      },


  async addVideo(req, res) {
  try {
    const newVideo = await videoService.addVideo(req.body);

    if (!newVideo) {
      return res.status(400).json({ message: "Video adding failed" });
    }

    res.status(201).json({message:"video added successfully",newVideo});

  } catch (error) {
    if (error.message === "Video with this title already exists") {
      return res.status(400).json({ message: error.message });
    }

    res.status(500).json({ error: error.message });
  }
},


    async getVideoById(req,res){
        try{
     const video= await videoService.getVideoById(req.params.id);
     if (!video)
        return res.status(404).json({message:"vidoe not found"});
       res.status(200).json(video);
    }catch(error){
    res.status(500).json({ error: error.message });

    }
      },
       async getVideoByTitle(req,res){
       try{
      const video=videoService.getVideoByTitle(req.params.name);
      if (!video)
        return res.status(404).json({message:"vidoe not found"});
       res.status(200).json(video);
    }catch(error){
     res.status(500).json({ error: error.message });

    }
      },

     async getVideosByAge(req,res){
         try{
      const videos= await videoService.getVideosByAge(req.params.ageGroup);
      if (!videos)
        return res.status(404).json({message:"no videos found for the specified age group"});
     res.status(200).json(videos);

    }catch(error){
     res.status(500).json({ error: error.message });

    }
      },



        async getVideosByCategory(req,res){
      try{
     const videos =await videoService.getVideosByCategory(req.params.category);
     res.status(200).json(videos);
    }catch(error){
    res.status(500).json({ error: error.message });

    }
    },
      async getSupervisorVideos(req,res){
      try{
     const videos =await videoService.getSupervisorVideos(req.params.id)
     res.status(200).json(videos);
    }catch(error){
    res.status(500).json({ error: error.message });

    }
    },

      async getPublishedVideos(req,res){
           try{
     const videos =await videoService.getPublishedVideos(req.params.ageGroup);
     res.status(200).json(videos);
    }catch(error){
    res.status(500).json({ error: error.message });

    }    
     },


     async getAllVideos(req,res){
      try{
     const videos =await videoService.getAllVideos();
     res.status(200).json(videos);
    }catch(error){
    res.status(500).json({ error: error.message });

    }
    },




    async updateVideoById(req,res){
      try{
    const updatedVideo=await videoService.updateVideoById(req.params.id,req.body);
    if(!updatedVideo)
       return res.status(404).json({message:"video not found"});
     res.status(200).json(updatedVideo);

    }catch(error){
    res.status(500).json({ error: error.message });
    }
   },

    async publishVideo(req , res){
  
   try{
    const{ isPublished}=req.body;
    const updatedVideo=await videoService.publishVideo(req.params.id,isPublished);
    if(!updatedVideo)
       return res.status(404).json({message:"video not found"});
     res.status(200).json(updatedVideo);

    }catch(error){
    res.status(500).json({ error: error.message });
    }
  },

async deleteVideoById(req,res){
  try{
    const deletedVideo=await videoService.deleteVideoById(req.params.id);
     if (!deletedVideo)
       return res.status(404).json({message:"video not found"});
        res.status(200).json({message:"Video deleted successfully"});
    }catch(error){
    res.status(500).json({ error: error.message });

    }
  },

async deleteAllVideos(req,res){
       try{
      await videoService.deleteAllVideos
      res.status(200).json({message:" videos deleted sucessfully"});
    }catch(error){
 res.status(500).json({error:error.message});
    }

    },   



async incrementViews(req, res) {
  try {
    const userId = req.body.userId; // <-- send this from frontend
    if (!userId) return res.status(400).json({ message: "UserId required" });

    const video = await videoService.incrementViews(req.params.id, userId);
    res.status(200).json(video);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
},


  async setRecommend(req,res){
       try{
        const {recommended} =req.body
      const video=await videoService.setRecommend(req.params.id,recommended);
      res.status(200).json(video);
     }catch(error){
     res.status(500).json({error:error.message});
    }  },

      async getRecommendedVideos(req,res){
       try{
      const videos=await videoService.getRecommendedVideos(req.params.age);
      res.status(200).json(videos);
     }catch(error){
     res.status(500).json({error:error.message});
    }  },



      async getTopViews(req,res){
      try{
     const videos =await videoService.getTopViews(req.params.id);
     res.status(200).json(videos);
    }catch(error){
    res.status(500).json({ error: error.message });

    }
    },
      async  getVideosDistribution(req,res){
      try{
     const videos =await videoService.getVideosDistribution(req.params.id);
     res.status(200).json(videos);
    }catch(error){
    res.status(500).json({ error: error.message });

    }
    },
    
     async  getViewsNumbers(req,res){
      try{
     const videos =await videoService.getViewsNumbers(req.params.id);
     res.status(200).json(videos);
    }catch(error){
    res.status(500).json({ error: error.message });

    }
    },
    

         async  getVideosNumbers(req,res){
      try{
     const videos =await videoService.getVideosNumbers(req.params.id);
     res.status(200).json(videos);
    }catch(error){
    res.status(500).json({ error: error.message });

    }
    },
        async  getTotalVideos(req,res){
      try{
     const videos =await videoService.getTotalVideos(req.params.id);
     res.status(200).json(videos);
    }catch(error){
    res.status(500).json({ error: error.message });

    }
    },
    
 

    async getPublishSupervisorVideos(req,res){
      try{
     const videos =await videoService.getPublishSupervisorVideos(req.params.id)
     res.status(200).json(videos);
    }catch(error){
    res.status(500).json({ error: error.message });

    }
    },



}