import express from "express";
import GameController from "../controllers/game.controller.js";

export const gameRouter = express.Router();

// CRUD routes
gameRouter.get("/games/fetchGames", GameController.fetchGames);        // List all games
gameRouter.get("/games/getGames/:id", GameController.getGame);      // Get single game
gameRouter.post("/games/createGames", GameController.createGame);      // Create new game
gameRouter.put("/games/updateGames/:id", GameController.updateGame);   // Update game
gameRouter.delete("/games/deleteGames/:id", GameController.deleteGame);// Delete game

