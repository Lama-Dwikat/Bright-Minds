

import {videoService} from "../services/video.service.js"


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
      const videos=videoService.getVideosByAge(req.params.ageGroup);
      if (!vedio)
        return res.status(404).json({message:"no vedios found for the specified age group"});
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







}