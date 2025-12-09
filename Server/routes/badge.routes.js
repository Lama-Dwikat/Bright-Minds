import express from "express";
import badgeController from "../controllers/badge.controller.js";
import authMiddleware from "../middlewares/auth.middleware.js";

export const badgeRouter = express.Router();

badgeRouter.get(
  "/badge/my",
  authMiddleware.authentication,
  badgeController.getChildBadges
);
