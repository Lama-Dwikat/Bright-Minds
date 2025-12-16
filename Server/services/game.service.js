import Game from "../models/game.model.js";

export const GameService = {
  async createGame() {
    const number = Math.floor(Math.random() * 100) + 1;
    const game = new Game({ numberToGuess: number });
    await game.save();
    return game;
  },

  async checkGuess(guess) {
    const game = await Game.findOne().sort({ _id: -1 });
    if (!game) throw new Error("No game found");

    if (guess < game.numberToGuess) return "Too low";
    if (guess > game.numberToGuess) return "Too high";
    return "Correct!";
  },
    async create(data) {
    const g = new Game(data);
    return g.save();
  },
  async update(id, data) {
    return Game.findByIdAndUpdate(id, data, { new: true });
  },
  async get(id) {
    return Game.findById(id);
  },
  async list(filter = {}) {
    // Only return published by default
    if (!filter.status) filter.status = "published";
    return Game.find(filter).sort({ createdAt: -1 });
  },
  async remove(id) {
    return Game.findByIdAndDelete(id);
  },
  async generateClockQuestion(difficulty = "easy") {
  let hour, minute;

  if (difficulty === "easy") {
    hour = Math.floor(Math.random() * 12) + 1;
    minute = 0;
  } else if (difficulty === "medium") {
    hour = Math.floor(Math.random() * 12) + 1;
    minute = Math.floor(Math.random() * 12) * 5;
  } else {
    hour = Math.floor(Math.random() * 12) + 1;
    minute = Math.floor(Math.random() * 60);
  }

  return { hour, minute };
},

async generateMathQuestion(operation, min, max) {
  const a = Math.floor(Math.random() * (max - min + 1)) + min;
  const b = Math.floor(Math.random() * (max - min + 1)) + min;

  let answer;
  if (operation === "add") answer = a + b;
  if (operation === "subtract") answer = a - b;
  if (operation === "multiply") answer = a * b;

  return { a, b, operation, answer };
}


};
