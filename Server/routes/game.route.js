import express from "express";
import { GameController } from "../controllers/game.controller.js";

export const gameRouter = express.Router();

gameRouter.post("/game/start", GameController.startGame);
gameRouter.post("/game/guess", GameController.makeGuess);
gameRouter.post("/game/", GameController.createGame);
gameRouter.get("/game/", GameController.listGames);
gameRouter.get("/game/:id", GameController.getGame);
gameRouter.put("/game/:id", GameController.updateGame);
gameRouter.delete("/game/:id", GameController.deleteGame);
gameRouter.get("/game/clock/question/:difficulty", GameController.getClockQuestion);
gameRouter.get("/game/math/question", GameController.getMathQuestion);

