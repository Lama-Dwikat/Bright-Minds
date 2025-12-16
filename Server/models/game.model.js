import mongoose from "mongoose";

const gameSchema = new mongoose.Schema({
    numberToGuess: { type: Number, 
        required: true },
//      type: { type: String, required: true }, // 'spelling'
//   title: String,
//   ageGroup: String,
//   word: String,
//   clueImage: String,
//   letters: [String],
//   audio: { wordAudio: String, lettersAudioBase: String },
//   settings: Object,
//   status: { type: String, default: "draft" },
//   createdBy: String,
//   createdAt: { type: Date, default: () => new Date() },
//   clockGame: {
//   enabled: { type: Boolean, default: false },
//   difficulty: { type: String, default: "easy" }, // easy | medium | hard
// },

// mathGame: {
//   enabled: { type: Boolean, default: false },
//   operation: { type: String, default: "add" }, // add | subtract | multiply
//   min: { type: Number, default: 1 },
//   max: { type: Number, default: 10 }
// },

// score: { type: Number, default: 0 },


},

{
    timestamps:true,
}
);







const Game = mongoose.model("Game", gameSchema);
export default Game;
