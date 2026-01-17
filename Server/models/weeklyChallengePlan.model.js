import mongoose from "mongoose";

const daySchema = new mongoose.Schema(
  {
    dayIndex: { type: Number, min: 0, max: 6, required: true }, // 0..6
    templateId: { type: mongoose.Schema.Types.ObjectId, ref: "ChallengeTemplate", required: true },
  },
  { _id: false }
);

const weeklyChallengePlanSchema = new mongoose.Schema(
  {
    supervisorId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },

    childIds: [{ type: mongoose.Schema.Types.ObjectId, ref: "User", required: true }],

 //   weekStart: { type: Date, required: true },
weekStart: { type: String, required: true }, // "YYYY-MM-DD"

    days: {
      type: [daySchema],
      validate: {
        validator: function (arr) {
          return Array.isArray(arr) && arr.length === 7 && new Set(arr.map(d => d.dayIndex)).size === 7;
        },
        message: "days must contain exactly 7 unique dayIndex entries (0..6)",
      },
    },

    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

weeklyChallengePlanSchema.index({ weekStart: 1, childIds: 1 });

const WeeklyChallengePlan = mongoose.model("WeeklyChallengePlan", weeklyChallengePlanSchema);
export default WeeklyChallengePlan;
