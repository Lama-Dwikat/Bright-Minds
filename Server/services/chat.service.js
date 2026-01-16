import Chat from "../models/chat.model.js";

export const chatService = {
  async sendMessage(senderId, receiverId, message) {
    const chat = await Chat.create({
      sender: senderId,
      receiver: receiverId,
      message,
    });
    return chat;
  },

  async getConversation(user1, user2) {
    const chats = await Chat.find({
      $or: [
        { sender: user1, receiver: user2 },
        { sender: user2, receiver: user1 },
      ],
    })
      .sort({ createdAt: 1 }) // oldest first
      .populate("sender", "name")
      .populate("receiver", "name");

    return chats;
  },

  async markAsRead(senderId, receiverId) {
    await Chat.updateMany(
      { sender: senderId, receiver: receiverId, read: false },
      { $set: { read: true } }
    );
  },

  async getUnreadCount(userId) {
    return await Chat.countDocuments({ receiver: userId, read: false });
  },
};
