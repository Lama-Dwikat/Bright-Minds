import StoryReview from "../models/reviewStory.model";
import Story from "../models/story.model";
import mongoose from "mongoose";

export const reviewStoryService = {



    async createReview ({ storyId, SupervisorId, rating = null, commet = ""}){
       try{
           const story = await Story.findById(stotyId);
           if(!story){
            throw new Error ("Story not found ");
           }

            if (story.supervisorId.toString() !== supervisorId.toString()) {
             throw new Error("Supervisor not assigned to this story");
             }


      const review = new StoryReview({
        storyId,
        supervisorId,
        rating,
        comment,
        status: "completed"
      });

      await review.save();
        
      
       if (rating !== null) {
        if (rating >= 4) story.status = "approved";
        else if (rating <= 2) story.status = "needs_edit";
        else story.status = "pending"; 
      } else if (comment && comment.trim() !== "") {
        story.status = "needs_edit"; 
      }

      story.supervisorCommentsSeen = false; 
      await story.save();

      return review;

    }
    catch (error) {
      throw new Error("Error creating review: " + error.message);
    }
    },


async updateReview({ reviewId, supervisorId, rating, comment }) {
    try {
      const review = await StoryReview.findById(reviewId);
      if (!review) throw new Error("Review not found");
      if (review.supervisorId.toString() !== supervisorId.toString()) {
        throw new Error("Unauthorized: You are not the owner of this review");
      }

      if (rating !== undefined) review.rating = rating;
      if (comment !== undefined) review.comment = comment;

      await review.save();


      const story = await Story.findById(review.storyId);
      if (!story) throw new Error("Story not found");

      if (rating !== undefined) {
        if (rating >= 4) story.status = "approved";
        else if (rating <= 2) story.status = "needs_edit";
        else story.status = "pending";
      } else if (comment && comment.trim() !== "") {
        story.status = "needs_edit";
      }

      story.supervisorCommentsSeen = false;
      await story.save();

      return review;

    } catch (error) {
      throw new Error("Error updating review: " + error.message);
    }
  },
  
  
   async getReviewsByStory({ storyId }) {
    try {
      const reviews = await StoryReview.find({ storyId })
        .populate("supervisorId", "name email")
        .sort({ createdAt: -1 });
      return reviews;
    } catch (error) {
      throw new Error("Error fetching reviews: " + error.message);
    }
  },


   async getReviewsBySupervisor({ supervisorId }) {
    try {
      const reviews = await StoryReview.find({ supervisorId })
        .populate("storyId", "title childId")
        .populate("supervisorId", "name email")
        .sort({ createdAt: -1 });
      return reviews;
    } catch (error) {
      throw new Error("Error fetching supervisor reviews: " + error.message);
    }
  }







};

export default reviewStoryService;
