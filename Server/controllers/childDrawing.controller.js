import ChildDrawing from "../models/childDrawing.model.js";
import DrawingActivity from "../models/drawingActivity.model.js";
import User from "../models/user.model.js";
import { Notification } from "../models/notification.model.js";

export const childDrawingController = {

 async saveChildDrawing(req, res) {
  try {
    const { activityId, drawingImage } = req.body;

    if (!activityId || !drawingImage) {
      return res
        .status(400)
        .json({ error: "activityId and drawingImage are required" });
    }

    // نتأكد من الـ Activity
    const activity = await DrawingActivity.findById(activityId);
    if (!activity) {
      return res.status(404).json({ error: "Activity not found" });
    }

    // نحفظ الرسم
    const drawing = new ChildDrawing({
      childId: req.user._id,
      activityId,
      drawingImage: {
        data: Buffer.from(drawingImage, "base64"),
        contentType: "image/png",
      },
    });

    await drawing.save();

    // 🔔 Notification للأهل (لو للطفل Parent مربوط)
    try {
      const child = await User.findById(req.user._id).select(
        "name parentId ageGroup"
      );

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
      // ما منرجع error عشان الإشعار ما يكسّر حفظ الرسم
    }

    return res
      .status(201)
      .json({ message: "Drawing saved", id: drawing._id });
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
        .populate("activityId", "title")
        .sort({ createdAt: -1 }); // الأحدث أولاً

      const result = drawings.map((d) => ({
        id: d._id,
        activityId: d.activityId?._id,
        activityTitle: d.activityId?.title,
        createdAt: d.createdAt,
        imageBase64: d.drawingImage.data.toString("base64"),
        contentType: d.drawingImage.contentType,
      }));

      res.status(200).json(result);
    } catch (error) {
      res.status(500).json({ error: error.message });
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
    })
      .populate("childId", "name ageGroup")
      .populate("activityId", "title type")
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

};