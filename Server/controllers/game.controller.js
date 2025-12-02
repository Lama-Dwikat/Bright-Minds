import GameService from "../services/game.service.js";

class GameController {
  // GET /games
  static async fetchGames(req, res) {
    try {
      const games = await GameService.getAllGames();
      res.json(games);
    } catch (err) {
      res.status(500).json({ error: "Failed to fetch games" });
    }
  }

  // GET /games/:id
  static async getGame(req, res) {
    try {
      const game = await GameService.getGameById(req.params.id);
      if (!game) return res.status(404).json({ error: "Game not found" });
      res.json(game);
    } catch (err) {
      res.status(500).json({ error: "Failed to fetch game" });
    }
  }

  // POST /games
  static async createGame(req, res) {
    try {
      const newGame = await GameService.createGame(req.body);
      res.status(201).json(newGame);
    } catch (err) {
      res.status(500).json({ error: "Failed to create game" });
    }
  }

  // PUT /games/:id
  static async updateGame(req, res) {
    try {
      const updatedGame = await GameService.updateGame(req.params.id, req.body);
      if (!updatedGame) return res.status(404).json({ error: "Game not found" });
      res.json(updatedGame);
    } catch (err) {
      res.status(500).json({ error: "Failed to update game" });
    }
  }

  // DELETE /games/:id
  static async deleteGame(req, res) {
    try {
      const deletedGame = await GameService.deleteGame(req.params.id);
      if (!deletedGame) return res.status(404).json({ error: "Game not found" });
      res.json({ message: "Game deleted successfully" });
    } catch (err) {
      res.status(500).json({ error: "Failed to delete game" });
    }
  }
}

export default GameController;
