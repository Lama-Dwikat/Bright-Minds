import mongoose from "mongoose";

const challengeTemplateSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true },
    category: {
      type: String,
      required: true,
      trim: true,
    },
sticker: { type: String, default: "🎯" },
    isActive: { type: Boolean, default: true },

    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
  },
  { timestamps: true }
);

challengeTemplateSchema.index({ title: 1, category: 1 }, { unique: true });

const ChallengeTemplate = mongoose.model("ChallengeTemplate", challengeTemplateSchema);
export default ChallengeTemplate;
