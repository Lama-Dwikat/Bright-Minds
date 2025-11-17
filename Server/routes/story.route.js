import express from "express";
import {storyController} from "../controllers/story.controller.js";
import authMiddleware from "../middlewares/auth.middleware.js";
import { authorizeStory } from "../middlewares/storyAuth.middleware.js";
export const storyRouter = express.Router();


storyRouter.post("/story/create", authMiddleware.authentication,authorizeStory(["child","supervisor"], "create"), storyController.createStory);
storyRouter.put("/story/update/:storyId", authMiddleware.authentication, authorizeStory(["child","supervisor","admin"], "update"), storyController.updateStory);
storyRouter.delete("/story/delete/:storyId", authMiddleware.authentication,  authorizeStory(["child","supervisor","admin"], "delete"),storyController.deleteStory);
storyRouter.get("/story/getstorybyid/:storyId", authMiddleware.authentication,authorizeStory(["child","supervisor","parent","admin"], "view"), storyController.getStoryById);
storyRouter.get("/story/getstoriesbychild/:childId", authMiddleware.authentication,authorizeStory(["child","supervisor","parent","admin"], "view"), storyController.getStoriesByChild);
storyRouter.post("/story/addmedia/:storyId/media", authMiddleware.authentication, authorizeStory(["child","supervisor"], "addMedia"), storyController.addMediaToStory);
storyRouter.post("/story/submit/:storyId/submit", authMiddleware.authentication,authorizeStory(["child"], "submit"), storyController.submitStory); 
storyRouter.post( "/story/resubmit/:storyId/resubmit",authMiddleware.authentication,authorizeStory(["child"], "resubmit"),storyController.resubmitStory);

