import express from "express";
import authMiddleware from "../middlewares/auth.middleware.js";
import { roleMiddleware } from "../middlewares/role.middleware.js";
import { drawingController } from "../controllers/drawing.controller.js";
import { childDrawingController } from "../controllers/childDrawing.controller.js";
import upload from "../middlewares/multer.middleware.js";

export const drawingRouter = express.Router();

// ========== CHILD ROUTES ==========
drawingRouter.post(
  "/drawing/save",
  authMiddleware.authentication,
  childDrawingController.saveChildDrawing
);

// ✅ جلب رسومات الطفل
drawingRouter.get(
  "/drawings",
  authMiddleware.authentication,
  roleMiddleware(["child"]),
  childDrawingController.getChildDrawings
);

drawingRouter.get(
  "/drawing/last/:activityId",
  authMiddleware.authentication,
  childDrawingController.getLastChildDrawingForActivity
);

drawingRouter.delete(
  "/drawings/:id",
  authMiddleware.authentication,
  childDrawingController.deleteChildDrawing
);

drawingRouter.post(
  "/drawing/submit/:id",
  authMiddleware.authentication,
  roleMiddleware(["child"]),
  childDrawingController.submitChildDrawing
);

drawingRouter.post(
  "/drawing/submitImage",
  authMiddleware.authentication,
  roleMiddleware(["child"]),
  childDrawingController.submitDrawingImage
);

// ========== GENERAL ROUTES ==========
drawingRouter.get(
  "/activities",
  authMiddleware.authentication,
  drawingController.getDrawingActivities
);

drawingRouter.get(
  "/drawing/activity/:id",
  authMiddleware.authentication,
  drawingController.getActivityById
);

// ========== SUPERVISOR ROUTES ==========
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

drawingRouter.put(
  "/drawing/:id/deactivate",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  drawingController.deactivateActivity
);

drawingRouter.delete(
  "/drawing/:id",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  drawingController.deleteActivity
);

// ✅ جلب رسومات الأطفال للسوبرفايزر
drawingRouter.get(
  "/supervisor/kids-drawings",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  childDrawingController.getKidsDrawingsForSupervisor
);

drawingRouter.put(
  "/supervisor/drawings/:id/review",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  childDrawingController.reviewChildDrawing
);

// ✅ جلب صورة رسم للسوبرفايزر (بدون تكرار)
drawingRouter.get(
  "/supervisor/drawings/:id/image",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  childDrawingController.getDrawingImageForSupervisor
);

drawingRouter.post(
  "/drawing/upload",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  upload.single("image"),
  drawingController.uploadFromDevice
);

drawingRouter.post(
  "/drawing/generateTracing",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  drawingController.generateTracing
);

drawingRouter.post(
  "/drawing/generateColorByNumber",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  drawingController.generateColorByNumber
);

drawingRouter.put(
  "/drawing/colorByNumber/:id/legend",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  drawingController.updateColorByNumberLegend
);

// ========== PARENT ROUTES ==========
drawingRouter.get(
  "/parent/kids-drawings",
  authMiddleware.authentication,
  roleMiddleware(["parent"]),
  childDrawingController.getKidsDrawingsForParent
);