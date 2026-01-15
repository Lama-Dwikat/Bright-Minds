import express from "express";
import authMiddleware from "../middlewares/auth.middleware.js";
import { roleMiddleware } from "../middlewares/role.middleware.js";
import { drawingTimeController } from "../controllers/drawingTime.controller.js";

export const drawingTimeRouter = express.Router();

// child
drawingTimeRouter.post(
  "/drawing/time/start",
  authMiddleware.authentication,
  roleMiddleware(["child"]),
  drawingTimeController.start
);

drawingTimeRouter.post(
  "/drawing/time/stop",
  authMiddleware.authentication,
  roleMiddleware(["child"]),
  drawingTimeController.stop
);

// parent report
drawingTimeRouter.get(
  "/parent/drawing-report",
  authMiddleware.authentication,
  roleMiddleware(["parent"]),
  drawingTimeController.parentReport
);
