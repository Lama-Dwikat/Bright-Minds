import Story from "../models/story.model.js";
import jwt from "jsonwebtoken";

export const authorizeStory = (roles = [], operation = "") => async (req, res, next) => {
  try {
    const { role, _id: userId } = req.user;

    if (operation === "create") {
      if (!roles.includes(role)) {
        return res.status(403).json({ message: "You are not allowed to create stories" });
      }
      return next();
    }

    const storyId = req.params.storyId || req.body.storyId;
    if (!storyId) return res.status(400).json({ message: "storyId is required" });

    const story = await Story.findById(storyId);
    if (!story) return res.status(404).json({ message: "Story not found" });

    const isChildOwner = story.childId.toString() === userId.toString();
    const isSupervisorAssigned = story.supervisorId?.toString() === userId.toString();

    switch (operation) {
      case "update":
        if (role === "child" && !isChildOwner) return res.status(403).json({ message: "You can only edit your own story" });
        if (role === "supervisor" && !isSupervisorAssigned) return res.status(403).json({ message: "You are not assigned to this story" });
        if (role === "parent") return res.status(403).json({ message: "Parents cannot edit stories" });
        break;

      case "delete":
        if (!(isChildOwner || isSupervisorAssigned || role === "admin")) {
          return res.status(403).json({ message: "You cannot delete this story" });
        }
        break;

      case "submit":
        if (role !== "child") return res.status(403).json({ message: "Only children can submit stories" });
        if (!isChildOwner) return res.status(403).json({ message: "You can only submit your own story" });
        break;

      case "view":
        const isParentOfChild = story.childId?.parentId?.toString() === userId.toString();
        if (!(isChildOwner || isSupervisorAssigned || role === "admin" || isParentOfChild)) {
          return res.status(403).json({ message: "You are not allowed to view this story" });
        }
        break;

      case "addMedia":
        if (role === "parent") return res.status(403).json({ message: "Parents cannot add media" });
        if (role === "child" && !isChildOwner) return res.status(403).json({ message: "You can only add media to your own story" });
        if (role === "supervisor" && !isSupervisorAssigned) return res.status(403).json({ message: "You are not assigned to this story" });
        break;


        case "resubmit":
           if (role !== "child") return res.status(403).json({ message: "Only children can resubmit stories" });
           if (!isChildOwner) return res.status(403).json({ message: "You can only resubmit your own story" });
           break;

      default:
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
