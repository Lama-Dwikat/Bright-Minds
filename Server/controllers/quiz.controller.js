
import { get } from "mongoose";
import { quizService }  from "../services/quiz.service.js";

export const quizController={

    // async creatQuiz(req,res){
    //     try{
    //         const quiz=await quizService.createQuiz(req.body);
    //         if(!quiz){
    //             return res.status(400).json({message:'Quiz creation failed'});
    //         }
    //         res.status(201).json({message:"Quiz created successfully",quiz});
    //     }
    //     catch(error){
    //         res.status(500).json({message:error.message})
    //     }
    // },
async creatQuiz(req, res) {
  try {
    const quiz = await quizService.createQuiz(req.body);

    if (!quiz) {
      return res.status(400).json({ message: "Quiz creation failed" });
    }

    res.status(201).json({
      message: "Quiz created successfully",
      quiz
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
},


    async getQuizById(req,res){
        try{
        const quiz=await quizService.getQuizById(req.params.id);
        if (!quiz){
                return res.status(404).json({message:error.message})
            }
        return res.status(200).json(quize);

        }catch(error){
            res.status(500).json({message:error.message})
    }

    },
    async getQuizByCreator(req,res){
        try{
        const quiz=await quizService.getQuizByCreator(req.params.creatorId);
       if (!quiz){
                return res.status(404).json({message:error.message})
            }
                return res.status(200).json(quize);

        }catch(error){
            
            res.status(500).json({message:error.message})
    }

    },

    async getAllQuizzes(req,res){
        try{
        const quizzes=await quizService.getAllQuizzes()
       res.status(200).json(quizzes);
        }catch(error){
            res.status(500).json({message:error.message})       

    } 
},

    async updateQuiz(req,res){
        try{
        const updatedQuiz=await quizService.updateQuiz(req.params.id,req.body);
        if(!updatedQuiz){
            return res.status(404).json({message:'Quiz not found'});
        }
        res.status(200).json({message:'Quize updated successfully',updatedQuize});
        }catch(error){
            res.status(500).json({message:error.message})       
    }


    },

   async  updateSingleQuestion (req, res) {
  try {
    const { quizId, questionIndex } = req.params;
    const updatedData = req.body;

    const updatedQuiz = await quizService.updateSingleQuestion(
      quizId,
      questionIndex,
      updatedData
    );

    if (!updatedQuiz) {
      return res.status(404).json({ message: "Quiz not found" });
    }

    return res.status(200).json({
      message: "Question updated successfully",
      quiz: updatedQuiz,
    });
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }},

  
    async deleteQuiz(req,res){         
        try{
        const deletedQuiz=await quizService.deleteQuiz(req.params.id);
        if(!deletedQuiz){
            return res.status(404).json({message:'Quiz not found'});
        }
        res.status(200).json({message:'Quiz deleted successfully'});
        }catch(error){
            res.status(500).json({message:error.message})       
    }   

    },      

    async deleteAllQuizzes(req,res){ 
        try{        
        await quizService.deleteAllQuizzes();
        res.status(200).json({message:'All quizzes deleted successfully'});
        }
        catch(error){
            res.status(500).json({message:error.message})       
    }

    }   ,


    async checkPronunciation(req, res) {
  try {
    const { quizId, questionIndex } = req.params;
    const { audio } = req.body;

    if (!audio) return res.status(400).json({ message: "Audio data is required" });

    const result = await quizService.checkPronunciation(quizId, questionIndex, audio);

    res.status(200).json({
      message: "Pronunciation checked",
      recognizedText: result.recognizedText,
      correct: result.isCorrect,
      mark: result.isCorrect ? 1 : 0 // or whatever mark you assign
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
},
 async getQuizByVideoId(req,res){
  try{
  const quiz = await quizService.getQuizByVideoId(req.params.videoId);
  if(!quiz)
    return res.status(400).json({message:"video not have a quiz"});
  return res.status(200).json(quiz);}
  catch(err){
        res.status(500).json({ message: error.message });

  }
 },



async submitQuiz(req, res) {
  try {
    const result = await quizService.submitQuiz(req.body);
    res.status(200).json({
      message: "Quiz submitted successfully",
      totalMark: result.totalMark,
      attemptNumber: result.attemptNumber
    });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
},
// quiz.controller.js
async getQuizzesSolvedByUser(req, res) {
  try {
    const { userId } = req.params;
    const quizzes = await quizService.getQuizzesSolvedByUser(userId);

    if (!quizzes || quizzes.length === 0) {
      return res.status(404).json({ message: "No quizzes found for this user" });
    }

    res.status(200).json({ quizzes });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
}







}





