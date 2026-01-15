import express from "express";
import { gameController } from "../controllers/game.controller.js";

export const gameRouter = express.Router();

// gameRouter.post("/game/start", GameController.startGame);
// gameRouter.post("/game/guess", GameController.makeGuess);
// gameRouter.post("/game/", GameController.createGame);
// gameRouter.get("/game/", GameController.listGames);
// gameRouter.get("/game/:id", GameController.getGame);
// gameRouter.put("/game/:id", GameController.updateGame);
// gameRouter.delete("/game/:id", GameController.deleteGame);
// gameRouter.get("/game/clock/question/:difficulty", GameController.getClockQuestion);
// gameRouter.get("/game/math/question", GameController.getMathQuestion);

gameRouter.post('/game/createGame', gameController.createGame);
gameRouter.post('/game/generateGuessClue', gameController.generateGuessClue);
gameRouter.get('/game/getGamesByAgeGroup/:ageGroup', gameController.getGamesByAgeGroup);
gameRouter.get('/game/getGameBySupervisor/:id', gameController.getGameBySupervisor);
gameRouter.get('/game/getGameById/:id', gameController.getGameById);
gameRouter.get('/game/getAllGames', gameController.getAllGames);
gameRouter.get('/game/getInputByLevel/:id', gameController.getInputByLevel);
gameRouter.put('/game/publishGame/:id', gameController.publishGameById);
gameRouter.put('/game/updateGameById/:id', gameController.updateGameById);
gameRouter.delete('/game/deleteAllGames', gameController.deleteAllGames);
gameRouter.delete('/game/deletBySupervisor/:id', gameController.deleteBySupervisor);
gameRouter.delete('/game/deleteGameById/:id', gameController.deleteGameById);
gameRouter.get("/game/getClueImages", gameController.getClueImages);


