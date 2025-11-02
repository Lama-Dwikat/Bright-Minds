import mongoose from "mongoose";

const LikeSchema = new mongoose.Schema({
  storyId: { type: mongoose.Schema.Types.ObjectId, ref: "Story", required: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
}, { timestamps: true });
// Ensure a user can like a story only once
LikeSchema.index({ storyId: 1, userId: 1 }, { unique: true });
// Index to optimize like count retrieval
LikeSchema.index({ storyId: 1 });


const StoryLike = mongoose.model("StoryLike", LikeSchema);
export default StoryLike;