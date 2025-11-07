import express from "express";
import { generateImageFromPrompt ,aiLimiter  } from "../controllers/ai.controller.js";
import authMiddleware from "../middleware/auth.middleware.js";
import { authorizeStory } from "../middleware/storyAuth.middleware.js";

export const aiRouter = express.Router();
aiRouter.post("/generate-image", authMiddleware.authentication, aiLimiter,authorizeStory(["child"], "addMedia"),generateImageFromPrompt);

