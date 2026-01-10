import express from "express";
import authMiddleware from "../middlewares/auth.middleware.js";
import { roleMiddleware } from "../middlewares/role.middleware.js";
import { drawingController } from "../controllers/drawing.controller.js";
import { childDrawingController } from "../controllers/childDrawing.controller.js";
import upload from "../middlewares/multer.middleware.js";

export const drawingRouter = express.Router();

// ========= child routes =========

// الأنشطة المناسبة لعمر الطفل
drawingRouter.get(
  "/activities",
  authMiddleware.authentication,
  drawingController.getDrawingActivities
);

// حفظ رسم الطفل
drawingRouter.post(
  "/drawing/save",
  authMiddleware.authentication,
  childDrawingController.saveChildDrawing
);

// My Drawings – كل رسومات الطفل
drawingRouter.get(
  "/drawings",
  authMiddleware.authentication,
  childDrawingController.getChildDrawings
);

// آخر رسم لـ Activity معيّن
drawingRouter.get(
  "/drawing/last/:activityId",
  authMiddleware.authentication,
  childDrawingController.getLastChildDrawingForActivity
);

// حذف رسم الطفل
drawingRouter.delete(
  "/drawings/:id",
  authMiddleware.authentication,
  childDrawingController.deleteChildDrawing
);

// ========= supervisor routes =========

// بحث خارجي عن صور (Pixabay)
drawingRouter.get(
  "/drawing/searchExternal",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  drawingController.searchExternal
);

// إضافة صورة من Pixabay
drawingRouter.post(
  "/drawing/addFromExternal",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  drawingController.addFromExternal
);

// أنشطة السوبرفايزر
drawingRouter.get(
  "/supervisor/activities",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  drawingController.getSupervisorActivities
);

// تعطيل Activity
drawingRouter.put(
  "/drawing/:id/deactivate",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  drawingController.deactivateActivity
);

// حذف Activity
drawingRouter.delete(
  "/drawing/:id",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  drawingController.deleteActivity
);
// 👩‍🏫 supervisor: كل رسومات الأطفال تحت إشرافه
drawingRouter.get(
  "/supervisor/kids-drawings",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  childDrawingController.getKidsDrawingsForSupervisor
);
// 👩‍🏫 supervisor: إضافة Comment + Rating لرسم طفل
drawingRouter.put(
  "/supervisor/drawings/:id/review",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  childDrawingController.reviewChildDrawing
);

// 👨‍👩‍👧 parent: يشوف رسومات أطفاله
drawingRouter.get(
  "/parent/kids-drawings",
  authMiddleware.authentication,
  roleMiddleware(["parent"]),
  childDrawingController.getKidsDrawingsForParent
);
// رفع صورة من جهاز السوبرفايزر (Upload)
drawingRouter.post(
  "/drawing/upload",
  authMiddleware.authentication,
  roleMiddleware(["supervisor"]),
  upload.single("image"), // اسم الحقل لازم يكون image
  drawingController.uploadFromDevice
);
