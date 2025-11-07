import express from "express";
import reviewStoryController from "../controllers/reviewStory.controller.js";
import { authMiddleware } from "../middlewares/auth.middleware.js";
import { reviewPermissions } from "../middlewares/review.middleware.js";
export const reviewStoryRouter = express.Router();

reviewStoryRouter.post("/reviewStory",authMiddleware.authentication,reviewPermissions, reviewStoryController.createReview);
reviewStoryRouter.get("/reviewStory/story/:storyId",authMiddleware.authentication,reviewStoryController.getReviewsByStory);
reviewStoryRouter.get("/reviewStory/supervisor",authMiddleware.authentication,reviewStoryController.getReviewsBySupervisor);
reviewStoryRouter.delete("/reviewStory/:reviewId",authMiddleware.authentication,reviewStoryController.deleteReview);


