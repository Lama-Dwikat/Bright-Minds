import Story from "../models/story.model";
import Template from "../models/template.model";
import StoryReview from "../models/reviewStory.model";
import StoryLike from "./storyLike.service";
import mongoose from "mongoose";

export const storyService = {

    // Create a new story
    async createStory({title, childId, templateId= null}) {
        try {
            let pages = [];


            // If a templateId is provided, fetch the template and use its pages
            if (templateId) {
                const template = await Template.findById(templateId);
                if (!template) {
                    throw new Error("Template not found");
                }
                pages = template.defaultPages;
            }


        const story = new Story({
            title,
            childId,
            pages,
            templateId,
            status: "draft",// default status
            isDraft: true 
        });

           await story.save();
              return story;
        } 
        catch (error) {
            throw new Error("Error creating story: " + error.message);
        }
    },


    async updateStory({storyId,childId, storyData}) {
        try {

            const story = await Story.findOne({ _id: storyId, childId });
            if (!story) {
                throw new Error("Story not found");
            }

            if (!["draft","needs_edit"].includes(story.status)) {
                throw new Error("Only stories with status 'draft' or 'need_edit' can be updated");
            }

            Object.assign(story, storyData);
            await story.save();
            return story;   

        } catch (error) {
            throw new Error("Error updating story: " + error.message);
        }
    },

    async submitStory({storyId, childId,supervisorId}) {

        try {
            const story = await Story.findOne({ _id: storyId, childId });
            if (!story) {
                throw new Error("Story not found");
            }

            if (story.status !== "draft" || story.status !=="needs_edit") {
                throw new Error("story already submitted");
            }

            story.status = "pending";
            story.isDraft = false;
            //story.supervisorId = supervisorId;
            await story.save();
            return story;
        } catch (error) {
            throw new Error("Error submitting story: " + error.message);
        }
    },


    async deleteStory({storyId, childId}) {
        try {
            const story = await Story.findOne({ _id: storyId, childId });
            if (!story) {
                throw new Error("Story not found or already deleted");
            }
            if (!["draft","needs_edit"].includes(story.status)) {
                throw new Error("Only stories with status 'draft' or 'needs_edit' can be deleted");
            }
            await Story.deleteOne({ _id: storyId});
            return { message: "Story deleted successfully" };

        } catch (error) {
            throw new Error("Error deleting story: " + error.message);
        }
    },


    async getStoryById({storyId}) {
        try {
            const story = await Story.findById(storyId)
             .populate("childId", "name")
             .populate("supervisorId", "name")
             .populate("templateId", "name defaultTheme")
             .lean();
           if (!story) {
                throw new Error("Story not found");
            }
            const reviews = await StoryReview.find({ storyId: story._id })
          .populate("supervisorId", "name email")
          .sort({ createdAt: -1 });

           const likesCount = await StoryLike.countDocuments({ storyId });       
           const userLiked = userId  ? !!(await StoryLike.findOne({ storyId, userId })): false;
           

         story.reviews = reviews;
         story.likesCount = likesCount;
         story.userLiked = userLiked;
            return story;
        } catch (error) {
            throw new Error("Error fetching story: " + error.message);
        }
    },


    async getStoriesByChild({childId, status = null}) {
        try {
            const query = { childId: mongoose.Types.ObjectId(childId) };        
            if (status) {
                query.status = status;
            }
            const stories = await Story.find(query)
                .populate("childId", "name")
                .populate("supervisorId", "name")
                .populate("templateId", "name defaultTheme")
                .lean();

                for (let story of stories) {
                    const reviews = await StoryReview.find({ storyId: story._id })
                   .populate("supervisorId", "name email")
                   .sort({ createdAt: -1 });
                     const likesCount = await StoryLike.countDocuments({ storyId });       
                      const userLiked = userId  ? !!(await StoryLike.findOne({ storyId, userId })): false;
           

                        story.reviews = reviews;
                        story.likesCount = likesCount;
                        story.userLiked = userLiked;
                
                
                }


            return stories;
        } catch (error) {
            throw new Error("Error fetching stories: " + error.message);
        }
    }

};

export default storyService;