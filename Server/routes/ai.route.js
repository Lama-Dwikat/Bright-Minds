import express from "express";
import { generateImageFromPrompt ,aiLimiter  } from "../controllers/ai.controller.js";
import authMiddleware from "../middlewares/auth.middleware.js";
import { authorizeStory } from "../middlewares/storyAuth.middleware.js";

export const aiRouter = express.Router();
//aiRouter.post("/ai/generate-image", authMiddleware.authentication, aiLimiter,authorizeStory(["child", "supervisor"], "addMedia"),generateImageFromPrompt);
/*aiRouter.post("/ai/generate-image",
  authMiddleware.authentication,
  // aiLimiter,   ❌ عطّليه مؤقتًا
  authorizeStory(["child", "supervisor"], "addMedia"),
  generateImageFromPrompt
);*/

