import templateService from "../services/template.service.js";
import mongoose from "mongoose";

export const templateController = {

  async createTemplate(req, res) {
    try {
      const { name, description, coverImageUrl, defaultTheme, defaultPages } = req.body;

      const newTemplate = await templateService.createTemplate({
        name,
        description,
        coverImageUrl,
        defaultTheme,
        defaultPages
      });

      res.status(201).json({
        success: true,
        message: "Template created successfully",
        data: newTemplate
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  },

  async getAllTemplates(req, res) {
    try {
      const templates = await templateService.getAllTemplates();
      res.json({ success: true, data: templates });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  },

  async getTemplateById(req, res) {
    try {
      const { templateId } = req.params;

      if (!mongoose.Types.ObjectId.isValid(templateId)) {
        return res.status(400).json({ success: false, message: "Invalid templateId" });
      }

      const template = await templateService.getTemplateById({ templateId });
      res.json({ success: true, data: template });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  },

  async updateTemplate(req, res) {
    try {
      const { templateId } = req.params;
      const updates = req.body;

      if (!mongoose.Types.ObjectId.isValid(templateId)) {
        return res.status(400).json({ success: false, message: "Invalid templateId" });
      }

      const updatedTemplate = await templateService.updateTemplate({ templateId, updates });
      res.json({ success: true, message: "Template updated successfully", data: updatedTemplate });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  },

  async deleteTemplate(req, res) {
    try {
      const { templateId } = req.params;

      if (!mongoose.Types.ObjectId.isValid(templateId)) {
        return res.status(400).json({ success: false, message: "Invalid templateId" });
      }

      const result = await templateService.deleteTemplate({ templateId });
      res.json({ success: true, message: result.message });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  }

};

export default templateController;
