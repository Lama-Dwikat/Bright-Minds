import storyService from "../services/story.service.js";
import mongoose from "mongoose";
import { v2 as cloudinary } from "cloudinary";
import fs from "fs";
import cloudinaryService from "../services/clouninary.service.js";




export const storyController ={

    async createStory (req, res) {
        try {
            const { title, templateId } = req.body;
            const childId = req.user._id; // نفترض أن Middleware تحقق JWT وضعه في req.user

            const story = await storyService.createStory({ title, childId, templateId });
            res.status(201).json(story);
        } catch (error) {
            res.status(400).json({ message: error.message });
        }
    },

     async updateStory (req, res)  {
        try {
            const { storyId } = req.params;
            const storyData = req.body;
            const childId = req.user._id;

            const story = await storyService.updateStory({ storyId, childId, storyData });
            res.status(200).json(story);
        } catch (error) {
            res.status(400).json({ message: error.message });
        }
    },


    async submitStory (req, res) {
        try {
            const { storyId } = req.params;
            const childId = req.user._id;

            const story = await storyService.submitStory({ storyId, childId });
            res.status(200).json(story);
        } catch (error) {
            res.status(400).json({ message: error.message });
        }
    },

     async deleteStory (req, res)  {
        try {
            const { storyId } = req.params;
            const childId = req.user._id;

            const result = await storyService.deleteStory({ storyId, childId });
            res.status(200).json(result);
        } catch (error) {
            res.status(400).json({ message: error.message });
        }
    },


   async getStoryById (req, res)  {
        try {
            const { storyId } = req.params;
            const userId = req.user ? req.user._id : null;

            const story = await storyService.getStoryById({ storyId, userId });
            res.status(200).json(story);
        } catch (error) {
            res.status(400).json({ message: error.message });
        }
    },


    async uploadStoryMedia (req, res)  {
        try {
            const { storyId } = req.params;
            if (!req.file) throw new Error("No file uploaded");

            const url = await cloudinaryService.uploadFile(req.file.path, "stories");

            const updatedStory = await storyService.addMediaToStory({ storyId, mediaUrl: url });

             res.status(200).json({ url, story: updatedStory });
        } catch (error) {
            res.status(400).json({ message: error.message });
        }
    }
     


};
export default storyController; 