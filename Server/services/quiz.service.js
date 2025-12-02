

import { get } from "mongoose";
import Quiz from "../models/quiz.model.js";
import axios from "axios";
//import { recognizeAudio } from "../utils/stt.js"; // function to call STT service



export const quizService = {

// async createQuiz(data){
//     const existingQuiz=await Quiz.findOne({title:data.title,createdBy:data.createdBy});
//     if(existingQuiz)
//         throw new Error('Quize with this title already exists');
//     const newQuize=new Quiz(data);
//     return await newQuize.save();

// },


async createQuiz(data) {
  const existingQuiz = await Quiz.findOne({
    title: data.title,
    createdBy: data.createdBy
  });

  if (existingQuiz) {
    throw new Error("Quiz with this title already exists");
  }

  const newQuiz = new Quiz(data);
  return await newQuiz.save();
},

async getQuizById(id){
   return await Quiz.findById(id);},

 async getQuizByCreator(creatorId){
    return await Quiz.find({createdBy:creatorId});
 },  

  async getQuizByTitle(title){
    return await Quiz.find({title:title});
  },

  async getAllQuizzes(){
    return await Quiz.find();
  },

async updateQuiz(id, updatedData) {
  return await Quiz.findByIdAndUpdate(
    id,
    { $set: updatedData },
    { new: true, runValidators: true }
  );
},
async updateSingleQuestion(quizId, questionIndex, updatedData) {
  let updateFields = {};
  Object.keys(updatedData).forEach(key => {
    updateFields[`questions.${questionIndex}.${key}`] = updatedData[key];
  });

  return await Quiz.findByIdAndUpdate(
    quizId,
    { $set: updateFields },
    { new: true }
  );
},

    async deleteQuiz(id){  
    return await Quiz.findByIdAndDelete(id);   
    },  
    async deleteAllQuizzes(){
        await Quiz.deleteMany()
     },

 async checkPronunciation(quizId, questionIndex, audioData) {
  const quiz = await Quize.findById(quizId);
  if (!quiz) throw new Error("Quiz not found");

  const question = quiz.questions[questionIndex];
  if (!question) throw new Error("Question not found");

  let correctAnswer;
  if (question.question_type === 'pronunciation') {
    correctAnswer = question.correctAnswer;
    if (!correctAnswer) throw new Error("Pronunciation answer not defined");
  } else {
    const correctOption = question.options.find(o => o.isCorrect);
    if (!correctOption) throw new Error("No correct option defined");
    correctAnswer = correctOption.optionText;
  }

  const recognizedText = await recognizeAudio(audioData);
  const isCorrect = recognizedText.trim().toLowerCase() === correctAnswer.trim().toLowerCase();

  return { recognizedText, isCorrect };
},

async getQuizByVideoId(videoId){
  return await Quiz.find({videoId:videoId});
},

async submitQuiz(data) {
  const { quizId, userId, answers } = data;

  const quiz = await Quiz.findById(quizId);
  if (!quiz) throw new Error("Quiz not found");

  // Find previous submission for this user
  let submission = quiz.submissions.find(s => s.userId.toString() === userId);

  // Check attempt limit
  if (submission && submission.attemptNumber >= quiz.attempts) {
    throw new Error("You have reached the maximum number of attempts");
  }

  // Evaluate answers and calculate total mark
  let totalMark = 0;
  const evaluatedAnswers = answers.map(a => {
    const question = quiz.questions[a.questionIndex];
    if (!question) return { ...a, mark: 0 };

    let mark = 0;
    if (question.question_type === "multiple-choice" || question.question_type === "true-false") {
      if (question.correctAnswer === a.answer) mark = question.mark || 1;
    } else if (question.question_type === "pronunciation") {
      // Optional: implement STT check
      mark = 0;
    }

    totalMark += mark;
    return { ...a, mark };
  });

  if (submission) {
    // Overwrite previous attempt
    submission.answers = evaluatedAnswers;
    submission.totalMark = totalMark;
    submission.attemptNumber += 1;
    submission.updatedAt = new Date();
  } else {
    // First attempt
    quiz.submissions.push({
      userId,
      answers: evaluatedAnswers,
      totalMark,
      attemptNumber: 1
    });
  }

  await quiz.save();

  return { totalMark, attemptNumber: submission ? submission.attemptNumber : 1 };
}



  }