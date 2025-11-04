

import express from "express"
import {videoController} from "../controllers/video.controller.js"

export const videoRouter=express.Router();

videoRouter.get('/video/fetchvVideoFromAPI',videoController.fetchVediosFromAPI);
videoRouter.post('/video/addVideo',videoController.addVideo);
videoRouter.get('/video/getVideoById/:id',videoController.getVideoById);
videoRouter.get('/video/getVideoByTitle/:title',videoController.getVideoByTitle);
videoRouter.get('/video/getVideoByAge/:ageGroup',videoController.getVideosByAge);
videoRouter.get('/video/getAllVideos',videoController.getAllVideos);
videoRouter.get('/video/updateVideoById/:id',videoController.updateVideoById);
videoRouter.get('/video/deleteVideoById/:id',videoController.deleteVideoById);
videoRouter.get('/video/deleteAllVideos',videoController.deleteAllVideos);




