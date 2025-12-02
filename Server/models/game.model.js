


import mongoose from "mongoose"

const gameSchema =new mongoose.Schema(
    {
        title:String,
        thumbnail:String,
        genre:String,
        platform:{
           type: String,
          default: ["Web", "Android", "iOS", "Desktop", "PC"],},
        description:String,
    },
    {
        timestamps:true,
    }
);
const Game = mongoose.model("Game",gameSchema);
 export default  Game;
