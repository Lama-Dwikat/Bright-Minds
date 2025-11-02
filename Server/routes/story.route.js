import express from "express";
import storyController from "../controllers/story.controller.js";
import authMiddleware from "../middleware/auth.middleware.js";
export const storyRouter = express.Router();


router.post("story/", authMiddleware.authentication, storyController.createStory);
router.put("story/:storyId", authMiddleware.authentication, storyController.updateStory);
router.delete("story/:storyId", authMiddleware.authentication, storyController.deleteStory);
router.get("story/:storyId", authMiddleware.authentication, storyController.getStoryById);
router.get("story/child/:childId", authMiddleware.authentication, storyController.getStoriesByChild);
router.post("story/:storyId/media", authMiddleware.authentication, storyController.addMediaToStory);
router.post("story/:storyId/submit", authMiddleware.authentication, storyController.submitStory); 


