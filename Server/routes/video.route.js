

import express from "express"
import {videoController} from "../controllers/video.controller.js"

export const videoRouter=express.Router();

videoRouter.get('/videos/fetchVideosFromAPI',videoController.fetchVediosFromAPI);
videoRouter.post('/videos/addVideo',videoController.addVideo);
videoRouter.get('/videos/getVideoById/:id',videoController.getVideoById);
videoRouter.get('/videos/getVideoByTitle/:title',videoController.getVideoByTitle);
videoRouter.get('/videos/getVideosByAge/:ageGroup',videoController.getVideosByAge);
videoRouter.get('/videos/getVideosByCategory/:category',videoController.getVideosByCategory);
videoRouter.get('/videos/getSupervisorVideos/:id',videoController.getSupervisorVideos);
videoRouter.get('/videos/getPublishedVideos/:ageGroup',videoController.getPublishedVideos);
videoRouter.get('/videos/getAllVideos',videoController.getAllVideos);
videoRouter.put('/videos/updateVideoById/:id',videoController.updateVideoById);
videoRouter.put('/videos/publishVideo/:id', videoController.publishVideo);
videoRouter.put('/videos/incrementView/:id',videoController.incrementViews);
videoRouter.put('/videos/setRecommend/:id',videoController.setRecommend);
videoRouter.get('/videos/getRecommendedVideos/:age',videoController.getRecommendedVideos);
videoRouter.delete('/videos/deleteVideoById/:id',videoController.deleteVideoById);
videoRouter.delete('/videos/deleteAllVideos',videoController.deleteAllVideos);
videoRouter.get('/videos/getTopViews/:id',videoController.getTopViews);
videoRouter.get('/videos/getVideosDistribution/:id',videoController.getVideosDistribution);
videoRouter.get('/videos/getTotalVideos/:id',videoController.getTotalVideos);
videoRouter.get('/videos/getVideosNumbers/:id',videoController.getVideosNumbers);
videoRouter.get('/videos/getViewsNumbers/:id',videoController.getViewsNumbers);
videoRouter.get('/videos/getPublishSupervisorVideos/:id',videoController.getPublishSupervisorVideos);








