import mongoose from "mongoose";

const legendItemSchema = new mongoose.Schema(
  {
    number: { type: Number, required: true, min: 1 },
    colorHex: { type: String, required: true },
    label: { type: String, default: "" },
  },
  { _id: false }
);

const maskPaletteItemSchema = new mongoose.Schema(
  {
    number: { type: Number, required: true, min: 1 },
    maskColorHex: { type: String, required: true },
  },
  { _id: false }
);

const drawingActivitySchema = mongoose.Schema(
  {
    title: { type: String, required: true },

    type: {
      type: String,
      enum: ["coloring", "tracing", "colorByNumber", "surpriseColor"],
      required: true,
      index: true,
    },

    ageGroup: {
      type: String,
      enum: ["5-8", "9-12"],
      required: true,
      index: true,
    },

    imageUrl: {
      type: String,
      required: true,
    },

    maskUrl: {
      type: String,
      default: null,
    },

    regionsCount: {
      type: Number,
      default: null,
      min: 1,
    },

    maskPalette: {
      type: [maskPaletteItemSchema],
      default: [],
    },

    legend: {
      type: [legendItemSchema],
      default: [],
    },

    source: {
      type: String,
      default: "pixabay",
      index: true,
    },

    supervisorId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
  },
  { timestamps: true }
);

drawingActivitySchema.index({ supervisorId: 1, createdAt: -1 });
drawingActivitySchema.index({ ageGroup: 1, isActive: 1, createdAt: -1 });
drawingActivitySchema.index({ type: 1, ageGroup: 1, isActive: 1 });

const DrawingActivity = mongoose.model("DrawingActivity", drawingActivitySchema);
export default DrawingActivity;
