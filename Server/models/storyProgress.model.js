import mongoose from "mongoose";

const progressSchema = new mongoose.Schema({

  storyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "StoryTemplate",
    required: true,
    index: true
  },

  childId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
    index: true
  },

  lastPageRead: {
    type: Number,
    default: 1,
    min: 1
  },

  startedAt: {
    type: Date,
    default: Date.now
  },

  finishedAt: Date,

  status: {
    type: String,
    enum: ["started", "completed"],
    default: "started"
  }

}, {
  timestamps: true
});

// ⭐ Virtual: calculate percent safely
progressSchema.virtual("progressPercent").get(function () {
  // إذا لم يتم عمل populate للـ story بعد → null
  if (!this.storyId || !this.storyId.pages) return null;

  if (this.storyId.pages.length === 0) return 0;

  return Math.min(
    100,
    Math.round((this.lastPageRead / this.storyId.pages.length) * 100)
  );
});

progressSchema.set("toJSON", { virtuals: true });
progressSchema.set("toObject", { virtuals: true });

export const StoryProgress = mongoose.model("StoryProgress", progressSchema);
