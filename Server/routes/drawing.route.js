import express from "express";
import authMiddleware from "../middlewares/auth.middleware.js";
import { roleMiddleware } from "../middlewares/role.middleware.js";
import { drawingController } from "../controllers/drawing.controller.js";
import { childDrawingController } from "../controllers/childDrawing.controller.js";

export const drawingRouter = express.Router();

// 👶 child
drawingRouter.get(
  "/activities",
  authMiddleware.authentication,
  drawingController.getDrawingActivities
);

drawingRouter.post(
  "/drawing/save",
  authMiddleware.authentication,
  childDrawingController.saveChildDrawing
);

drawingRouter.get(
  "/drawings",
  authMiddleware.authentication,
  childDrawingController.getChildDrawings
);

// 👩‍🏫 supervisor
drawingRouter.get(
  "/drawing/searchExternal",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  drawingController.searchExternal
);

drawingRouter.post(
  "/drawing/addFromExternal",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  drawingController.addFromExternal
);

drawingRouter.get(
  "/supervisor/activities",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  drawingController.getSupervisorActivities
);
// 🔴 Deactivate activity (hide from kids)
drawingRouter.put(
  "/drawing/:id/deactivate",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  drawingController.deactivateActivity
);

// 🗑️ Delete activity completely
drawingRouter.delete(
  "/drawing/:id",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  drawingController.deleteActivity
);
