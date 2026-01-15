// import mongoose from "mongoose";

// const gameSchema = new mongoose.Schema({
//     numberToGuess: { type: Number, 
//         required: true },
// //      type: { type: String, required: true }, // 'spelling'
// //   title: String,
// //   ageGroup: String,
// //   word: String,
// //   clueImage: String,
// //   letters: [String],
// //   audio: { wordAudio: String, lettersAudioBase: String },
// //   settings: Object,
// //   status: { type: String, default: "draft" },
// //   createdBy: String,
// //   createdAt: { type: Date, default: () => new Date() },
// //   clockGame: {
// //   enabled: { type: Boolean, default: false },
// //   difficulty: { type: String, default: "easy" }, // easy | medium | hard
// // },

// // mathGame: {
// //   enabled: { type: Boolean, default: false },
// //   operation: { type: String, default: "add" }, // add | subtract | multiply
// //   min: { type: Number, default: 1 },
// //   max: { type: Number, default: 10 }
// // },

// // score: { type: Number, default: 0 },


// },

// {
//     timestamps:true,
// }
// );







// const Game = mongoose.model("Game", gameSchema);
// export default Game;


import mongoose from "mongoose";
const gameSchema= new mongoose.Schema({
    name:{
        type:String,
        required:true,
    },
    input:[{
        text:mongoose.Schema.Types.Mixed,
        image:String,
        correctAnswer:mongoose.Schema.Types.Mixed,
         clue: String, 
        level:{
            type:Number,
            default:1,
        }
    }],
    ageGroup:{
        type:String,
        enum:["3-5","6-8","9-12"],
        required:true,
    },
    createdBy:{
        type:mongoose.Schema.Types.ObjectId,
        ref:"User"
    },
    playedBy:[
        {
       userId: {
            type:mongoose.Schema.Types.ObjectId,
            ref:"User"
        },
        score: { type: Number, default: 0 }
    }
    ],
    isPublished:{
        type:Boolean,
        default:false,
    },
    description:String,
    type:{
        type:String,
        enum:["Spelling","Math","Clock", "Memory","Puzzle","Snake","Sorting","Matching","Guessing"],
        required:true,
    }

},
{
timestamps:true,
}

);

const Game=mongoose.model("Game",gameSchema);
export default Game;
