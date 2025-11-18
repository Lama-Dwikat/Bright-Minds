import OpenAI from "openai";
import cloudinaryService from "../services/cloudinary.service.js";
import { Buffer } from "buffer";
import Story from "../models/story.model.js"; 
import ActivityLog from "../models/activityLog.model.js"; 
import rateLimit from "express-rate-limit";

console.log("OPENAI API KEY:", process.env.OPENAI_API_KEY);

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

// ===== Rate limiter =====
export const aiLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  max: (req) => req.user.role === "supervisor" ? 20 : 5,
  message: {
    success: false,
    message: "You have reached the temporary limit for AI image generation. Try again later.",
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.user._id.toString(),
});

// ===== Generate image =====
export const generateImageFromPrompt = async (req, res) => {
  const userId = req.user._id;
  const userRole = req.user.role || "child";
  let { prompt, storyId, pageNumber = 1, style = "cartoon" } = req.body;

  if (!prompt || !storyId) {
    return res.status(400).json({ success: false, message: "prompt and storyId are required" });
  }

  try {
    // sanitize
    prompt = prompt.trim().slice(0, 300);
    const forbiddenWords = ["kill", "blood", "weapon", "violence", "sword"];
    const hasBadWord = forbiddenWords.some(word => prompt.toLowerCase().includes(word));
    if (hasBadWord) {
      await ActivityLog.create({ userId, storyId, pageNumber, prompt, status: "error", role: userRole });
      return res.status(400).json({ success: false, message: "The prompt contains forbidden words." });
    }

    // moderation
    const modResp = await openai.moderations.create({
      model: "omni-moderation-latest",
      input: prompt,
    });
    if (modResp.results?.[0]?.flagged) {
      await ActivityLog.create({ userId, storyId, pageNumber, prompt, status: "error", role: userRole });
      return res.status(400).json({ success: false, message: "The prompt is not allowed due to safety policies." });
    }

    // story
    const story = await Story.findById(storyId);
    if (!story) throw new Error("Story not found");

    // Generate image
    const fullPrompt = `${prompt}. The image should be in ${style} style suitable for children.`;
    const imageResp = await openai.images.generate({
      model: "gpt-image-1",
      prompt: fullPrompt,
      size: "1024x1024",
    });

    const b64 = imageResp.data?.[0]?.b64_json;
    if (!b64) throw new Error("No image received from AI provider");

    // Upload to Cloudinary
    const buffer = Buffer.from(b64, "base64");

    const imageUrl = await cloudinaryService.uploadBuffer(
      buffer,
      `kids-platform/stories/${storyId}/page-${pageNumber}`
    );

    // Save to story
    let page = story.pages.find(p => p.pageNumber === pageNumber);
    if (!page) {
      page = { pageNumber, elements: [], assignedToRole: "child" };
      story.pages.push(page);
    }

    if (userRole === "supervisor") {
      page.assignedToRole = "child";
    }

    const newElement = {
      type: "image",
      content: "",
      role: userRole,
      media: {
        mediaType: "image",
        url: imageUrl,
        storyId,
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
    story.aiPrompts.push({ prompt, role: userRole });
    story.lastEditedBy = userId;
    story.lastEditedRole = userRole;
    await story.save();

    await ActivityLog.create({ userId, storyId, pageNumber, prompt, status: "success", role: userRole });

    res.json({ success: true, imageUrl, element: newElement, storyId: story._id });

  } catch (err) {
    console.error("AI generate error:", err);
    await ActivityLog.create({ userId, storyId, pageNumber, prompt, status: "error", role: userRole });
    res.status(500).json({ success: false, message: err.message || "Server error" });
  }
};

export default { aiLimiter, generateImageFromPrompt };
