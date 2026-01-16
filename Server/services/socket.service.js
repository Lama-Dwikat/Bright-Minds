import { Server } from "socket.io";

export const initChatSocket = (server) => {
  const io = new Server(server, {
    cors: { origin: "*" },
  });

  io.on("connection", (socket) => {
    console.log("⚡ User connected:", socket.id);

    socket.on("join", (userId) => {
      socket.join(userId);
      console.log(`User ${userId} joined room ${userId}`);
    });

    // ✅ Socket ONLY delivers messages (NO DB SAVE HERE)
    socket.on("sendMessage", ({ chat }) => {
      console.log("📨 Delivering chat:", chat._id);

      io.to(chat.receiver._id.toString()).emit("receiveMessage", chat);
      io.to(chat.sender._id.toString()).emit("receiveMessage", chat);
    });

    socket.on("disconnect", () => {
      console.log("⚡ User disconnected:", socket.id);
    });
  });
};
