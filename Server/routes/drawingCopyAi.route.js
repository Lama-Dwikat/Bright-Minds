import express from "express";
import authMiddleware from "../middlewares/auth.middleware.js";
import { roleMiddleware } from "../middlewares/role.middleware.js";
import { drawingCopyAiController } from "../controllers/drawingCopyAi.controller.js";

export const drawingCopyAiRouter = express.Router();

drawingCopyAiRouter.post(
  "/drawing/generateCopy",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  drawingCopyAiController.generateCopyDrawing
);
