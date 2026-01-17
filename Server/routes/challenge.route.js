import express from "express";
import authMiddleware from "../middlewares/auth.middleware.js";
import { challengeController } from "../controllers/challenge.controller.js";

export const challengeRouter = express.Router();

// templates
challengeRouter.post(
  "/challenges/templates",
  authMiddleware.authentication,
  challengeController.createTemplate
);

challengeRouter.get(
  "/challenges/templates",
  authMiddleware.authentication,
  challengeController.getTemplates
);

// weekly plan
challengeRouter.post(
  "/challenges/weekly-plans",
  authMiddleware.authentication,
  challengeController.createWeeklyPlan
);

challengeRouter.get(
  "/challenges/child/current-week",
  authMiddleware.authentication,
  challengeController.getMyCurrentWeek
);

// random generator
challengeRouter.get(
  "/challenges/random-week",
  authMiddleware.authentication,
  challengeController.generateRandomWeek
);

// mark done
challengeRouter.post(
  "/challenges/mark-done",
  authMiddleware.authentication,
  challengeController.markDone
);
console.log("✅ challengeRouter routes:");
challengeRouter.stack.forEach((r) => {
  if (r.route && r.route.path) {
    const methods = Object.keys(r.route.methods).join(",").toUpperCase();
    console.log(methods, r.route.path);
  }
});
