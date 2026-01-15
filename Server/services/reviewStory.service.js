import StoryReview from "../models/reviewStory.model.js";
import Story from "../models/story.model.js";
import mongoose from "mongoose";
import badgeService from "../services/badge.service.js";


export const reviewStoryService = {



 /*   async createReview ({ storyId, supervisorId, rating = null, comment = ""}){
       try{
           const story = await Story.findById(storyId);
           if(!story){
            throw new Error ("Story not found ");
           }

           if (!story.supervisorId) {
              throw new Error("No supervisor assigned to this story");
            }
            if (story.supervisorId.toString() !== supervisorId.toString()) {
               throw new Error("Supervisor not assigned to this story");
              }
             const existingReview = await StoryReview.findOne({ storyId, supervisorId });
      if (existingReview)
        throw new Error("You already submitted a review for this story");



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
      else if (rating >= 2) story.status = "needs_edit";
      else story.status = "rejected";
    } else if (comment && comment.trim() !== "") {
       story.status = "needs_edit";
     } else {
        story.status = "pending";
      }


      story.supervisorCommentsSeen = false; 
      story.updatedAt = new Date();
      await story.save();

      return review;

    }
    catch (error) {
      throw new Error("Error creating review: " + error.message);
    }
    },

*/
async createReview ({ storyId, supervisorId, rating = null, comment = ""}) {
  try {
    const story = await Story.findById(storyId);

    if (!story) {
      throw new Error("Story not found");
    }

    if (!story.supervisorId) {
      throw new Error("No supervisor assigned to this story");
    }

    if (story.supervisorId.toString() !== supervisorId.toString()) {
      throw new Error("Supervisor not assigned to this story");
    }

    const existingReview = await StoryReview.findOne({ storyId, supervisorId });
    if (existingReview)
      throw new Error("You already submitted a review for this story");

    const review = new StoryReview({
      storyId,
      supervisorId,
      rating,
      comment,
      status: "completed"
    });

    await review.save();

    // update story status
    if (rating !== null) {
      if (rating >= 4) story.status = "approved";
      else if (rating >= 2) story.status = "needs_edit";
      else story.status = "rejected";
    } else if (comment && comment.trim() !== "") {
      story.status = "needs_edit";
    } else {
      story.status = "pending";
    }

    story.supervisorCommentsSeen = false;
    story.updatedAt = new Date();

    await story.save();

    /** ⭐ NEW — Badge Award AFTER review */
    try {
      await badgeService.checkBadgesForStory(story.childId);
    } catch (err) {
      console.warn("⚠️ Badge check failed:", err.message);
    }

    return review;

  } catch (error) {
    throw new Error("Error creating review: " + error.message);
  }
},


  
  /* async getReviewsByStory( storyId ) {
    try {
      const query = await StoryReview.find({ storyId })
        .populate("supervisorId", "name email")
        .sort({ createdAt: -1 });
         //const reviews = latestOnly ? await query.limit(1) : await query;
         const reviews = await reviewStoryService.getReviewsByStory(storyId, latestOnly);

      return reviews;
    } catch (error) {
      throw new Error("Failed to fetch story reviews: " + error.message);
    }
  },*/

  async getReviewsByStory(storyId, latestOnly = false) {
  try {
    let query = StoryReview.find({ storyId })
      .populate("supervisorId", "name email")
      .sort({ createdAt: -1 });

    if (latestOnly) {
      query = query.limit(1);
    }

    const reviews = await query;
    return reviews;

  } catch (error) {
    throw new Error("Failed to fetch story reviews: " + error.message);
  }
},



   async getReviewsBySupervisor(supervisorId ) {
    try {
      const reviews = await StoryReview.find({ supervisorId })
        .populate("storyId", "title childId")
        .populate("supervisorId", "name email")
        .sort({ createdAt: -1 });
      return reviews;
    } catch (error) {
      throw new Error("Failed to fetch reviews by supervisor: " + error.message);
    }
  },

  async deleteReview({ reviewId, supervisorId }) {
    try {
    const review = await StoryReview.findById(reviewId);
    if (!review) throw new Error("Review not found");

    if (review.supervisorId.toString() !== supervisorId.toString()) {
      throw new Error("Unauthorized: You cannot delete this review");
    }

    await review.deleteOne();
    return { message: "Review deleted successfully" };
  }
  catch (error) {
      throw new Error("Error deleting review: " + error.message);
    }
  }




/*async updateReview({ reviewId, supervisorId, rating, comment }) {
    try {
      const review = await StoryReview.findById(reviewId);
      if (!review) throw new Error("Review not found");
      if (review.supervisorId.toString() !== supervisorId.toString()) {
        throw new Error("Unauthorized: You are not the owner of this review");
      }

      if (rating !== undefined) review.rating = rating;
      if (comment !== undefined) review.comment = comment;
      review.status = "completed";
      await review.save();


      const story = await Story.findById(review.storyId);
      if (!story) throw new Error("Story not found");

       if (rating !== undefined && rating !== null) {
      if (rating >= 4) story.status = "approved";
      else if (rating >= 2) story.status = "needs_edit";
      else story.status = "rejected";
    } else if (typeof comment === "string" && comment.trim() !== "") {
      story.status = "needs_edit";
    } else {
      story.status = "pending";
    }

      story.supervisorCommentsSeen = false;
      await story.save();

      return review;

    } catch (error) {
      throw new Error("Error updating review: " + error.message);
    }
  },
  */


};

export default reviewStoryService;
