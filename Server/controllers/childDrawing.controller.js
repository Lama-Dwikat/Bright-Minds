import ChildDrawing from "../models/childDrawing.model.js";
import DrawingActivity from "../models/drawingActivity.model.js";
import User from "../models/user.model.js";
import { Notification } from "../models/notification.model.js";
import DrawingTimeSession from "../models/drawingTimeSession.model.js";
import cloudinaryService from "../services/cloudinary.service.js"; 

export const childDrawingController = {

async saveChildDrawing(req, res) {
  try {
    let { activityId, drawingImage } = req.body;

    if (!activityId || !drawingImage) {
      return res
        .status(400)
        .json({ error: "activityId and drawingImage are required" });
    }

    // ✅ تأكد من الـ Activity
    const activity = await DrawingActivity.findById(activityId);
    if (!activity) {
      return res.status(404).json({ error: "Activity not found" });
    }

    // ✅ يدعم حالتين:
    // 1) base64 raw: "AAAA..."
    // 2) data uri: "data:image/png;base64,AAAA..."
    let contentType = "image/png";
    if (typeof drawingImage === "string" && drawingImage.startsWith("data:")) {
      const match = drawingImage.match(/^data:(image\/[a-zA-Z0-9.+-]+);base64,(.*)$/);
      if (!match) {
        return res.status(400).json({ error: "Invalid image data URI" });
      }
      contentType = match[1];
      drawingImage = match[2];
    }

    if (typeof drawingImage !== "string") {
      return res.status(400).json({ error: "drawingImage must be a base64 string" });
    }

    // ✅ تحويل base64 -> Buffer مع تحقق
    const buf = Buffer.from(drawingImage, "base64");
    if (!buf || buf.length === 0) {
      return res.status(400).json({ error: "Invalid base64 image" });
    }

    // ✅ حماية من حجم كبير (Mongo limit 16MB + headers)
    // خليه 8MB safe (غيّريه إذا بدك)
    const MAX_BYTES = 8 * 1024 * 1024;
    if (buf.length > MAX_BYTES) {
      return res.status(413).json({
        error: "Image too large. Please reduce image size/quality.",
        maxBytes: MAX_BYTES,
        sizeBytes: buf.length,
      });
    }

    // ✅ نحفظ الرسم
    const drawing = new ChildDrawing({
      childId: req.user._id,
      activityId,
      drawingImage: {
        data: buf,
        contentType,
      },
    });

    await drawing.save();

    // ✅ Link timing session to this drawing + stop it
    try {
      const now = new Date();

      const open = await DrawingTimeSession.findOne({
        childId: req.user._id,
        scope: "activity",
        activityId,
        isActive: true,
      }).sort({ startedAt: -1 });

      if (open) {
        open.drawingId = drawing._id;
        open.endedAt = now;

        const diffSec = Math.max(
          0,
          Math.floor((now.getTime() - open.startedAt.getTime()) / 1000)
        );

        open.durationSec += diffSec;
        open.isActive = false;
        await open.save();

        // ✅ Start a new session immediately (so time continues if kid keeps drawing)
        await DrawingTimeSession.create({
          childId: req.user._id,
          scope: "activity",
          activityId,
          startedAt: now,
          isActive: true,
        });
      }
    } catch (timingErr) {
      console.error("Timing link/stop error:", timingErr.message);
    }

    // 🔔 Notification للأهل
    try {
      const child = await User.findById(req.user._id).select("name parentId ageGroup");

      if (child?.parentId) {
        const message = `Your child ${child.name} created a new drawing in the Drawing section 🎨`;

        await Notification.create({
          userId: child.parentId,
          title: "New Drawing",
          message,
          type: "drawing",
          isRead: false,
        });
      }
    } catch (notifyErr) {
      console.error("Notification error (new drawing):", notifyErr.message);
    }

    return res.status(201).json({ message: "Drawing saved", id: drawing._id });
  } catch (error) {
    console.error("saveChildDrawing error:", error);
    return res.status(500).json({ error: error.message });
  }
},



   // الحصول على كل رسومات الطفل (My Drawings)
  async getChildDrawings(req, res) {
    try {
      const drawings = await ChildDrawing.find({
        childId: req.user._id,
      })
        .populate(
  "activityId",
  "title type regionsCount outlineImageUrl maskImageUrl legend"
)

        .sort({ createdAt: -1 }); // الأحدث أولاً

      const result = drawings.map((d) => ({
        id: d._id,
        activityId: d.activityId?._id,
        activityTitle: d.activityId?.title || "My Drawing",
        createdAt: d.createdAt,
        imageBase64: d.drawingImage.data.toString("base64"),
        contentType: d.drawingImage.contentType,
        // ✨ الجديد:
        rating: d.rating ?? null,
        supervisorComment: d.supervisorComment ?? "",
      }));

      return res.status(200).json(result);
    } catch (error) {
      console.error("getChildDrawings error:", error);
      return res.status(500).json({ error: error.message });
    }
  },


    
  async getLastChildDrawingForActivity(req, res) {
    try {
      const { activityId } = req.params;

      if (!activityId) {
        return res.status(400).json({ error: "activityId is required" });
      }

      const drawing = await ChildDrawing.findOne({
        activityId: activityId,
        childId: req.user._id,
      }).sort({ createdAt: -1 });

      if (!drawing) {
        return res.status(404).json({ error: "No drawing found for this activity" });
      }

      const base64Image = drawing.drawingImage.data.toString("base64");

      return res.status(200).json({
        imageBase64: base64Image,
        contentType: drawing.drawingImage.contentType,
      });
    } catch (error) {
      return res.status(500).json({ error: error.message });
    }
  },


  async deleteChildDrawing(req, res) {
    try {
      const { id } = req.params;

      if (!id) {
        return res.status(400).json({ error: "Drawing id is required" });
      }

      // نجيب الرسم
      const drawing = await ChildDrawing.findById(id);

      if (!drawing) {
        return res.status(404).json({ error: "Drawing not found" });
      }

      // نتأكد إنه تبع نفس الطفل
      if (drawing.childId.toString() !== req.user._id.toString()) {
        return res
          .status(403)
          .json({ error: "You are not allowed to delete this drawing" });
      }

      await drawing.deleteOne();

      console.log("✅ Drawing deleted:", id);

      return res.status(200).json({ message: "Drawing deleted successfully" });
    } catch (error) {
      console.error("Delete drawing error:", error);
      return res.status(500).json({ error: error.message });
    }
  },

  // 👩‍🏫 supervisor: كل رسومات الأطفال تحت إشرافه
async getKidsDrawingsForSupervisor(req, res) {
  try {
    // نجيب الأطفال اللي supervisor تبعهم هو المستخدم الحالي
    const kids = await User.find({ supervisorId: req.user._id }).select(
      "_id name ageGroup"
    );

    if (!kids.length) {
      return res.status(200).json([]); // ما في أطفال
    }

    const kidIds = kids.map((k) => k._id);

    const drawings = await ChildDrawing.find({
      childId: { $in: kidIds },
       isSubmitted: true,
    })
      .populate("childId", "name ageGroup")
      .populate(
  "activityId",
  "title type regionsCount outlineImageUrl maskImageUrl legend"
)

      .sort({ createdAt: -1 });

    const result = drawings.map((d) => ({
      id: d._id,
      childId: d.childId?._id,
      childName: d.childId?.name,
      childAgeGroup: d.childId?.ageGroup,
      activityId: d.activityId?._id,
      activityTitle: d.activityId?.title,
      activityType: d.activityId?.type,
      createdAt: d.createdAt,
      supervisorComment: d.supervisorComment,
      rating: d.rating,
      drawingUrl: d.drawingUrl || "",

     // imageBase64: d.drawingImage.data.toString("base64"),
     // contentType: d.drawingImage.contentType,
    }));

    return res.status(200).json(result);
  } catch (error) {
    console.error("getKidsDrawingsForSupervisor error:", error);
    return res.status(500).json({ error: error.message });
  }
},
// ⭐ supervisor: إضافة / تعديل Comment + Rating لرسم طفل
async reviewChildDrawing(req, res) {
  try {
    const { id } = req.params;
    const { comment, rating } = req.body;

    if (!id) {
      return res.status(400).json({ error: "Drawing id is required" });
    }

    const drawing = await ChildDrawing.findById(id).populate(
      "childId",
      "supervisorId name"
    );

    if (!drawing) {
      return res.status(404).json({ error: "Drawing not found" });
    }

    // نتأكد إن الطفل تابع لهذا السوبرفايزر
    if (
      !drawing.childId?.supervisorId ||
      drawing.childId.supervisorId.toString() !== req.user._id.toString()
    ) {
      return res
        .status(403)
        .json({ error: "You are not allowed to review this drawing" });
    }

    if (comment !== undefined) {
      drawing.supervisorComment = comment;
    }

    if (rating !== undefined) {
      drawing.rating = rating; // تأكدنا من min/max بالـ schema
    }

    await drawing.save();
// 🔔 notify child + parent when reviewed
try {
  const child = await User.findById(drawing.childId._id).select("name parentId");
  const msg = `Your drawing was reviewed ⭐ (${drawing.rating ?? "no rating"})`;

  // للطفل
  await Notification.create({
    userId: drawing.childId._id,
    title: "Drawing Reviewed",
    message: msg,
    type: "drawing",
    drawingId: drawing._id,
    activityId: drawing.activityId,
    fromUserId: req.user._id,
    isRead: false,
  });

  // للأهل (لو موجود parent)
  if (child?.parentId) {
    await Notification.create({
      userId: child.parentId,
      title: "Your child’s drawing was reviewed",
      message: `Your child ${child.name}'s drawing was reviewed ⭐ (${drawing.rating ?? "no rating"})`,
      type: "drawing",
      drawingId: drawing._id,
      activityId: drawing.activityId,
      fromUserId: req.user._id,
      isRead: false,
    });
  }
} catch (e) {
  console.log("notify review error:", e.message);
}

    return res.status(200).json({
      message: "Review updated",
      id: drawing._id,
      supervisorComment: drawing.supervisorComment,
      rating: drawing.rating,
    });
  } catch (error) {
    console.error("reviewChildDrawing error:", error);
    return res.status(500).json({ error: error.message });
  }
},


async getKidsDrawingsForParent(req, res) {
  try {
    // نجيب الأطفال اللي parent تبعهم هو المستخدم الحالي
    const kids = await User.find({ parentId: req.user._id }).select(
      "_id name ageGroup"
    );

    if (!kids.length) {
      return res.status(200).json([]); // ما في أطفال
    }

    const kidIds = kids.map((k) => k._id);

    const drawings = await ChildDrawing.find({
      childId: { $in: kidIds },
      isSubmitted: true,
    })
      .populate("childId", "name ageGroup")
      .populate(
  "activityId",
  "title type regionsCount outlineImageUrl maskImageUrl legend"
)

      .sort({ createdAt: -1 });

    const result = drawings.map((d) => ({
      id: d._id,
      childId: d.childId?._id,
      childName: d.childId?.name,
      childAgeGroup: d.childId?.ageGroup,
      activityId: d.activityId?._id,
      activityTitle: d.activityId?.title,
      activityType: d.activityId?.type,
      createdAt: d.createdAt,
      supervisorComment: d.supervisorComment,
      rating: d.rating,
      imageBase64: d.drawingImage.data.toString("base64"),
      contentType: d.drawingImage.contentType,
      isSubmitted: d.isSubmitted,
      submittedAt: d.submittedAt,

    }));

    return res.status(200).json(result);
  } catch (error) {
    console.error("getKidsDrawingsForParent error:", error);
    return res.status(500).json({ error: error.message });
  }
},
async submitChildDrawing(req, res) {
  try {
    const { id } = req.params; // drawingId
    if (!id) return res.status(400).json({ error: "drawing id is required" });

    // نجيب الرسم ونتأكد انه للطفل الحالي
    const drawing = await ChildDrawing.findById(id);
    if (!drawing) return res.status(404).json({ error: "Drawing not found" });

    if (drawing.childId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ error: "Not allowed" });
    }

    // لو already submitted ما نكرر
    if (drawing.isSubmitted) {
      return res.status(200).json({
        message: "Already submitted",
        id: drawing._id,
        isSubmitted: true,
        submittedAt: drawing.submittedAt,
      });
    }

    drawing.isSubmitted = true;
    drawing.submittedAt = new Date();
    await drawing.save();

    // 🔔 Notifications (اختياري)
    try {
      const child = await User.findById(req.user._id).select("name parentId supervisorId");
      if (child?.supervisorId) {
        await Notification.create({
          userId: child.supervisorId,
          title: "New Drawing Submitted",
          message: `Child ${child.name} submitted a drawing for review 🎨`,
          type: "drawing",
          isRead: false,
        });
      }
      if (child?.parentId) {
        await Notification.create({
          userId: child.parentId,
          title: "Drawing Submitted",
          message: `Your child ${child.name} submitted a drawing for review ✅`,
          type: "drawing",
          isRead: false,
        });
      }
    } catch (e) {
      console.log("submit notification error:", e.message);
    }

    return res.status(200).json({
      message: "Submitted ✅",
      id: drawing._id,
      isSubmitted: true,
      submittedAt: drawing.submittedAt,
    });
  } catch (error) {
    console.error("submitChildDrawing error:", error);
    return res.status(500).json({ error: error.message });
  }
},
/*async submitDrawingImage(req, res) {
  try {
    let { activityId, drawingImage } = req.body;

    if (!activityId || !drawingImage) {
      return res.status(400).json({ error: "activityId and drawingImage are required" });
    }

    // ✅ تأكد من الـ Activity (ومنها نجيب supervisorId)
    const activity = await DrawingActivity.findById(activityId).select("title supervisorId");
    if (!activity) return res.status(404).json({ error: "Activity not found" });

    // ✅ يدعم data uri أو base64 raw
    let contentType = "image/png";
    if (typeof drawingImage === "string" && drawingImage.startsWith("data:")) {
      const match = drawingImage.match(/^data:(image\/[a-zA-Z0-9.+-]+);base64,(.*)$/);
      if (!match) return res.status(400).json({ error: "Invalid image data URI" });
      contentType = match[1];
      drawingImage = match[2];
    }

    if (typeof drawingImage !== "string") {
      return res.status(400).json({ error: "drawingImage must be a base64 string" });
    }

    const buf = Buffer.from(drawingImage, "base64");
    if (!buf || buf.length === 0) return res.status(400).json({ error: "Invalid base64 image" });

    // ✅ limit
    const MAX_BYTES = 8 * 1024 * 1024;
    if (buf.length > MAX_BYTES) {
      return res.status(413).json({
        error: "Image too large. Please reduce image size/quality.",
        maxBytes: MAX_BYTES,
        sizeBytes: buf.length,
      });
    }

    // ✅ حفظ + Submit مباشرة
    const now = new Date();

    const drawing = await ChildDrawing.create({
      childId: req.user._id,
      activityId,
      drawingImage: { data: buf, contentType },

      // هدول لازم يكونوا موجودين بالـ schema عندك
      isSubmitted: true,
      submittedAt: now,
    });

    // 🔔 Notifications للسوبرفايزر + للأهل
    try {
      const child = await User.findById(req.user._id).select("name parentId");
      const supervisorId = activity.supervisorId; // الأفضل من الـ activity نفسها

      if (supervisorId) {
        await Notification.create({
          userId: supervisorId,
          title: "New Drawing Submitted",
          message: `Child ${child?.name ?? "A child"} submitted a drawing for review 🎨`,
          type: "drawing",
          drawingId: drawing._id,
          activityId: activity._id,
          fromUserId: req.user._id,
          isRead: false,
        });
      }

      if (child?.parentId) {
        await Notification.create({
          userId: child.parentId,
          title: "Drawing Submitted",
          message: `Your child ${child.name} submitted a drawing for review ✅`,
          type: "drawing",
          drawingId: drawing._id,
          activityId: activity._id,
          fromUserId: req.user._id,
          isRead: false,
        });
      }
    } catch (e) {
      console.log("submitDrawingImage notification error:", e.message);
    }

    return res.status(201).json({
      message: "Saved & submitted ✅",
      id: drawing._id,
      isSubmitted: true,
      submittedAt: now,
    });
  } catch (error) {
    console.error("submitDrawingImage error:", error);
    return res.status(500).json({ error: error.message });
  }
},
*/
async submitDrawingImage(req, res) {
    try {
      let { activityId, drawingImage, autoSubmit } = req.body;

      if (!activityId || !drawingImage) {
        return res
          .status(400)
          .json({ error: "activityId and drawingImage are required" });
      }

      const activity = await DrawingActivity.findById(activityId);
      if (!activity) return res.status(404).json({ error: "Activity not found" });

      // ✅ supports dataUri or raw base64
      let contentType = "image/png";
      if (typeof drawingImage === "string" && drawingImage.startsWith("data:")) {
        const match = drawingImage.match(
          /^data:(image\/[a-zA-Z0-9.+-]+);base64,(.*)$/
        );
        if (!match) return res.status(400).json({ error: "Invalid image data URI" });
        contentType = match[1];
        drawingImage = match[2];
      }

      if (typeof drawingImage !== "string") {
        return res.status(400).json({ error: "drawingImage must be a base64 string" });
      }

      const buf = Buffer.from(drawingImage, "base64");
      if (!buf || buf.length === 0) {
        return res.status(400).json({ error: "Invalid base64 image" });
      }

      const MAX_BYTES = 8 * 1024 * 1024;
      if (buf.length > MAX_BYTES) {
        return res.status(413).json({
          error: "Image too large. Please reduce image size/quality.",
          maxBytes: MAX_BYTES,
          sizeBytes: buf.length,
        });
      }

      // ✅ upload to cloudinary
      const folder = "drawings";
      const drawingUrl = await cloudinaryService.uploadBuffer(buf, folder);

      // ✅ save in DB
      const drawing = await ChildDrawing.create({
        childId: req.user._id,
        activityId,
        drawingImage: { data: buf, contentType }, // keep buffer for old usage/fallback
        drawingUrl,
      });

      // ✅ autoSubmit => visible to supervisor immediately
      if (autoSubmit === true) {
        drawing.isSubmitted = true;
        drawing.submittedAt = new Date();
        await drawing.save();

        try {
          const child = await User.findById(req.user._id).select(
            "name parentId supervisorId"
          );

          if (child?.supervisorId) {
            await Notification.create({
              userId: child.supervisorId,
              title: "New Drawing Submitted",
              message: `Child ${child.name} submitted a drawing for review 🎨`,
              type: "drawing",
              isRead: false,
              drawingId: drawing._id,
              activityId,
            });
          }

          if (child?.parentId) {
            await Notification.create({
              userId: child.parentId,
              title: "Drawing Submitted",
              message: `Your child ${child.name} submitted a drawing for review ✅`,
              type: "drawing",
              isRead: false,
              drawingId: drawing._id,
              activityId,
            });
          }
        } catch (e) {
          console.log("autoSubmit notify error:", e.message);
        }
      }

      return res.status(201).json({
        message: "Drawing saved ✅",
        id: drawing._id,
        drawingUrl,
        isSubmitted: drawing.isSubmitted,
        submittedAt: drawing.submittedAt,
      });
    } catch (error) {
      console.error("submitDrawingImage error:", error);
      return res.status(500).json({ error: error.message });
    }
  },

/*async getDrawingImageForSupervisor(req, res) {
  try {
    const { id } = req.params; // drawingId
    if (!id) return res.status(400).json({ error: "drawing id is required" });

    const drawing = await ChildDrawing.findById(id).populate("childId", "supervisorId");
    if (!drawing) return res.status(404).json({ error: "Drawing not found" });

    // ✅ تأكد إنه الرسم لطفل تابع لهالسوبرفايزر
    if (
      !drawing.childId?.supervisorId ||
      drawing.childId.supervisorId.toString() !== req.user._id.toString()
    ) {
      return res.status(403).json({ error: "Not allowed" });
    }

    res.set("Content-Type", drawing.drawingImage?.contentType || "image/png");
    res.set("Cache-Control", "no-store");
    return res.status(200).send(drawing.drawingImage.data); // ✅ bytes
  } catch (error) {
    console.error("getDrawingImageForSupervisor error:", error);
    return res.status(500).json({ error: error.message });
  }
},*/

async getDrawingImageForSupervisor(req, res) {
    try {
      const { id } = req.params;

      const drawing = await ChildDrawing.findById(id).populate(
        "childId",
        "supervisorId"
      );

      if (!drawing) return res.status(404).json({ error: "Drawing not found" });

      // ✅ check supervisor permission
      if (
        !drawing.childId?.supervisorId ||
        drawing.childId.supervisorId.toString() !== req.user._id.toString()
      ) {
        return res.status(403).json({ error: "Not allowed" });
      }

      // ✅ if cloudinary url exists => redirect
      if (drawing.drawingUrl && drawing.drawingUrl.trim() !== "") {
        return res.redirect(drawing.drawingUrl);
      }

      // ✅ fallback buffer
      res.set("Content-Type", drawing.drawingImage?.contentType || "image/png");
      res.set("Cache-Control", "no-store");
      return res.send(drawing.drawingImage.data);
    } catch (e) {
      console.error("getDrawingImageForSupervisor error:", e);
      return res.status(500).json({ error: e.message });
    }
  },


};