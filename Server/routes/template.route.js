import express from "express";
import templateController from "../controllers/template.controller.js";
import { authMiddleware } from "../middlewares/auth.middleware.js";
import { roleMiddleware } from "../middlewares/role.middleware.js";

export const templateRouter = express.Router();

templateRouter.post("/template/", authMiddleware.authentication, roleMiddleware(["supervisor", "admin"]), templateController.createTemplate);
templateRouter.put("/template/:templateId",authMiddleware.authentication,roleMiddleware(["supervisor", "admin"]),templateController.updateTemplate);
templateRouter.delete("/template/:templateId",authMiddleware.authentication,roleMiddleware(["supervisor", "admin"]),templateController.deleteTemplate);
templateRouter.get("/template/", templateController.getAllTemplates);
templateRouter.get("/template/:templateId", templateController.getTemplateById);
