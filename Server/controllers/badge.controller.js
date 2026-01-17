import Badge from "../models/badge.model.js";

export const badgeController = {
  async getChildBadges(req, res) {
    try {
      const childId = req.user._id;
      const badges = await Badge.find({ childId });
      res.json({ success: true, badges });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },
  


};

export default badgeController;
