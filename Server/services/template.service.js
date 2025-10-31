import Template from "../models/Template.js";
import mongoose from "mongoose";

export const templateService ={

    
     async createTemplate({ name, description, coverImageUrl, defaultTheme, defaultPages }) {
    try {
      const newTemplate = await Template.create({
        name,
        description,
        coverImageUrl,
        defaultTheme,
        defaultPages
      });
      return newTemplate;
    } catch (error) {
      throw new Error("Error creating template: " + error.message);
    }
     },

      async getAllTemplates() {
    try {
      const templates = await Template.find().lean();
      return templates;
    } catch (error) {
      throw new Error("Error fetching templates: " + error.message);
    }
  },
  
  
   async getTemplateById({ templateId }) {
    try {
      const template = await Template.findById(templateId).lean();
      if (!template) {
        throw new Error("Template not found");
      }
      return template;
    } catch (error) {
      throw new Error("Error fetching template: " + error.message);
    }
  },



   async updateTemplate({ templateId, updates }) {
    try {
      const updatedTemplate = await Template.findByIdAndUpdate(
        templateId,
        { $set: updates },
        { new: true, runValidators: true }
      );
      if (!updatedTemplate) {
        throw new Error("Template not found for update");
      }
      return updatedTemplate;
    } catch (error) {
      throw new Error("Error updating template: " + error.message);
    }
  },



   async deleteTemplate({ templateId }) {
    try {
      const deletedTemplate = await Template.findByIdAndDelete(templateId);
      if (!deletedTemplate) {
        throw new Error("Template not found for deletion");
      }
      return { message: "Template deleted successfully" };
    } catch (error) {
      throw new Error("Error deleting template: " + error.message);
    }
  }




};
export default templateService ;