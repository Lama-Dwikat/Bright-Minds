

import {quizController} from "../controllers/quiz.controller.js";
import express from "express";

export const quizRouter=express.Router();


quizRouter.post('/quiz/createQuiz',quizController.creatQuiz);
quizRouter.get('/quiz/getQuizById/:id',quizController.getQuizById);
quizRouter.get('/quiz/getQuizByCreator/:creatorId',quizController.getQuizByCreator);
quizRouter.get('/quiz/getAllQuizzes',quizController.getAllQuizzes);
quizRouter.put('/quiz/updateQuiz/:id',quizController.updateQuiz);
quizRouter.delete('/quiz/deleteQuiz/:id',quizController.deleteQuiz);
quizRouter.delete('/quiz/deleteAllQuizzes',quizController.deleteAllQuizzes);
quizRouter.put("/quiz/update-question/:quizId/:questionIndex",quizController.updateSingleQuestion);
quizRouter.post( "/quiz/check-pronunciation/:quizId/:questionIndex", quizController.checkPronunciation);
quizRouter.get('/quiz/getQuizByVideoId/:videoId',quizController.getQuizByVideoId);
quizRouter.post("/quiz/submitQuiz", quizController.submitQuiz);


