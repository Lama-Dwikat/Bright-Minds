import Story from "../models/story.model.js";
import mongoose from "mongoose";

export const authorizeStory = (roles = [], operation = "") => async (req, res, next) => {
  try {
    const { role, _id: userId } = req.user;

    // 1) السماح فوريًا بإنشاء قصة جديدة — بدون أي شروط
    if (operation === "create") {
      return next();
    }

    // 2) التحقق من الدور
    if (!roles.includes(role)) {
      return res.status(403).json({ message: "Authorization failed" });
    }

    // 3) السماح بالعرض باستخدام childId بدون فحص storyId
    if (operation === "view" && req.params.childId) {
      return next();
    }

    // 4) العمليات الأخرى تحتاج storyId
    const storyId = req.params.storyId || req.body.storyId;
    if (!storyId) {
      return res.status(400).json({ message: "storyId is required" });
    }

    const story = await Story.findById(storyId)
      .populate("childId", "parentId")
      .lean();

    if (!story) return res.status(404).json({ message: "Story not found" });

    const userIdStr = userId.toString();
    const storyChildId = story.childId?._id?.toString();
    const storySupervisorId = story.supervisorId?.toString();
    const parentIdStr = story.childId?.parentId?._id?.toString() || null;

    const isChildOwner = storyChildId === userIdStr;
    const isSupervisorAssigned = storySupervisorId === userIdStr;

    switch (operation) {
      case "update":
        if (role === "child" && !isChildOwner)
          return res.status(403).json({ message: "You can only edit your own story" });
        if (role === "supervisor" && !isSupervisorAssigned)
          return res.status(403).json({ message: "You are not assigned to this story" });
        if (role === "parent")
          return res.status(403).json({ message: "Parents cannot edit stories" });
        break;

      case "delete":
        if (!(isChildOwner || isSupervisorAssigned || role === "admin"))
          return res.status(403).json({ message: "You cannot delete this story" });
        break;

      case "submit":
        if (role !== "child")
          return res.status(403).json({ message: "Only children can submit stories" });
        if (!isChildOwner)
          return res.status(403).json({ message: "You can only submit your own story" });
        break;

      case "addMedia":
        if (role === "parent")
          return res.status(403).json({ message: "Parents cannot add media" });
        if (role === "child" && !isChildOwner)
          return res.status(403).json({ message: "You can only add media to your own story" });
        if (role === "supervisor" && !isSupervisorAssigned)
          return res.status(403).json({ message: "You are not assigned to this story" });
        break;

      case "resubmit":
        if (role !== "child")
          return res.status(403).json({ message: "Only children can resubmit stories" });
        if (!isChildOwner)
          return res.status(403).json({ message: "You can only resubmit your own story" });
        break;
    }

    req.story = story;
    next();
  } catch (error) {
    console.error("Authorization error:", error);
    res.status(500).json({ message: "Authorization failed" });
  }
};

export default authorizeStory;
