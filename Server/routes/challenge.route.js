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
//challengeRouter.get("/parent/kid-week", authMiddleware.authentication, challengeController.getParentKidWeekProgress);
challengeRouter.get(
  "/challenges/parent/kid-week",
  authMiddleware.authentication,
  challengeController.getParentKidWeekProgress
);
challengeRouter.get(
  "/challenges/weekly-plans/count",
  authMiddleware.authentication,
  challengeController.getWeeklyPlansCount
);

