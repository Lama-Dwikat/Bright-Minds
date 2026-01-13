import { Notification } from "../models/notification.model.js";

export const notificationController = {
  // (اختياري) إرسال إشعار يدوي
  async sendNotification(req, res) {
    try {
      const { userId, title, message, type, storyId, drawingId, activityId } = req.body;

      if (!userId || !message) {
        return res.status(400).json({ error: "userId and message are required" });
      }

      const notification = await Notification.create({
        userId,
        title: title || "",
        message,
        type: type || "system",
        storyId: storyId || null,
        drawingId: drawingId || null,
        activityId: activityId || null,
        fromUserId: req.user?._id || null,
        isRead: false,
      });

      return res.status(200).json({ success: true, notification });
    } catch (err) {
      return res.status(500).json({ error: err.message });
    }
  },

  // ✅ جلب إشعاراتي أنا
  async getMyNotifications(req, res) {
    try {
      const userId = req.user._id;

      const notifications = await Notification.find({
  $or: [
    { userId },        // الجديد
    { childId: userId } // القديم (story notifications)
  ],
}).sort({ createdAt: -1 });

      return res.status(200).json(notifications);
    } catch (err) {
      return res.status(500).json({ error: err.message });
    }
  },

  // ✅ تعليم الكل كمقروء
  async markAllAsRead(req, res) {
    try {
      const userId = req.user._id;

await Notification.updateMany(
  { $or: [{ userId }, { childId: userId }] },
  { $set: { isRead: true, seen: true } } // لو عندك seen قديم
);

      return res.status(200).json({ message: "Notifications marked as read" });
    } catch (err) {
      return res.status(500).json({ error: err.message });
    }
  },
};
