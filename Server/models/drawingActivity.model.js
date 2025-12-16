import mongoose from "mongoose";

const drawingActivitySchema = mongoose.Schema(
  {
    title: { type: String, required: true },

    type: {
      type: String,
      enum: ["coloring", "tracing", "colorByNumber", "surpriseColor"],
      required: true,
    },

    ageGroup: {
      type: String,
      enum: ["5-8", "9-12"],
      required: true,
    },

    imageUrl: {
      type: String,
      required: true,
    },

    source: {
      type: String,
      default: "pixabay",
    },

    supervisorId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

const DrawingActivity = mongoose.model("DrawingActivity", drawingActivitySchema);
export default DrawingActivity;
