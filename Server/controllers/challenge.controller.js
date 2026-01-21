import ChallengeTemplate from "../models/challengeTemplate.model.js";
import WeeklyChallengePlan from "../models/weeklyChallengePlan.model.js";
import ChallengeProgress from "../models/challengeProgress.model.js";
import User from "../models/user.model.js";
function normalizeWeekStart(dateStrOrDate) {
  const d = new Date(dateStrOrDate);
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

export const challengeController = {
  // =========================
  // Templates
  // =========================
  async createTemplate(req, res) {
    try {
      const { title, category } = req.body;

      if (!title || !category) {
        return res.status(400).json({ error: "title and category are required" });
      }

      // only supervisor/admin
      if (!["supervisor", "admin"].includes(req.user.role)) {
        return res
          .status(403)
          .json({ error: "Only supervisor/admin can create templates" });
      }

      const doc = await ChallengeTemplate.create({
        title: title.trim(),
        category: category.trim(),
        createdBy: req.user._id,
        // sticker رح ينعمل default لو ما بعتتيه
      });

      return res.status(201).json(doc);
    } catch (error) {
      if (error.code === 11000) {
        return res.status(409).json({ error: "Template already exists" });
      }
      return res.status(500).json({ error: error.message });
    }
  },

  async getTemplates(req, res) {
    try {
      const { category } = req.query;

      const filter = { isActive: true };
      if (category) filter.category = category;

      // الجاهز (createdBy null) أو تبع السوبرفايزر الحالي
      filter.$or = [{ createdBy: null }, { createdBy: req.user._id }];

      const list = await ChallengeTemplate.find(filter)
        .select("_id title category sticker createdBy") // ✅ include sticker
        .sort({ category: 1, title: 1 });

      return res.status(200).json(list);
    } catch (error) {
      return res.status(500).json({ error: error.message });
    }
  },

  // =========================
  // Weekly Plan
  // =========================
  async createWeeklyPlan(req, res) {
    try {
      if (req.user.role !== "supervisor") {
        return res
          .status(403)
          .json({ error: "Only supervisor can create weekly plans" });
      }

      const { childIds, weekStart, templateIds } = req.body;
      if (!Array.isArray(childIds) || childIds.length === 0) {
        return res.status(400).json({ error: "childIds is required (array)" });
      }
      if (!weekStart) {
        return res.status(400).json({ error: "weekStart is required" });
      }
      if (!Array.isArray(templateIds) || templateIds.length !== 7) {
        return res
          .status(400)
          .json({ error: "templateIds must be an array of 7 items" });
      }

      const count = await ChallengeTemplate.countDocuments({
        _id: { $in: templateIds },
        isActive: true,
      });
      if (count !== 7) {
        return res.status(400).json({ error: "Some templateIds are invalid" });
      }

      //const ws = normalizeWeekStart(weekStart);
const ws = weekStart; // already "YYYY-MM-DD"

      const days = templateIds.map((tid, idx) => ({
        dayIndex: idx,
        templateId: tid,
      }));

      const plan = await WeeklyChallengePlan.create({
        supervisorId: req.user._id,
        childIds,
        weekStart: ws,
        days,
        isActive: true,
      });

      const progressDocs = [];
      for (const cId of childIds) {
        for (let i = 0; i < 7; i++) {
          progressDocs.push({
            planId: plan._id,
            childId: cId,
            dayIndex: i,
            done: false,
          });
        }
      }
      await ChallengeProgress.insertMany(progressDocs, { ordered: false }).catch(
        () => {}
      );

      return res.status(201).json(plan);
    } catch (error) {
      return res.status(500).json({ error: error.message });
    }
  },

  async generateRandomWeek(req, res) {
    try {
      if (req.user.role !== "supervisor") {
        return res
          .status(403)
          .json({ error: "Only supervisor can generate random week" });
      }

      const templates = await ChallengeTemplate.find({ isActive: true })
        .select("_id title category sticker"); // ✅ include sticker

      if (templates.length < 7) {
        return res
          .status(400)
          .json({ error: "Not enough templates to generate a week" });
      }

      const shuffled = templates.sort(() => Math.random() - 0.5);
      const picked = shuffled.slice(0, 7);

      return res.status(200).json({
        templateIds: picked.map((t) => t._id),
        templates: picked, // ✅ now includes sticker too
      });
    } catch (error) {
      return res.status(500).json({ error: error.message });
    }
  },

  async getMyCurrentWeek(req, res) {
    try {
      if (req.user.role !== "child") {
        return res
          .status(403)
          .json({ error: "Only child can access this endpoint" });
      }

     const weekStart = req.query.weekStart?.toString();

     if (!weekStart) {
  return res.status(400).json({ error: "weekStart query param is required" });
}


     const plan = await WeeklyChallengePlan.findOne({
  childIds: req.user._id,
  weekStart,
  isActive: true,
}).populate("days.templateId", "title category sticker");

      if (!plan) {
        return res.status(200).json({ plan: null, progress: [] });
      }

      const progress = await ChallengeProgress.find({
        planId: plan._id,
        childId: req.user._id,
      }).select("dayIndex done doneAt");

      return res.status(200).json({ plan, progress });
    } catch (error) {
      return res.status(500).json({ error: error.message });
    }
  },

  async markDone(req, res) {
    try {
      if (req.user.role !== "child") {
        return res.status(403).json({ error: "Only child can mark done" });
      }

      const { planId, dayIndex } = req.body;
      if (!planId || dayIndex === undefined) {
        return res.status(400).json({ error: "planId and dayIndex are required" });
      }

      const prog = await ChallengeProgress.findOneAndUpdate(
        { planId, childId: req.user._id, dayIndex },
        { done: true, doneAt: new Date() },
        { new: true, upsert: true }
      );

      return res.status(200).json(prog);
    } catch (error) {
      return res.status(500).json({ error: error.message });
    }
  },
  async getParentKidWeekProgress(req, res) {
  try {
    if (req.user.role !== "parent") {
      return res.status(403).json({ error: "Only parent can access this endpoint" });
    }

    const { kidId, weekStart } = req.query;
    if (!kidId || !weekStart) {
      return res.status(400).json({ error: "kidId and weekStart are required" });
    }

    //const ws = normalizeWeekStart(weekStart);
const ws = weekStart; // same format stored in DB

    const kid = await User.findOne({ _id: kidId, parentId: req.user._id }).select("_id name email");
    if (!kid) {
      return res.status(404).json({ error: "Kid not found or not assigned to this parent" });
    }

    const plan = await WeeklyChallengePlan.findOne({
  childIds: kidId,
  weekStart: ws,
  isActive: true,
}).populate("days.templateId", "title category sticker");

    if (!plan) {
      return res.status(200).json({ kid, plan: null, progress: [] });
    }

    const progress = await ChallengeProgress.find({
      planId: plan._id,
      childId: kidId,
    }).select("dayIndex done doneAt");

    return res.status(200).json({ kid, plan, progress });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
},
async getWeeklyPlansCount(req, res) {
  try {
    const count = await WeeklyChallengePlan.countDocuments({});
    return res.status(200).json({ count });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
},


};
