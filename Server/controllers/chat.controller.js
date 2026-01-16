import { chatService } from "../services/chat.service.js";

export const chatController = {
  async sendMessage(req, res) {
    try {
      const senderId = req.user._id;
      const { receiverId, message } = req.body;

      const chat = await chatService.sendMessage(senderId, receiverId, message);

      return res.status(200).json({ success: true, chat });
    } catch (err) {
      return res.status(500).json({ success: false, message: err.message });
    }
  },

  async getConversation(req, res) {
    try {
      const userId = req.user._id;
      const { otherUserId } = req.params;

      const chats = await chatService.getConversation(userId, otherUserId);
      return res.status(200).json({ success: true, chats });
    } catch (err) {
      return res.status(500).json({ success: false, message: err.message });
    }
  },

  async markAsRead(req, res) {
    try {
      const userId = req.user._id;
      const { senderId } = req.body;

      await chatService.markAsRead(senderId, userId);
      return res.status(200).json({ success: true });
    } catch (err) {
      return res.status(500).json({ success: false, message: err.message });
    }
  },

  async getUnreadCount(req, res) {
    try {
      const userId = req.user._id;
      const count = await chatService.getUnreadCount(userId);
      return res.status(200).json({ success: true, count });
    } catch (err) {
      return res.status(500).json({ success: false, message: err.message });
    }
  },
};
