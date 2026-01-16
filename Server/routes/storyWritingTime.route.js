import express from "express";
import authMiddleware from "../middlewares/auth.middleware.js";
import storyWritingTimeController from "../controllers/storyWritingTime.controller.js";

export const storyWritingTimeRouter = express.Router();

// child timing
storyWritingTimeRouter.post("/storyTime/start", authMiddleware.authentication, storyWritingTimeController.start);
storyWritingTimeRouter.post("/storyTime/ping", authMiddleware.authentication, storyWritingTimeController.ping);
storyWritingTimeRouter.post("/storyTime/end", authMiddleware.authentication, storyWritingTimeController.end);

// parent report
storyWritingTimeRouter.get("/parent/storyTime/report", authMiddleware.authentication, storyWritingTimeController.parentReport);

export default storyWritingTimeRouter;
