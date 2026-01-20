


import { gameService} from "../services/game.service.js";

export const gameController={

  async createGame(req,res){
     try{
      const game=await gameService.createGame(req.body);
      res.status(200).json(game);
    }catch(e){
      if (e.message === "Game not found") {
       return res.status(404).json({ message: e.message });
       }
      res.status(500).json({error:e.message});
    }
  },
  async getInputByLevel(req,res){
    try{
      const {level}=req.query;
      const input=await gameService.getInputByLevel(req.params.id,level);
      res.status(200).json(input);
    }catch(e){
      if (e.message === "Game not found") {
       return res.status(404).json({ message: e.message });
        }
      res.status(500).json({error:e.message});
    }
  },

  async getGameById(req,res){
     try{
      const game =await gameService.getGameById(req.params.id);
      res.status(200).json(game);
    }catch(e){
       if (e.message === "Game not found") {
       return res.status(404).json({ message: e.message });
        }
      res.status(500).json({error:e.message});
    }
  },

  async getGameBySupervisor(req,res){
      try{
      const games =await gameService.getGameBySupervisor(req.params.id);
      res.status(200).json(games);
    }catch(e){
      if (e.message === "Game not found") {
      return res.status(404).json({ message: e.message });
        }
      res.status(500).json({error:e.message});
    }
  },

 async getAllGames(req,res){
  try{
      const games =await gameService.getAllGames();
      res.status(200).json(games);
    }catch(e){
      if (e.message === "Game not found") {
       return res.status(404).json({ message: e.message });
       }
      res.status(500).json({error:e.message});
    }
  },

  async getGamesByAgeGroup(req,res){
   try{
      const games =await gameService.getGamesByAgeGroup(req.params.ageGroup);
      res.status(200).json(games);
    }catch(e){
      if (e.message === "Game not found") {
        return res.status(404).json({ message: e.message });
        }
      res.status(500).json({error:e.message});
    }
  },

    async getGamesByName(req,res){
   try{
      const games =await gameService.getGameByName(req.params.name);
      res.status(200).json(games);
    }catch(e){
      if (e.message === "Game not found") {
        return res.status(404).json({ message: e.message });
        }
      res.status(500).json({error:e.message});
    }
  },

  async  updateGameById(req,res){
  try{
    const updatedGame=await gameService.updateGameById(req.params.id,req.body);
    res.status(200).json(updatedGame);
    }catch(e){
      if (e.message === "Game not found") {
       return res.status(404).json({ message: e.message });
         }
      res.status(500).json({error:e.message});
    }    
  },

  async  publishGameById(req,res ){
  try{
      const {isPublished}=req.body;
      const game = await gameService.publishGameById(req.params.id,isPublished);
      res.status(200).json(game);
    }catch(e){
      if (e.message === "Game not found") {
        return res.status(404).json({ message: e.message });
          }
      res.status(500).json({error:e.message});
    }    
  },

  async deleteGameById(req,res){
  try{
    const game= await gameService.deleteGameById(req.params.id);
    res.status(200).json(game); 
    }catch(e){
      if (e.message === "Game not found") {
       return res.status(404).json({ message: e.message });
        }
      res.status(500).json({error:e.message});
    } 
   },

  async deleteBySupervisor(req,res){
  try{ 
    const games=await gameService.deleteBySupervisor(req.params.id);
    res.status(200).json(games);
    }catch(e){
      res.status(500).json({error:e.message});
    }  
  },
   async deleteAllGames(req,res){
  try{
    const games=await gameService.deleteAllGames();
    res.status(200).json(games);
    }catch(e){
      res.status(500).json({error:e.message});
    }
  },

   async generateGuessClue(req, res) {
    try {
      const { word, ageGroup } = req.body;
      const clue = await gameService.generateGuessClue(word, ageGroup);
      res.status(200).json({ clue });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  },

     async generateThemeWords(req, res) {
    try {
      const { theme, ageGroup } = req.body;
      const words = await gameService.generateThemeWords(theme, ageGroup);
      res.status(200).json(words);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  },




  async getClueImages (req, res) {
  try {
    const { word } = req.query; // word to get images for
    const images = await gameService.fetchClueImages(word);
    res.status(200).json({ images });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
},



async saveUserScore (req, res) {
 try {
    const { gameId, userId, score, complete } = req.body;

    if (!gameId || !userId || score == null) {
      return res.status(400).json({ message: "Missing required data" });
    }

    const game = await gameService.saveScoreService(gameId, userId, score, complete);

    return res.json({ message: "Score saved successfully", game });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }

},


async getTopPlayedGames(req, res) {
  try {
    const topGames = await gameService.getTopPlayedGames(4); // top 4
    res.status(200).json(topGames);
  } catch (err) {
    console.error("Error fetching top played games:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
},

 async getPlayedGamesByUser(req, res) {
  try {
    const { id } = req.params;

    if (!id) {
      return res.status(400).json({ message: "User ID is required" });
    }

    const games = await gameService.getPlayedGamesByUserId(id);

    return res.status(200).json(games);
  } catch (err) {
    console.error("Error fetching played games:", err);
    res.status(500).json({ message: err.message });
  }
},




};