import { StoryTemplate } from "../models/storyTemplate.model.js";
import { StoryProgress } from "../models/storyProgress.model.js";
import axios from "axios";

export const storyService = {

  /** 🔍 Search stories for children with 3 APIs */
  async searchExternalStories(query) {
    query = query?.trim() || "kids";

    // ⭐ 1 — Storyberries (best match for kids fairy tales)
    try {
      const res = await axios.get(
        "https://www.storyberries.com/wp-json/wp/v2/stories?search=" + query
      );

      const books = res.data.map(b => ({
        externalId: b.id,
        source: "storyberries",
        title: b.title.rendered,
        author: "Unknown",
        summary: b.excerpt.rendered.replace(/<[^>]*>/g, ""),
        image: b.jetpack_featured_media_url ?? null,
        textUrl: b.link
      }));

      if (books.length) return books;
    } catch (e) {
      console.warn("❌ Storyberries failed — moving on…");
    }

    // ⭐ 2 — StoryWeaver Kids API
    try {
      const res = await axios.get(
        `https://storyweaver.org.in/api/v1/stories?search=${query}&language=English`
      );

      const books = res.data.stories.slice(0, 10).map(story => ({
        externalId: story.id,
        source: "storyweaver-api",
        title: story.title,
        author: story.authors?.join(", ") ?? "Unknown",
        summary: story.synopsis ?? "Children’s story",
        image: story.cover_image_url,
        textUrl: null
      }));

      if (books.length) return books;
    } catch (e) {
      console.warn("❌ StoryWeaver failed — fallback OpenLibrary…");
    }

    // ⭐ 3 — OpenLibrary fallback
    try {
      const res = await axios.get(
        `https://openlibrary.org/search.json?q=${query}&subject=children`
      );

      return res.data.docs.slice(0, 10).map(b => ({
        externalId: b.key,
        source: "openlibrary",
        title: b.title,
        author: b.author_name?.[0] ?? "Unknown",
        summary: "Children book",
        image: b.cover_i
          ? `https://covers.openlibrary.org/b/id/${b.cover_i}-M.jpg`
          : null,
        textUrl: null
      }));
    } catch (e) {
      console.warn("❌ OpenLibrary failed — fallback Gutendex…");
    }

    // ⭐ Last fallback — Gutendex
    const fallback = await axios.get(
      `https://gutendex.com/books/?search=${query}`
    );

    return fallback.data.results.map(book => ({
      externalId: book.id,
      source: "gutendex",
      title: book.title,
      author: book.authors?.[0]?.name ?? "Unknown author",
      summary: book.title,
      image: book.formats["image/jpeg"] ?? null,
      textUrl: book.formats["text/plain"] ?? null
    }));
  },

  /** Supervisor manual creation */
  async createManualStory(data) {
    return await StoryTemplate.create(data);
  },

  /** Unified importer — auto detect source */
  async importStory({ externalId, source, ageGroup, createdBy }) {
    switch (source) {
      case "storyberries":
        return this.importStoryberries({ externalId, ageGroup, createdBy });

      case "storyweaver-api":
        return this.importStoryWeaver({ externalId, ageGroup, createdBy });

      case "openlibrary":
        return this.importOpenLibrary({ externalId, ageGroup, createdBy });

      case "gutendex":
        return this.importGutendexStory({ externalId, ageGroup, createdBy });

      default:
        throw new Error("Invalid source");
    }
  },

  /** ⭐ Import from Storyberries */
  async importStoryberries({ externalId, ageGroup, createdBy }) {
    const res = await axios.get(
      "https://www.storyberries.com/wp-json/wp/v2/stories?include=" + externalId
    );

    const story = res.data[0];
    const clean = story.excerpt.rendered.replace(/<[^>]*>/g, "");

    const chunks = clean.match(/.{1,300}/g) ?? [];

    const pages = chunks.map((chunk, i) => ({
      pageNumber: i + 1,
      text: chunk
    }));

    return StoryTemplate.create({
      title: story.title.rendered,
      description: "Kids story",
      summary: clean,
      coverImage: story.jetpack_featured_media_url,
      ageGroup,
      source: "storyberries",
      pages,
      createdBy
    });
  },

  /** ⭐ Import from StoryWeaver Kids API */
  async importStoryWeaver({ externalId, ageGroup, createdBy }) {
    const res = await axios.get(
      "https://storyweaver.org.in/api/v1/stories/" + externalId
    );

    const story = res.data.story;

    const cleanText = (story.synopsis ?? "A children’s tale")
      .replace(/<[^>]*>/g, "")
      .trim();

    const chunks = cleanText.match(/.{1,300}/g) ?? [];

    const pages = chunks.length
      ? chunks.map((c, i) => ({ pageNumber: i + 1, text: c }))
      : [{ pageNumber: 1, text: cleanText }];

    return StoryTemplate.create({
      title: story.title,
      description: cleanText,
      summary: cleanText,
      coverImage: story.cover_image_url,
      ageGroup,
      source: "storyweaver-api",
      pages,
      createdBy
    });
  },

  /** Import OpenLibrary (minimum content fallback) */
  async importOpenLibrary({ externalId, ageGroup, createdBy }) {
    return StoryTemplate.create({
      title: externalId,
      description: "Kids imported story",
      ageGroup,
      source: "openlibrary",
      pages: [{ pageNumber: 1, text: "Story imported. Content unavailable." }],
      createdBy
    });
  },

  /** Gutendex importer */
  async importGutendexStory({ externalId, ageGroup, createdBy }) {
    const bookRes = await axios.get(
      `https://gutendex.com/books/${externalId}`
    );

    const book = bookRes.data;

    let pages = [];
    const textUrl = book.formats["text/plain"];

    if (textUrl) {
      const textRes = await axios.get(textUrl, { responseType: "text" });
      const fullText = textRes.data;

      for (let i = 0; i < fullText.length; i += 300) {
        pages.push({
          pageNumber: pages.length + 1,
          text: fullText.slice(i, i + 300)
        });
      }
    }

    return StoryTemplate.create({
      title: book.title,
      summary: book.title,
      description: "Imported story",
      ageGroup,
      source: "gutendex",
      pages,
      createdBy
    });
  },

  /** Kids story listing */
  async getStoriesForKids(ageGroup) {
    return StoryTemplate.find({ ageGroup }).sort({
      recommended: -1,
      createdAt: -1
    });
  },

  async setStoryCategories(storyId, categories) {
    return StoryTemplate.findByIdAndUpdate(storyId, { categories }, { new: true });
  },

  async getStoryStats(storyId) {
    return StoryProgress.find({ storyId }).populate("childId", "name");
  },

  async getStoryById(id) {
    const story = await StoryTemplate.findById(id);
    if (!story) throw new Error("Story not found");
    return story;
  },

  async updateProgress({ storyId, childId, lastPageRead, isCompleted }) {
    let progress = await StoryProgress.findOne({ storyId, childId });

    if (!progress) {
      return StoryProgress.create({
        storyId,
        childId,
        lastPageRead: lastPageRead ?? 1,
        status: isCompleted ? "completed" : "started",
        finishedAt: isCompleted ? new Date() : null
      });
    }

    progress.lastPageRead = lastPageRead ?? progress.lastPageRead;

    if (isCompleted && progress.status !== "completed") {
      progress.status = "completed";
      progress.finishedAt = new Date();
    }

    await progress.save();
    return progress;
  }
};
