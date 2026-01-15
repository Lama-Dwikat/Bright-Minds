import express from "express";
import authMiddleware from "../middlewares/auth.middleware.js";
import { roleMiddleware } from "../middlewares/role.middleware.js";
import { colorByNumberProgressController } from "../controllers/colorByNumberProgress.controller.js";

export const colorByNumberProgressRouter = express.Router();

colorByNumberProgressRouter.get(
  "/drawing/color-by-number/progress/:activityId",
  authMiddleware.authentication,
  roleMiddleware(["child"]),
  colorByNumberProgressController.getMyProgress
);

colorByNumberProgressRouter.put(
  "/drawing/color-by-number/progress/:activityId/fill",
  authMiddleware.authentication,
  roleMiddleware(["child"]),
  colorByNumberProgressController.upsertFill
);

colorByNumberProgressRouter.put(
  "/drawing/color-by-number/progress/:activityId/bulk",
  authMiddleware.authentication,
  roleMiddleware(["child"]),
  colorByNumberProgressController.bulkSave
);

colorByNumberProgressRouter.post(
  "/drawing/color-by-number/progress/:activityId/reset",
  authMiddleware.authentication,
  roleMiddleware(["child"]),
  colorByNumberProgressController.reset
);
