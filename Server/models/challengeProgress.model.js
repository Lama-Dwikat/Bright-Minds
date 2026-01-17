import mongoose from "mongoose";

const challengeProgressSchema = new mongoose.Schema(
  {
    planId: { type: mongoose.Schema.Types.ObjectId, ref: "WeeklyChallengePlan", required: true },
    childId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    dayIndex: { type: Number, min: 0, max: 6, required: true },

    done: { type: Boolean, default: false },
    doneAt: { type: Date },
  },
  { timestamps: true }
);

challengeProgressSchema.index({ planId: 1, childId: 1, dayIndex: 1 }, { unique: true });

const ChallengeProgress = mongoose.model("ChallengeProgress", challengeProgressSchema);
export default ChallengeProgress;
