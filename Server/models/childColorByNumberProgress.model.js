import mongoose from "mongoose";

const fillSchema = new mongoose.Schema(
  {
    regionId: { type: Number, required: true, min: 1 },
    colorHex: { type: String, required: true },
    updatedAt: { type: Date, default: Date.now },
  },
  { _id: false }
);

const childColorByNumberProgressSchema = new mongoose.Schema(
  {
    childId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    activityId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "DrawingActivity",
      required: true,
      index: true,
    },

    regionsCountSnapshot: { type: Number, required: true, min: 1 },

    fills: { type: [fillSchema], default: [] },

    percent: { type: Number, default: 0, min: 0, max: 100 },

    isCompleted: { type: Boolean, default: false },
    completedAt: { type: Date, default: null },
  },
  { timestamps: true }
);

childColorByNumberProgressSchema.index({ childId: 1, activityId: 1 }, { unique: true });

const ChildColorByNumberProgress = mongoose.model(
  "ChildColorByNumberProgress",
  childColorByNumberProgressSchema
);

export default ChildColorByNumberProgress;
