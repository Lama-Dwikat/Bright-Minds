import Game from "../models/game.model.js";

class GameService {
  // Get all games
  static async getAllGames() {
    return await Game.find().sort({ createdAt: -1 });
  }

  // Get game by ID
  static async getGameById(id) {
    return await Game.findById(id);
  }

  // Create a new game
  static async createGame(data) {
    const game = new Game(data);
    return await game.save();
  }

  // Update a game
  static async updateGame(id, data) {
    return await Game.findByIdAndUpdate(id, data, { new: true });
  }

  // Delete a game
  static async deleteGame(id) {
    return await Game.findByIdAndDelete(id);
  }
}

export default GameService;
