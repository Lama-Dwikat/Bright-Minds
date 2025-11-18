// routes/upload.routes.js
import express from "express";
import multer from "multer";
import cloudinaryService from "../services/cloudinary.service.js";
import { authMiddleware } from "../middlewares/auth.middleware.js";

const upload = multer({ dest: "uploads/" }); // مجلد مؤقت

const router = express.Router();

// POST /api/upload/story-media
router.post(
  "/story-media",
  authMiddleware.authentication,
  upload.single("file"),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({ message: "No file uploaded" });
      }

      const url = await cloudinaryService.uploadFile(req.file.path, "stories");

      return res.status(200).json({ url });
    } catch (error) {
      console.error("Upload error:", error);
      return res
        .status(500)
        .json({ message: "Upload failed", error: error.message });
    }
  }
);

export default router;
