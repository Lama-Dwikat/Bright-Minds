import mongoose from "mongoose";

const StoryWritingSessionSchema = new mongoose.Schema(
  {
    childId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    storyId: { type: mongoose.Schema.Types.ObjectId, ref: "Story", required: true, index: true },

    startAt: { type: Date, default: Date.now, index: true },
    lastActiveAt: { type: Date, default: Date.now },
    endAt: { type: Date, default: null },

    durationSec: { type: Number, default: 0 },

    endedReason: {
      type: String,
      enum: ["save_draft", "submit", "exit", "auto_timeout"],
      default: "exit",
    },
  },
  { timestamps: true }
);

StoryWritingSessionSchema.index({ childId: 1, storyId: 1, endAt: 1, lastActiveAt: -1 });

const StoryWritingSession =
  mongoose.models.StoryWritingSession ||
  mongoose.model("StoryWritingSession", StoryWritingSessionSchema);

export default StoryWritingSession;
