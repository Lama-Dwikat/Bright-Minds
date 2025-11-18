import Story from "../models/story.model.js";
import Template from "../models/template.model.js";
import StoryReview from "../models/reviewStory.model.js";
import StoryLike from "../models/storyLike.model.js";
import mongoose from "mongoose";
import ActivityLog from "../models/activityLog.model.js";

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

      if (templateId) {
        const template = await Template.findById(templateId);
        if (!template) throw new Error("Template not found");
        pages = Array.isArray(template.defaultPages) ? template.defaultPages : [];
      }

      const story = new Story({
        title,
        childId: new mongoose.Types.ObjectId(childId),
        pages,
        templateId,
        status: "draft",
        isDraft: true,
        startedBy,
        continuedByChild
      });

      await story.save();

      await ActivityLog.create({
        userId: childId,
        type: "create_story",
        timestamp: new Date(),
        status: "success"
      });

      return {
        storyId: story._id,
        title: story.title,
        pages: story.pages,
        status: story.status
      };
    } catch (error) {
      throw new Error("Error creating story: " + error.message);
    }
  },

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

      if (role !== "admin") {
        const isChildOwner = story.childId?._id?.toString() === userId;
        const isSupervisorAssigned = story.supervisorId?._id?.toString() === userId;
        const isParentOfChild = story.childId?.parentId?._id?.toString() === userId;

        if (!isChildOwner && !isAdmin) {
  throw new Error("You are not allowed to delete this story");
}

      }

      const [reviews, likesCount, userLiked] = await Promise.all([
        StoryReview.find({ storyId: story._id }).populate("supervisorId", "name email").sort({ createdAt: -1 }),
        StoryLike.countDocuments({ storyId }),
        userId ? StoryLike.findOne({ storyId, userId: new mongoose.Types.ObjectId(userId) }) : Promise.resolve(null)
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
  }



};

export default storyService;