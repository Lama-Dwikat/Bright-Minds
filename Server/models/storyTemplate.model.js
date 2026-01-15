import mongoose from "mongoose";

const pageSchema = new mongoose.Schema({
  pageNumber: {
    type: Number,
    required: true,
    min: 1
  },
  text: {
    type: String,
    required: true,
    trim: true
  },
  image: String
});

const storyTemplateSchema = new mongoose.Schema({

  title: {
    type: String,
    required: true,
    trim: true
  },

  summary: {
    type: String,
    trim: true,
    maxLength: 500
  },

  description: {
    type: String,
    trim: true
  },

  coverImage: {
    type: String,
    default: null
  },

  pages: {
    type: [pageSchema],
    validate: {
      validator: pages => pages.length > 0,
      message: "Story must contain at least one page"
    }
  },

  // ⭐ تحديث مهم — إضافة storyweaver-api كمصدر
  source: {
    type: String,
    enum: ["manual", "fairytales-api", "gutendex", "storyweaver-api"],
    default: "manual"
  },

  externalId: {
    type: String,
    index: true,
    sparse: true
  },

  ageGroup: {
    type: String,
    enum: ["3-5", "6-8", "9-12"],
    required: true
  },

  categories: {
    type: [String],
    default: []
  },

  recommended: {
    type: Boolean,
    default: false,
    index: true
  },

  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User"
  },

  createdAt: {
    type: Date,
    default: Date.now
  }
});

// 📌 Virtual count helper
storyTemplateSchema.virtual("pagesCount").get(function () {
  return this.pages?.length ?? 0;
});

// 📌 Clean messy text in imports (Gutendex)
storyTemplateSchema.pre("save", function (next) {
  this.pages = this.pages.map(p => ({
    ...p,
    text: p.text
      .replace(/(\*{2}|===|CHAPTER|GUTENBERG)/gi, "")
      .trim()
  }));
  next();
});

export const StoryTemplate = mongoose.model("StoryTemplate", storyTemplateSchema);
