import mongoose from "mongoose";

const notificationSchema = new mongoose.Schema(
  {
    // مين اللي رح يستقبل الاشعار (child أو parent أو supervisor)
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    title: { type: String, default: "" },
    message: { type: String, required: true },

    // نوع الاشعار (سهل للفلترة في الفرونت)
    type: {
      type: String,
      enum: ["story", "drawing", "activity", "system"],
      default: "system",
      index: true,
    },

    // روابط اختيارية لأي شيء
    storyId: { type: mongoose.Schema.Types.ObjectId, ref: "Story", default: null },
    drawingId: { type: mongoose.Schema.Types.ObjectId, ref: "ChildDrawing", default: null },
    activityId: { type: mongoose.Schema.Types.ObjectId, ref: "DrawingActivity", default: null },

    // مين أرسل/سبب الاشعار
    fromUserId: { type: mongoose.Schema.Types.ObjectId, ref: "User", default: null },

    // قراءة/مشاهدة
    isRead: { type: Boolean, default: false, index: true },
  },
  { timestamps: true }
);

notificationSchema.index({ userId: 1, createdAt: -1 });

export const Notification = mongoose.model("Notification", notificationSchema);
