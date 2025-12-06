import { Notification } from "../models/notification.model.js";

export const notificationController = {

  async sendNotification(req, res) {
    try {
      const { childId, storyId, message } = req.body;

      const notification = await Notification.create({
        childId,
        storyId,
        message,
      });

      res.status(200).json({ success: true, notification });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  },

  async getMyNotifications(req, res) {
    try {
      const userId = req.user.id; // الطفل

      const notifications = await Notification.find({ childId: userId })
        .sort({ createdAt: -1 });

      res.status(200).json(notifications);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  },

  async markAsSeen(req, res) {
    try {
      const userId = req.user.id;

      await Notification.updateMany(
        { childId: userId },
        { $set: { seen: true } }
      );

      res.status(200).json({ message: "Notifications marked as seen" });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }

};
