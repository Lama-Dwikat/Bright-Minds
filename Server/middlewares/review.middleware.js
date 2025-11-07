import Story from "../models/story.model.js";

export const reviewPermissions = async (req, res, next) => {
  try {
    const user = req.user;
    const { storyId } = req.body || req.params;

    if (user.role !== "supervisor") {
      return res.status(403).json({
        success: false,
        message: "Access denied. Only supervisors can review stories."
      });
    }

    const story = await Story.findById(storyId);
    if (!story) {
      return res.status(404).json({ success: false, message: "Story not found" });
    }

    if (!story.supervisorId || story.supervisorId.toString() !== user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: "You are not assigned to review this story."
      });
    }

    next();
  } catch (error) {
    console.error("Review middleware error:", error);
    res.status(500).json({
      success: false,
      message: "Server error in review permission check"
    });
  }
};
export default reviewPermissions;