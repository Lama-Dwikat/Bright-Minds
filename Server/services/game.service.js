// import Game from "../models/game.model.js";

// export const GameService = {
//   async createGame() {
//     const number = Math.floor(Math.random() * 100) + 1;
//     const game = new Game({ numberToGuess: number });
//     await game.save();
//     return game;
//   },

//   async checkGuess(guess) {
//     const game = await Game.findOne().sort({ _id: -1 });
//     if (!game) throw new Error("No game found");

//     if (guess < game.numberToGuess) return "Too low";
//     if (guess > game.numberToGuess) return "Too high";
//     return "Correct!";
//   },
//     async create(data) {
//     const g = new Game(data);
//     return g.save();
//   },
//   async update(id, data) {
//     return Game.findByIdAndUpdate(id, data, { new: true });
//   },
//   async get(id) {
//     return Game.findById(id);
//   },
//   async list(filter = {}) {
//     // Only return published by default
//     if (!filter.status) filter.status = "published";
//     return Game.find(filter).sort({ createdAt: -1 });
//   },
//   async remove(id) {
//     return Game.findByIdAndDelete(id);
//   },
//   async generateClockQuestion(difficulty = "easy") {
//   let hour, minute;

//   if (difficulty === "easy") {
//     hour = Math.floor(Math.random() * 12) + 1;
//     minute = 0;
//   } else if (difficulty === "medium") {
//     hour = Math.floor(Math.random() * 12) + 1;
//     minute = Math.floor(Math.random() * 12) * 5;
//   } else {
//     hour = Math.floor(Math.random() * 12) + 1;
//     minute = Math.floor(Math.random() * 60);
//   }

//   return { hour, minute };
// },

// async generateMathQuestion(operation, min, max) {
//   const a = Math.floor(Math.random() * (max - min + 1)) + min;
//   const b = Math.floor(Math.random() * (max - min + 1)) + min;

//   let answer;
//   if (operation === "add") answer = a + b;
//   if (operation === "subtract") answer = a - b;
//   if (operation === "multiply") answer = a * b;

//   return { a, b, operation, answer };
// }


// };


import Game from "../models/game.model.js";
import OpenAI from "openai";
import axios from "axios";


const openai=new OpenAI({
  apiKey:process.env.GAME_API_KEY,
})

export const gameService = {

  async createGame(data){
    const g = new Game(data);
    return g.save();
  },

  async getInputByLevel(gameId, level){
  const game = await Game.findById(gameId);
  if (!game) throw new Error("Game not found");
  const input = game.input.filter(i=>i.level==level);
  return input;
  },

  async getGameById(gameId){
    const game = await Game.findById(gameId);
    if (!game) throw new Error("Game not found");
    return game;
  },

  async getGameBySupervisor(supervisorId){
    const games = await Game.find({createdBy:supervisorId});
    if (games.length===0) throw new Error("Game not found");

    return games;
  },

  async getAllGames(){
    const games = await Game.find();
    if (games.length===0) throw new Error("Game not found");
    return games;
  },

  async getGamesByAgeGroup(ageGroup){
    const games = await Game.find({ageGroup:ageGroup, isPublished:true});
    if (games.length===0) throw new Error("Game not found");
    return games;
  },

  async  updateGameById(gameId , updatedData){
    const game=await Game.findByIdAndUpdate(gameId,updatedData ,{new:true});
    if (!game) throw new Error("Game not found");
    return game;
    
  },
  async  publishGameById(gameId , published ){
    const game= await Game.findByIdAndUpdate(gameId,{isPublished:published},{new:true});
    if (!game) throw new Error("Game not found");
    return game;
  },
  
  async deleteGameById(gameId){
    const game= await Game.findByIdAndDelete(gameId);
    if (!game) throw new Error("Game not found");   
    return game;
  },
  async deleteBySupervisor(supervisorId){
    const games= await Game.deleteMany({createdBy:supervisorId});
    if (!games) throw new Error("Game not found");
    return games;
  },

  async deleteAllGames(){
    const game= await Game.deleteMany({});
      if (!game) throw new Error("Game not found");
      return game;
  },

  async generateGuessClue(word, ageGroup) {
    const prompt = `Generate a simple clue to help guess the word "${word}" for children aged ${ageGroup}. The clue should be easy to understand and related to the word, make it children friendly , dont include the word`;
    const response = await openai.chat.completions.create({
      model: "gpt-3.5-turbo",
      messages: [{ role: "user", content: prompt }],
      max_tokens: 40

    })
      return response.choices[0].message.content.trim();
  },

  async fetchClueImages (word) {
  const response = await axios.get("https://pixabay.com/api/", {
    params: {
      key: process.env.PIXABAY_KEY,
      q: word  + "+cartoon",
      image_type: "illustration",
      per_page: 5 // number of images
    }
  });
  return response.data.hits.map(hit => hit.webformatURL);
},


};