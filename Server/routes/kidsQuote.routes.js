import express from "express";
import authMiddleware from "../middlewares/auth.middleware.js";
import { roleMiddleware } from "../middlewares/role.middleware.js";
import { kidsQuoteController } from "../controllers/kidsQuote.controller.js";

export const kidsQuoteRouter = express.Router();

kidsQuoteRouter.get(
  "/kids/quote",
  authMiddleware.authentication,
  roleMiddleware(["child"]),
  kidsQuoteController.getQuote
);
