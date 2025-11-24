

import {quizeController} from "../controllers/quize.controller.js";
import express from "express";

export const quizeRouter=express.Router();


quizeRouter.post('/quize/createQuize',quizeController.creatQuize);
quizeRouter.get('/quize/getQuizeById/:id',quizeController.getQuizeById);
quizeRouter.get('/quize/getQuizeByCreator/:creatorId',quizeController.getQuizeByCreator);
quizeRouter.get('/quize/getAllQuizes',quizeController.getAllQuizes);
quizeRouter.put('/quize/updateQuize/:id',quizeController.updateQuize);
quizeRouter.delete('/quize/deleteQuize/:id',quizeController.deleteQuize);
quizeRouter.delete('/quize/deleteAllQuizes',quizeController.deleteAllQuizes);
quizeRouter.put("/update-question/:quizId/:questionIndex",quizeController.updateSingleQuestion);

