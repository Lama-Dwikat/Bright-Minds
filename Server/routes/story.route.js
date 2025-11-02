import express from "express";
import {storyController} from "../controllers/story.controller.js";
import authMiddleware from "../middleware/auth.middleware.js";
export const storyRouter = express.Router();


storyRouter.post("story/", authMiddleware.authentication, storyController.createStory);
storyRouter.put("story/:storyId", authMiddleware.authentication, storyController.updateStory);
storyRouter.delete("story/:storyId", authMiddleware.authentication, storyController.deleteStory);
storyRouter.get("story/:storyId", authMiddleware.authentication, storyController.getStoryById);
storyRouter.get("story/child/:childId", authMiddleware.authentication, storyController.getStoriesByChild);
storyRouter.post("story/:storyId/media", authMiddleware.authentication, storyController.addMediaToStory);
storyRouter.post("story/:storyId/submit", authMiddleware.authentication, storyController.submitStory); 


