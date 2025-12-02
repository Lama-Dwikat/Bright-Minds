import "../controllers/videoHistory.controller.js"
import express from "express";
import { historyController } from "../controllers/videoHistory.controller.js";

export const historyRouter= express.Router();

historyRouter.post('/history/createHistory',historyController.createHistory);
historyRouter.get('/history/getLastWatch/:id',historyController.getLastWatch);
historyRouter.get('/history/getHistory/:id',historyController.getHistory);
historyRouter.put('/history/updateDuration/:id',historyController.updateDuration);
historyRouter.delete('/history/clearHistory/:id',historyController.clearHistory);
