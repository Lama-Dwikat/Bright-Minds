import express from "express";
import { chatController } from "../controllers/chat.controller.js";
import authMiddleware from "../middlewares/auth.middleware.js";

export const chatRouter = express.Router();

chatRouter.post("/chat/send", authMiddleware.authentication, chatController.sendMessage);
chatRouter.get("/chat/conversation/:otherUserId", authMiddleware.authentication, chatController.getConversation);
chatRouter.post("/chat/read", authMiddleware.authentication, chatController.markAsRead);
chatRouter.get("/chat/unread-count", authMiddleware.authentication, chatController.getUnreadCount);

