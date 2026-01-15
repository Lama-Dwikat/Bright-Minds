import mongoose from "mongoose";

const storyViewSchema = new mongoose.Schema({
  storyId: { type: mongoose.Schema.Types.ObjectId, ref: "Story", required: true },
  childId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  viewedAt: { type: Date, default: Date.now }
});

export default mongoose.model("StoryView", storyViewSchema);
