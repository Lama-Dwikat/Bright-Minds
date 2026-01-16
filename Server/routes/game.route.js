import express from "express";
import { gameController } from "../controllers/game.controller.js";

export const gameRouter = express.Router();



gameRouter.post('/game/createGame', gameController.createGame);
gameRouter.post('/game/generateGuessClue', gameController.generateGuessClue);
gameRouter.post('/game/saveUserScore', gameController.saveUserScore);
gameRouter.post('/game/generateThemeWords', gameController.generateThemeWords);
gameRouter.get('/game/getGamesByAgeGroup/:ageGroup', gameController.getGamesByAgeGroup);
gameRouter.get('/game/getGameBySupervisor/:id', gameController.getGameBySupervisor);
gameRouter.get('/game/getGameByName/:name', gameController.getGamesByName);
gameRouter.get('/game/getGameById/:id', gameController.getGameById);
gameRouter.get('/game/getAllGames', gameController.getAllGames);
gameRouter.get("/game/getClueImages", gameController.getClueImages);
gameRouter.get('/game/getInputByLevel/:id', gameController.getInputByLevel);
gameRouter.put('/game/publishGame/:id', gameController.publishGameById);
gameRouter.put('/game/updateGameById/:id', gameController.updateGameById);
gameRouter.delete('/game/deleteAllGames', gameController.deleteAllGames);
gameRouter.delete('/game/deletBySupervisor/:id', gameController.deleteBySupervisor);
gameRouter.delete('/game/deleteGameById/:id', gameController.deleteGameById);


