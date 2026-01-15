import mongoose from "mongoose";

const BadgeSchema = new mongoose.Schema({
  childId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  type: {
    type: String,
    required: true,
  },
  earnedAt: {
    type: Date,
    default: Date.now,
  }
});

export const Badge = mongoose.model("Badge", BadgeSchema);

export default Badge;
