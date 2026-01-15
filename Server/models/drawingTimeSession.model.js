import mongoose from "mongoose";

const drawingTimeSessionSchema = new mongoose.Schema(
  {
    childId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    scope: {
      type: String,
      enum: ["section", "activity"], // section=صفحة الرسم العامة, activity=كانفاس activity محددة
      required: true,
      index: true,
    },

    activityId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "DrawingActivity",
      default: null,
      index: true,
    },

    // ✅ NEW: link timing to a specific saved drawing
    drawingId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "ChildDrawing",
      default: null,
      index: true,
    },

    startedAt: { type: Date, required: true, default: Date.now },
    endedAt: { type: Date, default: null },

    durationSec: { type: Number, default: 0 }, // محسوبة بالثواني عند stop

    isActive: { type: Boolean, default: true, index: true },
  },
  { timestamps: true }
);

// مفيد للتقرير
drawingTimeSessionSchema.index({ childId: 1, startedAt: -1 });
drawingTimeSessionSchema.index({ childId: 1, scope: 1, isActive: 1 });
drawingTimeSessionSchema.index({ childId: 1, scope: 1, activityId: 1, isActive: 1 });
drawingTimeSessionSchema.index({ childId: 1, drawingId: 1 });

const DrawingTimeSession = mongoose.model(
  "DrawingTimeSession",
  drawingTimeSessionSchema
);

export default DrawingTimeSession;
