import cloudinary from "../utils/cloudinary.js";
import storyService from "../services/story.service.js";
import fs from "fs";

export const cloudinaryService = {
  async uploadFile(filePath, folder = "stories") {
    try {
      const result = await cloudinary.uploader.upload(filePath, {
        folder,
        resource_type: "auto"
      });

      fs.unlinkSync(filePath); 

      return result.secure_url;
    } catch (error) {
      throw new Error("Cloudinary upload failed: " + error.message);
    }
  }
};

export default cloudinaryService;