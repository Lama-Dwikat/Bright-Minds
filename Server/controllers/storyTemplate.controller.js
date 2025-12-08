import { storyService } from "../services/storyTemplate.service.js";

export const storyTemplateController = {

  /** ✍ Supervisor manual creation */
  async createStory(req, res) {
    try {
      const story = await storyService.createManualStory(req.body);
      return res.status(201).json(story);
    } catch (err) {
      return res.status(500).json({ error: err.message });
    }
  },


  /** 🔍 External search (Storyberries + StoryWeaver + OpenLibrary + Gutendex) */
  async searchExternal(req, res) {
    try {
      const { q } = req.query;

      if (!q || q.trim().length === 0) {
        return res.status(400).json({ error: "Query ?q=keyword is required" });
      }

      const results = await storyService.searchExternalStories(q);
      return res.status(200).json(results);

    } catch (err) {
      return res.status(500).json({ error: err.message });
    }
  },


  /** 📌 Unified importer */
  async importStory(req, res) {
    try {
      const { externalId, ageGroup, source } = req.body;
      const createdBy = req.user?.id;

      // ---------- Validation ---------
      if (!externalId || !ageGroup || !source) {
        return res.status(400).json({
          error: "externalId, ageGroup and source are required"
        });
      }

      // ------------ Validate supported sources ------------
      const validSources = ["storyberries", "storyweaver-api", "openlibrary", "gutendex"];

      if (!validSources.includes(source)) {
        return res.status(400).json({
          error: `Invalid source. Allowed: ${validSources.join(", ")}`
        });
      }

      // ---------- Import ----------
      const story = await storyService.importStory({
        externalId,
        ageGroup,
        source,
        createdBy
      });

      return res.status(201).json(story);

    } catch (err) {
      return res.status(500).json({ error: err.message });
    }
  },


  /** 👶 Kids library display */
  async getStoriesForKids(req, res) {
    try {
      const { ageGroup } = req.query;

      if (!ageGroup) {
        return res.status(400).json({ error: "ageGroup is required" });
      }

      const stories = await storyService.getStoriesForKids(ageGroup);
      return res.status(200).json(stories);

    } catch (err) {
      return res.status(500).json({ error: err.message });
    }
  },


  /** 📖 Single story reader */
  async getStory(req, res) {
    try {
      const { id } = req.params;

      if (!id) {
        return res.status(400).json({ error: "Story ID required" });
      }

      const story = await storyService.getStoryById(id);
      return res.status(200).json(story);

    } catch (err) {
      return res.status(500).json({ error: err.message });
    }
  },


  /** 📌 Update reading tracker */
  async updateProgress(req, res) {
    try {
      const { storyId, lastPageRead, isCompleted } = req.body;
      const childId = req.user?.id;

      if (!storyId) {
        return res.status(400).json({ error: "storyId required" });
      }

      const updated = await storyService.updateProgress({
        storyId,
        childId,
        lastPageRead,
        isCompleted
      });

      return res.status(200).json(updated);

    } catch (err) {
      return res.status(500).json({ error: err.message });
    }
  },


  /** ⭐ Toggle recommended */
  async markRecommended(req, res) {
    try {
      const { id } = req.params;
      const { recommended } = req.body;

      if (typeof recommended !== "boolean") {
        return res.status(400).json({
          error: "recommended must be true or false"
        });
      }

      const updated = await storyService.setRecommendation(id, recommended);
      return res.status(200).json(updated);

    } catch (err) {
      return res.status(500).json({ error: err.message });
    }
  },


  /** 🏷 Update categories */
  async updateCategories(req, res) {
    try {
      const { id } = req.params;
      const { categories } = req.body;

      if (!Array.isArray(categories)) {
        return res.status(400).json({ error: "categories must be an array" });
      }

      const updated = await storyService.setStoryCategories(id, categories);
      return res.status(200).json(updated);

    } catch (err) {
      return res.status(500).json({ error: err.message });
    }
  },


  /** 📊 Kids who read story stats */
  async stats(req, res) {
    try {
      const { id } = req.params;

      if (!id) {
        return res.status(400).json({ error: "id required" });
      }

      const result = await storyService.getStoryStats(id);
      return res.status(200).json(result);

    } catch (err) {
      return res.status(500).json({ error: err.message });
    }
  }

};
