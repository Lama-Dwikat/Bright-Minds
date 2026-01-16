


import mongoose from "mongoose";
const gameSchema= new mongoose.Schema({
    name:{
        type:String,
        required:true,
    },
    input:[{
        text:[mongoose.Schema.Types.Mixed],
        image:[String],
        correctAnswer:[mongoose.Schema.Types.Mixed],
         clue: String, 
         lettersClue: [String],
        level:{
            type:Number,
            default:1,
        }
    }],
    ageGroup:{
        type:String,
        enum:["5-8","9-12","5-12"],
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
        score: { type: Number, default: 0 },
        complete: { type: Boolean, default: false },
        playedAt: { type: Date, default: Date.now }
    }

    ],
    isPublished:{
        type:Boolean,
        default:false,
    },
    description:String,
    type:{
        type:String,
        enum:["Spelling","Math","Clock", "Memory","Puzzle","Snake","Sorting","Matching","Guessing","Grid","MissLetters", "Ruler"],
        required:true,
    },
    
    theme:String,

    maxTrials: { 
      type: Number, 
       default: 3 }, 

     scorePerQuestion: { type: Number, default: 1},
      Image:[String],
     


      timePerQuestionMin: { type: Number, default: 15 },

},
{
timestamps:true,
}

);

const Game=mongoose.model("Game",gameSchema);
export default Game;
