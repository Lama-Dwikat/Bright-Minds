import express from "express";
import multer from "multer";
import  cloudinaryService  from "../services/cloudinary.service.js";

const router = express.Router();

// 🟣 بدل تخزين الملف على الهارد → استخدمي الذاكرة مباشرة
const storage = multer.memoryStorage();
const upload = multer({ storage });

router.post("/story-media", upload.single("file"), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: "No file uploaded" });
    }

    // 🟣 رفع الصورة من buffer مباشرة
    const url = await cloudinaryService.uploadBuffer(req.file.buffer, "stories");

    return res.json({ url });
  } catch (error) {
    console.error("Upload route error FULL:", error);

return res.status(500).json({
  message: "Upload failed",
  error: error.message,
  details: error,
});

  }
});

export default router;
