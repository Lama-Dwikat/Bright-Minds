import OpenAI from "openai";
import cloudinaryService from "../services/cloudinary.service.js";
import { Buffer } from "buffer";
import Story from "../models/story.model.js"; 
import ActivityLog from "../models/activityLog.model.js"; 
import rateLimit from "express-rate-limit";
import cloudinary from 'cloudinary';




console.log("OPENAI API KEY:", process.env.OPENAI_API_KEY);

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

// Cloudinary config
cloudinary.v2.config({
  cloud_name: process.env.CLOUDINARY_NAME,
  api_key: process.env.CLOUDINARY_KEY,
  api_secret: process.env.CLOUDINARY_SECRET,
});

// ===== Rate limiter =====
export const aiLimiter = rateLimit({
  windowMs: 10 * 60 * 1000, // 10 minutes
  max: (req) => req.user.role === "supervisor" ? 20 : 5, // supervisors can generate more
  message: {
    success: false,
    message: "You have reached the temporary limit for AI image generation. Try again later.",
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.user._id.toString(), // limit per user
});

// ===== Generate image =====
export const generateImageFromPrompt = async (req, res) => {
  const userId = req.user._id;
  const userRole = req.user.role || "child";
  let { prompt, storyId, pageNumber = 1, style = "cartoon" } = req.body;

  // ===== Input validation =====
  if (!prompt || !storyId) {
    return res.status(400).json({ success: false, message: "prompt and storyId are required" });
  }

  try {
    // ===== Sanitization =====
    prompt = prompt.trim().slice(0, 300); // max 300 characters
    const forbiddenWords = ["kill", "blood", "weapon", "violence", "sword"];
    const hasBadWord = forbiddenWords.some(word => prompt.toLowerCase().includes(word));
    if (hasBadWord) {
      await ActivityLog.create({ userId, prompt, status: "error" });
      return res.status(400).json({ success: false, message: "The prompt contains forbidden words." });
    }

    // ===== Moderation check =====
    const modResp = await openai.moderations.create({
      model: "omni-moderation-latest",
      input: prompt,
    });
    if (modResp.results?.[0]?.flagged) {
      await ActivityLog.create({ userId, prompt, status: "error" });
      return res.status(400).json({ success: false, message: "The prompt is not allowed due to safety policies." });
    }

    // ===== Generate image =====
    const fullPrompt = `${prompt}. The image should be in ${style} style suitable for children.`;
    const imageResp = await openai.images.generate({
      model: "gpt-image-1",
      prompt: fullPrompt,
      size: "1024x1024",
    });

    const b64 = imageResp.data?.[0]?.b64_json;
    if (!b64) throw new Error("No image received from AI provider");

    // ===== Upload to Cloudinary (organized by story/page) =====
    const buffer = Buffer.from(b64, "base64");
    const uploadResult = await new Promise((resolve, reject) => {
      const uploadStream = cloudinary.v2.uploader.upload_stream(
        { folder: `kids-platform/stories/${storyId}/page-${pageNumber}` },
        (err, result) => (err ? reject(err) : resolve(result))
      );
      uploadStream.end(buffer);
    });

    const imageUrl = uploadResult.secure_url;

    // ===== Save to Story =====
    const story = await Story.findById(storyId);
    if (!story) throw new Error("Story not found");

    let page = story.pages.find(p => p.pageNumber === pageNumber);
    if (!page) {
      page = { pageNumber, elements: [], assignedToRole: "child" }; // default role
      story.pages.push(page);
    }

    // ===== Supervisor -> Child workflow =====
    if (userRole === "supervisor") {
      page.assignedToRole = "child"; // next role to complete
    }

    const newElement = {
      type: "image",
      content: "",
      role: userRole, // store who generated this element
      media: {
        mediaType: "image",
        url: imageUrl,
        page: pageNumber,
        elementOrder: (page.elements?.length || 0) + 1
      },
      x: 0,
      y: 0,
      width: 400,
      height: 400,
    };
    page.elements.push(newElement);

    story.aiGenerated = true;
    story.aiPrompts = story.aiPrompts || [];
    story.aiPrompts.push({ prompt, role: userRole });
    story.lastEditedBy = userId;
    story.lastEditedRole = userRole;
    await story.save();

    // ===== Log successful activity =====
    await ActivityLog.create({ userId, prompt, status: "success", role: userRole });

    // ===== Send response =====
    res.json({ success: true, imageUrl, element: newElement, storyId: story._id });

  } catch (err) {
    console.error("AI generate error:", err);
    await ActivityLog.create({ userId, prompt, status: "error", role: userRole });
    res.status(500).json({ success: false, message: err.message || "Server error" });
  }
};

export default { aiLimiter, generateImageFromPrompt };
