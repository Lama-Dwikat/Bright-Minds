import mongoose from "mongoose";
import StoryWritingSession from "../models/storyWritingSession.model.js";
import User from "../models/user.model.js";
import Story from "../models/story.model.js";
import StoryReview from "../models/reviewStory.model.js";

function clampSeconds(x) {
  return Math.max(0, Math.floor(x));
}

export const storyWritingTimeService = {
  async startOrResumeSession({ childId, storyId }) {
    const childObj = new mongoose.Types.ObjectId(childId);
    const storyObj = new mongoose.Types.ObjectId(storyId);

    const tenMinAgo = new Date(Date.now() - 10 * 60 * 1000);

    const open = await StoryWritingSession.findOne({
      childId: childObj,
      storyId: storyObj,
      endAt: null,
      lastActiveAt: { $gte: tenMinAgo },
    }).sort({ lastActiveAt: -1 });

    if (open) {
      open.lastActiveAt = new Date();
      await open.save();
      return open;
    }

    const created = await StoryWritingSession.create({
      childId: childObj,
      storyId: storyObj,
      startAt: new Date(),
      lastActiveAt: new Date(),
      endAt: null,
      durationSec: 0,
    });

    return created;
  },

  async pingSession({ sessionId, childId }) {
    const sess = await StoryWritingSession.findById(sessionId);
    if (!sess) throw new Error("Session not found");
    if (sess.childId.toString() !== childId.toString()) throw new Error("Unauthorized");

    // ✅ لو session مسكّرة ما نعمل ping
    if (sess.endAt) return sess;

    sess.lastActiveAt = new Date();
    await sess.save();
    return sess;
  },

  async endSession({ sessionId, childId, reason }) {
    const sess = await StoryWritingSession.findById(sessionId);
    if (!sess) throw new Error("Session not found");
    if (sess.childId.toString() !== childId.toString()) throw new Error("Unauthorized");

    // لو انتهت قبل هيك، رجّعها زي ما هي
    if (sess.endAt) return sess;

    const now = new Date();
    const duration = clampSeconds((now.getTime() - sess.startAt.getTime()) / 1000);

    sess.endAt = now;
    sess.durationSec = duration;
    sess.endedReason = reason || "exit";
    sess.lastActiveAt = now;

    await sess.save();
    return sess;
  },

  // ✅ Report للأهل: Histogram + Stories + Latest Review
  async getParentReport({ parentId, rangeDays = 7 }) {
    const from = new Date();
    from.setDate(from.getDate() - Number(rangeDays));
    from.setHours(0, 0, 0, 0);

    // 1) هات أطفال هذا الـ parent
    const children = await User.find({ role: "child", parentId }).select("_id name").lean();
    const childIds = children.map(c => c._id);

    if (childIds.length === 0) {
      return { rangeDays: Number(rangeDays), histogram: [], stories: [], children: [] };
    }

    // 2) Histogram يومي: مجموع مدة الكتابة لكل يوم (بالدقائق)
    const histogram = await StoryWritingSession.aggregate([
      {
        $match: {
          childId: { $in: childIds },
          startAt: { $gte: from },
        }
      },
      {
        $project: {
          day: { $dateToString: { format: "%Y-%m-%d", date: "$startAt" } },
          durationSec: 1
        }
      },
      {
        $group: {
          _id: "$day",
          totalSec: { $sum: "$durationSec" }
        }
      },
      { $sort: { _id: 1 } },
      {
        $project: {
          _id: 0,
          date: "$_id",
          minutes: { $round: [{ $divide: ["$totalSec", 60] }, 0] }
        }
      }
    ]);

    // 3) Stories summary: مجموع مدة الكتابة لكل قصة + latest review
    const stories = await StoryWritingSession.aggregate([
      {
        $match: {
          childId: { $in: childIds },
          startAt: { $gte: from },
        }
      },
      {
        $group: {
          _id: "$storyId",
          totalSec: { $sum: "$durationSec" },
          lastAt: { $max: "$lastActiveAt" },
        }
      },
      { $sort: { lastAt: -1 } },

      // lookup story
      {
        $lookup: {
          from: "stories",
          localField: "_id",
          foreignField: "_id",
          as: "story"
        }
      },
      { $unwind: "$story" },

      // lookup latest review (StoryReview)
      {
        $lookup: {
          from: "storyreviews",
          let: { sid: "$_id" },
          pipeline: [
            { $match: { $expr: { $eq: ["$storyId", "$$sid"] } } },
            { $sort: { createdAt: -1 } },
            { $limit: 1 },

            // join supervisor name
            {
              $lookup: {
                from: "users",
                localField: "supervisorId",
                foreignField: "_id",
                as: "supervisor"
              }
            },
            {
              $unwind: {
                path: "$supervisor",
                preserveNullAndEmptyArrays: true
              }
            },
            {
              $project: {
                _id: 1,
                rating: 1,
                comment: 1,
                createdAt: 1,
                supervisorName: "$supervisor.name"
              }
            }
          ],
          as: "latestReview"
        }
      },
      {
        $project: {
          _id: 0,
          storyId: "$_id",
          title: "$story.title",
          status: "$story.status",
          childId: "$story.childId",
          totalMinutes: { $round: [{ $divide: ["$totalSec", 60] }, 0] },
          latestReview: { $arrayElemAt: ["$latestReview", 0] },
          lastAt: 1
        }
      }
    ]);

    return {
      rangeDays: Number(rangeDays),
      children: children.map(c => ({ id: c._id, name: c.name })),
      histogram,
      stories
    };
  }
};

export default storyWritingTimeService;
