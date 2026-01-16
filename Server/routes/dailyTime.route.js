import { dailywatchController } from "../controllers/dailyTime.controller.js";
import express from "express";

export const dailywatchRouter=express.Router();

dailywatchRouter.post('/dailywatch/calculateRecord/:id',dailywatchController.calculateDailyWatch)
dailywatchRouter.get('/dailywatch/RemainingTime/:id',dailywatchController.calculateTimeRemaining);
dailywatchRouter.get('/dailywatch/canWatch/:id',dailywatchController.canWatch);
dailywatchRouter.get('/dailywatch/getRecord/:id',dailywatchController.getDailywatchRecord);
dailywatchRouter.delete('/dailywatch/deleteRecord/:id',dailywatchController.deleteDailywatch);
dailywatchRouter.get('/dailywatch/getUserWatchRecord/:id',dailywatchController.getUserWatchRecord);
dailywatchRouter.post('/dailywatch/calculatePlay/:id', dailywatchController.calculateDailyPlay);
dailywatchRouter.get('/dailywatch/canPlay/:id', dailywatchController.canPlay);
dailywatchRouter.get('/dailywatch/playTimeRemaining/:id', dailywatchController.playTimeRemaining);



