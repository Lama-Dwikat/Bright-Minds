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
  
   async checkChampionBadge(req, res) {
    try {
      const { userId } = req.params;

      await badgeService.checkGameCompletionBadges(userId);

      return res.status(200).json({ message: "Champion badge check completed." });
    } catch (error) {
      console.error(error);
      return res.status(500).json({ message: error.message });
    }
  },


};

export default badgeController;
