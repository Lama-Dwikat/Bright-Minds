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
  },
  {
    timestamps: true,
  }
);

const ChildDrawing = mongoose.model("ChildDrawing", childDrawingSchema);
export default ChildDrawing;
