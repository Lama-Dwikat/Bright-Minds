import mongoose from "mongoose";

const StoryReviewSchema = new mongoose.Schema({
  storyId: { type: mongoose.Schema.Types.ObjectId, ref: "Story", required: true },
  supervisorId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  rating: { type: Number, min:1, max:5 },
  comment: { type: String, trim: true ,maxlength: 1000 },
  status: { type: String, enum: ["pending", "completed"], default: "pending" }
  //createdAt: { type: Date, default: Date.now }
  
}, { timestamps: true });

const StoryReview = mongoose.model("StoryReview", StoryReviewSchema);
export default StoryReview;