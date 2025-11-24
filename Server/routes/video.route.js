

import express from "express"
import {videoController} from "../controllers/video.controller.js"

export const videoRouter=express.Router();

videoRouter.get('/videos/fetchVideosFromAPI',videoController.fetchVediosFromAPI);
videoRouter.post('/videos/addVideo',videoController.addVideo);
videoRouter.get('/videos/getVideoById/:id',videoController.getVideoById);
videoRouter.get('/videos/getVideoByTitle/:title',videoController.getVideoByTitle);
videoRouter.get('/videos/getVideoByAge/:ageGroup',videoController.getVideosByAge);
videoRouter.get('/videos/getVideosByCategory/:category',videoController.getVideosByCategory);
videoRouter.get('/videos/getSupervisorVideos/:id',videoController.getSupervisorVideos);
videoRouter.get('/videos/getPublishedVideos/:ageGroup',videoController.getPublishedVideos);
videoRouter.get('/videos/getAllVideos',videoController.getAllVideos);
videoRouter.put('/videos/updateVideoById/:id',videoController.updateVideoById);
videoRouter.put('/videos/publishVideo/:id',videoController.updateVideoById);
videoRouter.put('/videos/incrementView/:id',videoController.incrementViews);
videoRouter.put('/videos/serRecommend/:recommended',videoController.setRecommend);
videoRouter.delete('/videos/deleteVideoById/:id',videoController.deleteVideoById);
videoRouter.delete('/videos/deleteAllVideos',videoController.deleteAllVideos);






