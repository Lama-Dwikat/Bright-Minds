import mongoose from "mongoose";

const childDrawingSchema = new mongoose.Schema(
  {
    childId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    activityId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "DrawingActivity",
      required: true,
    },

    drawingImage: {
      data: {
        type: Buffer,
        required: true,
      },
      contentType: {
        type: String,
        required: true,
      },
    },

    supervisorComment: {
      type: String,
    },
    rating: {
      type: Number,
      min: 1,
      max: 5,
    },
    isSubmitted: { type: Boolean, default: false },
    submittedAt: { type: Date, default: null },

  },
  
  {
    timestamps: true,
  }
);

const ChildDrawing = mongoose.model("ChildDrawing", childDrawingSchema);
export default ChildDrawing;
