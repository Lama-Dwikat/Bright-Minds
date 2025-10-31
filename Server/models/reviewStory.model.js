const mongoose = require("mongoose");

const ReviewSchema = new mongoose.Schema({
  storyId: { type: mongoose.Schema.Types.ObjectId, ref: "Story", required: true },
  supervisorId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  rating: { type: Number, min:1, max:5 },
  comment: String,
  status: { type: String, enum: ["pending", "completed"], default: "completed" }
  //createdAt: { type: Date, default: Date.now }
  
}, { timestamps: true });

const storyReview = mongoose.model("storyReview", ReviewSchema);
export default storyReview;