import express from "express";
import { notificationController } from "../controllers/notification.controller.js";
import { authMiddleware } from "../middlewares/auth.middleware.js";

export const notificationRouter = express.Router();

notificationRouter.post(
  "/notifications/send",
  authMiddleware.authentication,
  notificationController.sendNotification
);

notificationRouter.get(
  "/notifications/my",
  authMiddleware.authentication,
  notificationController.getMyNotifications
);

notificationRouter.put(
  "/notifications/seen",
  authMiddleware.authentication,
  notificationController.markAsSeen
);
