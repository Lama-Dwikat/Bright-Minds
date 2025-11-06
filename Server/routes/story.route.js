import express from "express";
import {storyController} from "../controllers/story.controller.js";
import authMiddleware from "../middleware/auth.middleware.js";
export const storyRouter = express.Router();


storyRouter.post("/story/create", authMiddleware.authentication, storyController.createStory);
storyRouter.put("/story/update/:storyId", authMiddleware.authentication, storyController.updateStory);
storyRouter.delete("/story/delete/:storyId", authMiddleware.authentication, storyController.deleteStory);
storyRouter.get("/story/getstorybyid/:storyId", authMiddleware.authentication, storyController.getStoryById);
storyRouter.get("/story/grtstoriesbychild/:childId", authMiddleware.authentication, storyController.getStoriesByChild);
storyRouter.post("/story/addmedia/:storyId/media", authMiddleware.authentication, storyController.addMediaToStory);
storyRouter.post("/story/submit/:storyId/submit", authMiddleware.authentication, storyController.submitStory); 


