import { GameService } from "../services/game.service.js";

export const GameController = {
  async startGame(req, res) {
    try {
      const game = await GameService.createGame();
      res.json({ message: "New game started!", gameId: game._id });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  },

  async makeGuess(req, res) {
    try {
      const { guess } = req.body;
      if (!guess && guess !== 0) return res.status(400).json({ error: "Guess is required" });

      const result = await GameService.checkGuess(Number(guess));
      res.json({ result });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  },



    async createGame(req, res) {
    try {
      const game = await GameService.create(req.body);
      res.json(game);
    } catch (e) { res.status(500).json({ error: e.message }); }
  },

  async listGames(req, res) {
    try {
      const { ageGroup } = req.query;
      const filter = { status: "published" };
      if (ageGroup) filter.ageGroup = ageGroup;
      const games = await GameService.list(filter);
      res.json(games);
    } catch (e) { res.status(500).json({ error: e.message }); }
  },

  async getGame(req, res) {
    try {
      const game = await GameService.get(req.params.id);
      if (!game) return res.status(404).json({ error: "Not found" });
      res.json(game);
    } catch (e) { res.status(500).json({ error: e.message }); }
  },

  async updateGame(req, res) {
    try {
      const updated = await GameService.update(req.params.id, req.body);
      res.json(updated);
    } catch (e) { res.status(500).json({ error: e.message }); }
  },

  async deleteGame(req, res) {
    try {
      await GameService.remove(req.params.id);
      res.json({ success: true });
    } catch (e) { res.status(500).json({ error: e.message }); }
  },
  async getClockQuestion(req, res) {
  try {
    const difficulty = req.params.difficulty || "easy";
    const question = await GameService.generateClockQuestion(difficulty);
    res.json(question);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
},
async getMathQuestion(req, res) {
  try {
    const { operation = "add", min = 1, max = 10 } = req.query;
    const question = await GameService.generateMathQuestion(operation, min, max);
    res.json(question);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
}


};
