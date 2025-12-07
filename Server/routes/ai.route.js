import express from "express";
//import { generateImageFromPrompt ,aiLimiter  } from "../controllers/ai.controller.js";
import authMiddleware from "../middlewares/auth.middleware.js";
import { authorizeStory } from "../middlewares/storyAuth.middleware.js";
import { generateImageFromPrompt } from "../controllers/ai.controller.js";


export const aiRouter = express.Router();
/*aiRouter.post(
  "/generate-image",
  authMiddleware.authentication,
  authorizeStory(["child", "supervisor"], "addMedia"),
  generateImageFromPrompt
);*/

console.log("AI ROUTES LOADED");

aiRouter.post(
  "/generate-image",
  authMiddleware.authentication,
  // aiLimiter,  ← عطليه الآن
  authorizeStory(["child", "supervisor"], "addMedia"),
  
  generateImageFromPrompt
);
/*aiRouter.post(
  "/generate-image",
  authMiddleware.authentication,
  authorizeStory(["child", "supervisor"], "addMedia"),
  generateImageFromPrompt
);*/


