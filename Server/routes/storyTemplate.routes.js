import express from "express";
import { storyTemplateController } from "../controllers/storyTemplate.controller.js";
import authMiddleware from "../middlewares/auth.middleware.js";
import roleMiddleware from "../middlewares/role.middleware.js";

const router = express.Router();

/**
 * 🔐 Protect ALL routes under /api/stories
 */
router.use(authMiddleware.authentication);

/**
 * 🔎 Supervisor → Search external children stories API
 * GET /api/stories/external/search?q=Cats
 */
router.get(
  "/external/search",
  roleMiddleware(["supervisor"]),
  storyTemplateController.searchExternal
);

/**
 * 📚 Kids library (child + supervisor + admin)
 * GET /api/stories/kids?ageGroup=6-8
 */
router.get(
  "/kids",
  roleMiddleware(["child", "supervisor", "admin"]),
  storyTemplateController.getStoriesForKids
);

/**
 * ✍ Supervisor → Manual story creation
 * POST /api/stories/
 */
router.post(
  "/",
  roleMiddleware(["supervisor"]),
  storyTemplateController.createStory
);

/**
 * ✨ Supervisor → Import external story
 * POST body → { externalId, ageGroup, source }
 */
router.post(
  "/import",
  roleMiddleware(["supervisor"]),
  storyTemplateController.importStory
);

/**
 * 📌 Child → update reading progress
 * POST /api/stories/progress
 */
router.post(
  "/progress",
  roleMiddleware(["child"]),
  storyTemplateController.updateProgress
);

/**
 * ⭐ Supervisor → Toggle recommended flag
 * PATCH /api/stories/:id/recommended
 */
router.patch(
  "/:id/recommended",
  roleMiddleware(["supervisor"]),
  storyTemplateController.markRecommended
);

/**
 * 🏷 Supervisor → Update categories/tags
 * PATCH /api/stories/:id/categories
 */
router.patch(
  "/:id/categories",
  roleMiddleware(["supervisor"]),
  storyTemplateController.updateCategories
);

/**
 * 📊 Supervisor → reading statistics
 * GET /api/stories/:id/stats
 */
router.get(
  "/:id/stats",
  roleMiddleware(["supervisor"]),
  storyTemplateController.stats
);

/**
 * 📖 Read full story (child + supervisor + admin)
 * MUST ALWAYS BE LAST to avoid conflict
 */
router.get(
  "/:id",
  roleMiddleware(["child", "supervisor", "admin"]),
  storyTemplateController.getStory
);

export default router;
