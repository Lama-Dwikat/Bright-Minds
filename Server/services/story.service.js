import Story from "../models/story.model.js";
import Template from "../models/template.model.js";
import StoryReview from "../models/reviewStory.model.js";
import StoryLike from "../models/storyLike.model.js";
import mongoose from "mongoose";
import ActivityLog from "../models/activityLog.model.js";
import User from "../models/user.model.js";

export const storyService = {

    // Create a new story
  async createStory({ title, childId, templateId = null, role }) {
  try {
    if (!["child", "admin", "supervisor"].includes(role)) {
      throw new Error("You are not allowed to create stories");
    }

    let pages = [];
    const startedBy = role === "supervisor" ? "supervisor" : "child";
    const continuedByChild = role === "child";

    // ✅ نحاول نجيب الطفل ونأخذ supervisorId لو موجود
    let supervisorId = null;
    try {
      const Child = mongoose.model("User"); // نفس اللي مستخدماه في getStoriesByChild
      const child = await User.findById(childId).select("supervisorId");

      if (!child) {
        console.warn("⚠️ Child not found when creating story, childId =", childId);
      } else if (!child.supervisorId) {
        console.warn("⚠️ Child has no supervisorId yet, story will be created without supervisorId");
      } else {
        supervisorId = child.supervisorId;
      }
    } catch (innerErr) {
      console.error("⚠️ Error while fetching child for supervisorId:", innerErr.message);
      // ما بنرمي error هون عشان ما نكسر إنشاء القصة
    }

    // 🧩 لو في template
    if (templateId) {
      const template = await Template.findById(templateId);
      if (!template) throw new Error("Template not found");
      pages = Array.isArray(template.defaultPages) ? template.defaultPages : [];
    }

    // ✅ إنشاء القصة (نضيف supervisorId بس لو موجود)
    const story = new Story({
      title,
      childId: new mongoose.Types.ObjectId(childId),
      supervisorId: supervisorId || undefined, // لو null ما ينحط
      pages,
      templateId,
      status: "draft",
      isDraft: true,
      startedBy,
      continuedByChild,
    });

    await story.save();

    await ActivityLog.create({
      userId: childId,
      type: "create_story",
      timestamp: new Date(),
      status: "success",
    });

    return {
      storyId: story._id,
      title: story.title,
      pages: story.pages,
      status: story.status,
      supervisorId: story.supervisorId || null,
    };
  } catch (error) {
    throw new Error("Error creating story: " + error.message);
  }
}
,

 async updateStory({ storyId, userId, role, storyData }) {
    try {

      const story = await Story.findById(storyId)
      .populate("childId", "_id name parentId")
      .populate("supervisorId", "_id name");
      if (!story) throw new Error("Story not found");

       const isChildOwner = story.childId?._id?.toString() === userId;
    const isSupervisorAssigned = story.supervisorId?._id?.toString() === userId;

     if (role === "child" && !isChildOwner)
      throw new Error("You are not allowed to edit this story");
    if (role === "parent")
      throw new Error("Parents are not allowed to edit stories");
    if (role === "supervisor" && !isSupervisorAssigned)
      throw new Error("You are not assigned as the supervisor for this story");
    if (!["draft", "needs_edit"].includes(story.status) && !["admin", "supervisor"].includes(role)) {
      throw new Error("Only stories with status 'draft' or 'needs_edit' can be updated");
    }

      let allowedFields = [];
      switch (role) {
        case "child":
          allowedFields = ["title", "pages", "templateId", "continuedByChild", "coverImage"];
          break;
        case "supervisor":
          allowedFields = ["status", "reviewNotes", "startedBy"];
          break;
        case "admin":
          allowedFields = ["title", "pages", "templateId", "status", "supervisorId", "startedBy", "continuedByChild"];
          break;
        default:
          throw new Error("Invalid role");
      }

      for (const key of Object.keys(storyData)) {
        if (allowedFields.includes(key)) story[key] = storyData[key];
      }

      await story.save();
      return story;
    } catch (error) {
      throw new Error("Error updating story: " + error.message);
    }
  },

    async submitStory({ storyId, userId, role }) {
  try {
    const story = await Story.findById(storyId).populate("childId", "_id");
    if (!story) throw new Error("Story not found");

    const isChildOwner = story.childId?._id?.toString() === userId.toString();

    if (role !== "child")
      throw new Error("You are not allowed to submit stories");

    if (!isChildOwner)
      throw new Error("You are not allowed to submit this story");

    if (story.startedBy === "supervisor")
      story.continuedByChild = true;

    if (!["draft", "needs_edit"].includes(story.status))
      throw new Error("Only draft or needs_edit stories can be submitted");

    story.status = "pending";
    story.isDraft = false;
    await story.save();

    return story;

  } catch (error) {
    throw new Error("Error submitting story: " + error.message);
  }
},

async deleteStory({ storyId, userId, role }) {
  try {
    const story = await Story.findById(storyId);

    if (!story) throw new Error("Story not found or already deleted");

    const storyChildId = story.childId?.toString();
    const isChildOwner = storyChildId === userId.toString();  // ← الحل
    const isAdmin = role === "admin";

    if (!isChildOwner && !isAdmin)
      throw new Error("You are not allowed to delete this story");

    await Story.deleteOne({ _id: storyId });

    return { message: "Story deleted successfully" };
  } catch (error) {
    throw new Error("Error deleting story: " + error.message);
  }
},


   async getStoryById({ storyId, userId = null, role }) {
  try {
    const story = await Story.findById(storyId)
      .populate("childId", "name parentId")
      .populate("supervisorId", "name")
      .populate("templateId", "name defaultTheme")
      .lean();

    if (!story) throw new Error("Story not found");

    const isAdmin = role === "admin";

    // 🧠 نحول كل الإيَدات لـ string عشان المقارنة تكون صح
    const userIdStr = userId ? userId.toString() : null;
    const childIdStr = story.childId?._id?.toString() || null;
    const supervisorIdStr = story.supervisorId?._id?.toString() || null;
    const parentIdStr = story.childId?.parentId?._id?.toString() || null;

    console.log("CHILD OWNER CHECK");
    console.log("UserId:", userIdStr);
    console.log("Story childId:", childIdStr);
    console.log("Story supervisorId:", supervisorIdStr);
    console.log("Story parentId:", parentIdStr);
    console.log("role:", role);

    if (!isAdmin) {
      const isChildOwner =
        userIdStr && childIdStr && childIdStr === userIdStr;

      const isSupervisorAssigned =
        userIdStr && supervisorIdStr && supervisorIdStr === userIdStr;

      const isParentOfChild =
        userIdStr && parentIdStr && parentIdStr === userIdStr;

      if (!isChildOwner && !isSupervisorAssigned && !isParentOfChild) {
        throw new Error("You are not allowed to view this story");
      }
    }

    const [reviews, likesCount, userLiked] = await Promise.all([
      StoryReview.find({ storyId: story._id })
        .populate("supervisorId", "name email")
        .sort({ createdAt: -1 }),

      StoryLike.countDocuments({ storyId: story._id }),

      userIdStr
        ? StoryLike.findOne({
            storyId: story._id,
            userId: new mongoose.Types.ObjectId(userIdStr),
          })
        : Promise.resolve(null),
    ]);

    story.reviews = reviews;
    story.likesCount = likesCount;
    story.userLiked = !!userLiked;

    return story;
  } catch (error) {
    throw new Error("Error fetching story: " + error.message);
  }
},

async getStoriesByChild({ childId, status = null, userId = null, role }) {
  try {
    const childIdStr = childId.toString();
    const userIdStr = userId?.toString();
       
    if (role !== "admin") {
      if (role === "child" && userIdStr !== childIdStr) {
        throw new Error("You are not allowed to view other children's stories");
      }

      if (role === "parent") {
        const ChildModel = mongoose.model("Child");
        const child = await ChildModel.findById(childId).populate("parentId", "_id");
        const parentIdStr = child?.parentId?._id?.toString();
        if (!child || parentIdStr !== userIdStr) {
          throw new Error("You are not allowed to view this child's stories");
        }
      }

      if (role === "supervisor") {
        const storyExample = await Story.findOne({ childId: new mongoose.Types.ObjectId(childId) });
        const supervisorIdStr = storyExample?.supervisorId?.toString();
        if (storyExample && supervisorIdStr !== userIdStr) {
          throw new Error("You are not allowed to view this child's stories");
        }
      }
    }

    const query = { childId: new mongoose.Types.ObjectId(childId) };
    if (status) query.status = status;

    const stories = await Story.find(query)
      .populate("childId", "name parentId")
      .populate("supervisorId", "name")
      .populate("templateId", "name defaultTheme")
      .sort({ createdAt: -1 })
      .lean();

    const filteredStories = stories.filter((story) => {
      const storyChildId = story.childId?._id?.toString();
      const parentId = story.childId?.parentId?._id?.toString();
      const supervisorId = story.supervisorId?._id?.toString();

      if (role === "admin") return true;
      if (role === "child") return storyChildId === userIdStr;
      if (role === "parent") return parentId === userIdStr;
      if (role === "supervisor") return supervisorId === userIdStr;
      return false;
    });

    const storiesWithDetails = await Promise.all(
      filteredStories.map(async (story) => {
        const [reviews, likesCount, userLiked] = await Promise.all([
          StoryReview.find({ storyId: story._id }).populate("supervisorId", "name email").sort({ createdAt: -1 }),
          StoryLike.countDocuments({ storyId: story._id }),
          userId ? StoryLike.findOne({ storyId: story._id, userId: new mongoose.Types.ObjectId(userIdStr) }) : Promise.resolve(null),
        ]);

        story.reviews = reviews;
        story.likesCount = likesCount;
        story.userLiked = !!userLiked;

        return story;
      })
    );

    return storiesWithDetails;
  } catch (error) {
    throw new Error("Error fetching stories: " + error.message);
  }
},



  async addMediaToStory({ storyId, mediaUrl, mediaType = "image", pageIndex = 0 }) {
    try {
      const story = await Story.findById(storyId);
      if (!story) throw new Error("Story not found");

      if (mediaType === "image" && !mediaUrl.match(/\.(jpg|jpeg|png|gif)$/i)) {
        throw new Error("Invalid media type. Only image URLs are allowed.");
      }

      if (!story.pages) story.pages = [];
      if (!story.pages[pageIndex]) story.pages[pageIndex] = { elements: [] };
      if (!story.pages[pageIndex].elements) story.pages[pageIndex].elements = [];

      const nextOrder = story.pages[pageIndex].elements.length + 1;

      story.pages[pageIndex].elements.push({
        type: mediaType,
        media: { mediaType, url: mediaUrl, page: pageIndex + 1, elementOrder: nextOrder },
        x: 0,
        y: 0,
        width: 100,
        height: 100,
        order: nextOrder
      });

      await story.save();
      return story;
    } catch (error) {
      throw new Error("Failed to add media: " + error.message);
    }
  },

  async resubmitStory({ storyId, childId }) {
    try {
      const story = await Story.findById(storyId);
      if (!story) throw new Error("Story not found");

      if (story.childId.toString() !== childId.toString()) {
        throw new Error("Unauthorized: You cannot resubmit someone else's story");
      }

      if (story.status !== "needs_edit") {
        throw new Error("Story must be in 'needs_edit' status to resubmit");
      }

      if (story.startedBy === "supervisor" && !story.continuedByChild) {
        story.continuedByChild = true;
      }

      story.status = "pending";
      story.isDraft = false;
      await story.save();

      if (!story.supervisorId) throw new Error("No supervisor assigned to this story");

      const review = new StoryReview({
        storyId: story._id,
        supervisorId: story.supervisorId,
        status: "pending"
      });
      await review.save();

      return { message: "Story resubmitted for review", story, review };
    } catch (error) {
      throw new Error("Error resubmitting story: " + error.message);
    }
  },
  

async getStoriesForSupervisor({ supervisorId, role, status = null }) {
  try {
    if (role !== "supervisor" && role !== "admin") {
      throw new Error("Only supervisors or admins can view these stories");
    }

    const query = {
      supervisorId: new mongoose.Types.ObjectId(supervisorId),
    };

    if (status) {
      query.status = status; // اختياري لو حبيتي تدعمي فلترة من الفرونت
    }

    let stories = await Story.find(query)
      .populate("childId", "name")
      .sort({ updatedAt: -1 })
      .lean();

    // نخلي الـ pending أول شي
    const statusOrder = {
      pending: 0,
      needs_edit: 1,
      approved: 2,
      rejected: 3,
    };

    stories.sort((a, b) => {
      const sa = statusOrder[a.status] ?? 99;
      const sb = statusOrder[b.status] ?? 99;
      if (sa !== sb) return sa - sb;
      const da = a.updatedAt ? new Date(a.updatedAt) : 0;
      const db = b.updatedAt ? new Date(b.updatedAt) : 0;
      return db - da; // الأحدث أولاً
    });

    return stories;
  } catch (error) {
    throw new Error("Error fetching supervisor stories: " + error.message);
  }
},




};

export default storyService;