import express from "express";
import storyLikeController from "../controllers/storyLike.controller.js";
import { authMiddleware } from "../middlewares/auth.middleware.js";

export const storyLikeRouter = express.Router();


storyLikeRouter.post("/story/like", authMiddleware.authentication, storyLikeController.addLike);
storyLikeRouter.post("/story/unlike", authMiddleware.authentication, storyLikeController.removeLike);
storyLikeRouter.get("/story/:storyId/liked", authMiddleware.authentication, storyLikeController.checkIfLiked);
storyLikeRouter.get("/story/:storyId/likes/count", storyLikeController.getLikesCount);
storyLikeRouter.get("/story/:storyId/likes/users", storyLikeController.getUsersWhoLiked);
