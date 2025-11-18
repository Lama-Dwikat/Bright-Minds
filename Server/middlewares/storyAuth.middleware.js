import Story from "../models/story.model.js";

export const authorizeStory = (roles = [], operation = "") => async (req, res, next) => {
  try {
    const { role, _id: userId } = req.user;
    const userIdStr = userId.toString();

    // 1) CREATE لا يحتاج storyId
    if (operation === "create") {
      return next();
    }

    // 2) تأكد أن الدور مسموح
    if (!roles.includes(role)) {
      return res.status(403).json({ message: "Authorization failed" });
    }

    // 3) VIEW by childId بدون storyId
    if (operation === "view" && req.params.childId) {
      return next();
    }

    // 4) باقي العمليات تحتاج storyId
    const storyId = req.params.storyId || req.body.storyId;

    if (!storyId) {
      return res.status(400).json({ message: "storyId is required" });
    }

    const story = await Story.findById(storyId)
      .populate("childId", "_id parentId name")
      .lean();

    if (!story)
      return res.status(404).json({ message: "Story not found" });

    // 🔥 هذا مهم — هيك نضمن إنه الـ childId دايمًا مضبوط
    const storyChildId = story.childId?._id?.toString();

    const isChildOwner = storyChildId === userIdStr;

    // --------------------------------------
    // ----------- AUTH RULES ---------------
    // --------------------------------------

    switch (operation) {

      case "update":
        if (role === "child" && !isChildOwner)
          return res.status(403).json({ message: "You can only edit your own story" });
        break;

      case "submit":
        if (role !== "child")
          return res.status(403).json({ message: "Only children can submit stories" });

        if (!isChildOwner)
          return res.status(403).json({ message: "You can only submit your own story" });

        break;

      case "delete":
        if (!(isChildOwner || role === "admin"))
          return res.status(403).json({ message: "You cannot delete this story" });
        break;

      case "addMedia":
        if (role === "child" && !isChildOwner)
          return res.status(403).json({ message: "You can only add media to your own story" });
        break;

      case "resubmit":
        if (role !== "child" || !isChildOwner)
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
