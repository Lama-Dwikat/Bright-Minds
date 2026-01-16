


import Game from "../models/game.model.js";
import OpenAI from "openai";
import axios from "axios";
import badgeService from "./badge.service.js";


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

    async getGameByName(name){
    const games = await Game.find({name:name});
    if (games.length===0) throw new Error("Game not found");

    return games;
  },

  async getAllGames(){
    const games = await Game.find();
    if (games.length===0) throw new Error("Game not found");
    return games;
  },

  async getGamesByAgeGroup(ageGroup){
  const games = await Game.find({
    ageGroup: { $in: [ageGroup, "5-12"] },
    isPublished: true
  });  
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
    const prompt = `Generate a simple clue to help guess the word "${word}" for children aged ${ageGroup}. The clue should be easy to understand and related to the word, make it children friendly , dont include the word and make it short`;
    const response = await openai.chat.completions.create({
      model: "gpt-3.5-turbo",
      messages: [{ role: "user", content: prompt }],
      max_tokens: 40

    })
      return response.choices[0].message.content.trim();
  },

  async generateThemeWords(theme, ageGroup) {
  const prompt = `
Generate a list of 15 simple, kid-friendly words related to the theme "${theme}" 
suitable for children aged ${ageGroup}. 

From these, pick 5 words that are **real compound words** that can be split into two smaller words. 
For each, return in this format:
  Word1 + Word2 = FullWord

Do not include any words that cannot be split into two meaningful words. 
Return the full result as a JSON object like this:

{
  "words": ["Word1", "Word2", ..., "Word35"],
  "compoundWords": [
    {"compound": "Rain + Bow = Rainbow"},
    {"compound": "Sun + Flower = Sunflower"}
  ]
}

  `;

  const response = await openai.chat.completions.create({
    model: "gpt-3.5-turbo",
    messages: [{ role: "user", content: prompt }],
    max_tokens: 400,
  });

  const resultText = response.choices[0].message.content.trim();

  try {
    return JSON.parse(resultText);
  } catch (e) {
    console.error("Failed to parse AI response:", resultText);
    return { words: [], compoundWords: [] };
  }
},






  async fetchClueImages (word) {
  const response = await axios.get("https://pixabay.com/api/", {
    params: {
      key: process.env.PIXABAY_KEY,
      q: word ,
      // + "+cartoon",
      image_type: "illustration",
      per_page: 4 // number of images
    }
  });
  return response.data.hits.map(hit => hit.webformatURL);
},

async saveScoreService (gameId, userId, score , isComplete = false) {
const game = await Game.findById(gameId);
  if (!game) throw new Error("Game not found");

  const existing = game.playedBy.find(p => p.userId.toString() === userId);
  if (existing) {
    existing.score = Math.max(existing.score, score);
    if (isComplete) existing.complete = true; // mark complete only if finished
  } else {
    game.playedBy.push({ userId, score, complete: isComplete });
  }

  await game.save();

  // ✅ Check for Champion Gamer badge after completion
  if (isComplete) {
    await badgeService.checkGameCompletionBadges(userId);
  }

  return game;
},


};