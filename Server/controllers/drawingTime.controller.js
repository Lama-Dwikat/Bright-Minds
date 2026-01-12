import DrawingTimeSession from "../models/drawingTimeSession.model.js";
import User from "../models/user.model.js";
import ChildDrawing from "../models/childDrawing.model.js";

function diffSeconds(start, end) {
  const ms = end.getTime() - start.getTime();
  return Math.max(0, Math.floor(ms / 1000));
}

function startOfDayLocal(d) {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate(), 0, 0, 0, 0);
}

function nextDayStartLocal(d) {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1, 0, 0, 0, 0);
}

/**
 * Parses "YYYY-MM-DD" safely to local date start (00:00 local).
 * If string includes time, still normalizes to local day start.
 */
function parseDayStartLocal(input) {
  const d = new Date(input);
  // normalize to local start-of-day
  return startOfDayLocal(d);
}

/**
 * Parses "YYYY-MM-DD" to local next-day start (exclusive end boundary).
 */
function parseDayEndExclusiveLocal(input) {
  const d = new Date(input);
  return nextDayStartLocal(d); // exclusive
}

export const drawingTimeController = {
  // ✅ child starts timing
  async start(req, res) {
    try {
      if (req.user?.role !== "child") {
        return res.status(403).json({ error: "Only child can start timing" });
      }

      const { scope, activityId } = req.body;

      if (!scope || !["section", "activity"].includes(scope)) {
        return res
          .status(400)
          .json({ error: "scope must be section or activity" });
      }

      if (scope === "activity" && !activityId) {
        return res
          .status(400)
          .json({ error: "activityId is required for activity scope" });
      }

      // سكّر أي sessions مفتوحة لنفس scope (ولنفس activity إذا activity)
      const openQuery = {
        childId: req.user._id,
        scope,
        isActive: true,
      };
      if (scope === "activity") openQuery.activityId = activityId;

      const openSessions = await DrawingTimeSession.find(openQuery);

      if (openSessions.length) {
        const now = new Date();
        await Promise.all(
          openSessions.map(async (s) => {
            s.endedAt = now;
            s.durationSec += diffSeconds(s.startedAt, now);
            s.isActive = false;
            await s.save();
          })
        );
      }

      // ابدأ session جديد
      const session = await DrawingTimeSession.create({
        childId: req.user._id,
        scope,
        activityId: scope === "activity" ? activityId : null,
        startedAt: new Date(),
        isActive: true,
      });

      return res.status(201).json({
        message: "Timing started",
        sessionId: session._id,
        startedAt: session.startedAt,
      });
    } catch (error) {
      console.error("drawingTime start error:", error);
      return res.status(500).json({ error: error.message });
    }
  },

  // ✅ child stops timing
  async stop(req, res) {
    try {
      if (req.user?.role !== "child") {
        return res.status(403).json({ error: "Only child can stop timing" });
      }

      const { sessionId, scope, activityId, drawingId } = req.body;

      let session = null;

      if (sessionId) {
        session = await DrawingTimeSession.findOne({
          _id: sessionId,
          childId: req.user._id,
        });
      } else {
        const q = {
          childId: req.user._id,
          isActive: true,
        };
        if (scope) q.scope = scope;
        if (activityId) q.activityId = activityId;

        session = await DrawingTimeSession.findOne(q).sort({ startedAt: -1 });
      }

      if (!session) {
        return res.status(404).json({ error: "Session not found" });
      }

      // لو already stopped
      if (!session.isActive) {
        return res.status(200).json({
          message: "Session already stopped",
          sessionId: session._id,
          durationSec: session.durationSec,
        });
      }

      const now = new Date();
      session.endedAt = now;
      session.durationSec += diffSeconds(session.startedAt, now);
      session.isActive = false;

      // ✅ if provided, link to drawing
      // ⚠️ لازم يكون عندك drawingId موجود بالـ schema تبع DrawingTimeSession
      if (drawingId) session.drawingId = drawingId;

      await session.save();

      return res.status(200).json({
        message: "Timing stopped",
        sessionId: session._id,
        durationSec: session.durationSec,
        endedAt: session.endedAt,
      });
    } catch (error) {
      console.error("drawingTime stop error:", error);
      return res.status(500).json({ error: error.message });
    }
  },

  // ✅ parent report: totals + drawings + histogram by day (default last 7 days)
  async parentReport(req, res) {
    try {
      if (req.user?.role !== "parent") {
        return res.status(403).json({ error: "Only parent can view report" });
      }

      const TZ = "Asia/Hebron";
      const { from, to } = req.query;

      // default: last 7 days (inclusive)
      const today = new Date();
      const defaultFromStart = startOfDayLocal(
        new Date(today.getFullYear(), today.getMonth(), today.getDate() - 6)
      );
      const defaultToExclusive = nextDayStartLocal(today); // exclusive end

      const fromStart = from ? parseDayStartLocal(from) : defaultFromStart;
      const toExclusive = to ? parseDayEndExclusiveLocal(to) : defaultToExclusive;

      const kids = await User.find({ parentId: req.user._id }).select(
        "_id name ageGroup"
      );
      if (!kids.length) return res.status(200).json([]);

      const kidIds = kids.map((k) => k._id);

      // match only CLOSED sessions in range (inclusive by day using exclusive end)
      const match = {
        childId: { $in: kidIds },
        isActive: false,
        startedAt: { $gte: fromStart, $lt: toExclusive },
      };

      // 1) totals per kid
      const totalsByKid = await DrawingTimeSession.aggregate([
        { $match: match },
        {
          $group: {
            _id: "$childId",
            totalSec: { $sum: "$durationSec" },
            sectionSec: {
              $sum: {
                $cond: [
                  { $eq: ["$scope", "section"] },
                  "$durationSec",
                  0,
                ],
              },
            },
            activitySec: {
              $sum: {
                $cond: [
                  { $eq: ["$scope", "activity"] },
                  "$durationSec",
                  0,
                ],
              },
            },
          },
        },
      ]);

      // 2) per drawing time (only sessions linked to drawingId)
      const perDrawing = await DrawingTimeSession.aggregate([
        { $match: { ...match, scope: "activity", drawingId: { $ne: null } } },
        {
          $group: {
            _id: { childId: "$childId", drawingId: "$drawingId" },
            totalSec: { $sum: "$durationSec" },
            sessions: { $sum: 1 },
            lastAt: { $max: "$startedAt" },
          },
        },
        { $sort: { lastAt: -1 } },
      ]);

      const drawingIds = perDrawing.map((x) => x._id.drawingId);

      const drawingsDocs = drawingIds.length
        ? await ChildDrawing.find({ _id: { $in: drawingIds } })
            .populate("activityId", "title type")
            .select("_id childId activityId createdAt drawingImage")
        : [];

      const drawingDocMap = new Map(
        drawingsDocs.map((d) => [d._id.toString(), d])
      );

      const drawingsByKid = {};
      for (const row of perDrawing) {
        const kidId = row._id.childId.toString();
        const drId = row._id.drawingId.toString();
        const doc = drawingDocMap.get(drId);

        if (!drawingsByKid[kidId]) drawingsByKid[kidId] = [];

        if (doc) {
          drawingsByKid[kidId].push({
            drawingId: drId,
            activityId: doc.activityId?._id,
            activityTitle: doc.activityId?.title,
            activityType: doc.activityId?.type,
            createdAt: doc.createdAt,
            durationSec: row.totalSec,
            imageBase64: doc.drawingImage.data.toString("base64"),
            contentType: doc.drawingImage.contentType,
          });
        }
      }

      // 3) histogram by day per kid (canvas/activity only)
      const histogram = await DrawingTimeSession.aggregate([
        { $match: { ...match, scope: "activity" } },
        {
          $group: {
            _id: {
              childId: "$childId",
              day: {
                $dateToString: {
                  format: "%Y-%m-%d",
                  date: "$startedAt",
                  timezone: TZ,
                },
              },
            },
            totalSec: { $sum: "$durationSec" },
          },
        },
        { $sort: { "_id.day": 1 } },
      ]);

      const histogramByKid = {};
      for (const h of histogram) {
        const kidId = h._id.childId.toString();
        if (!histogramByKid[kidId]) histogramByKid[kidId] = [];
        histogramByKid[kidId].push({ day: h._id.day, totalSec: h.totalSec });
      }

      const totalsMap = new Map(totalsByKid.map((t) => [t._id.toString(), t]));

      const result = kids.map((k) => {
        const kidId = k._id.toString();
        const t = totalsMap.get(kidId) || {
          totalSec: 0,
          sectionSec: 0,
          activitySec: 0,
        };

        return {
          childId: k._id,
          childName: k.name,
          ageGroup: k.ageGroup,

          // range as ISO (helpful for frontend)
          range: {
            from: fromStart.toISOString(),
            toExclusive: toExclusive.toISOString(),
          },

          totalSec: t.totalSec,
          sectionSec: t.sectionSec,
          activitySec: t.activitySec,

          drawings: drawingsByKid[kidId] || [],
          histogram: histogramByKid[kidId] || [],
        };
      });

      return res.status(200).json(result);
    } catch (error) {
      console.error("parentReport error:", error);
      return res.status(500).json({ error: error.message });
    }
  },
};
