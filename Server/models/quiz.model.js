
// import mongoose, { Schema } from "mongoose";

// const quizSchema = new Schema (
//     {

//     title : {
//        type:String,
//         required:true,
//       },
    
//       description:{
//         type:String,
//         required:true,
//       },
//       category:String,
//       level:{type:String,
//         enum:['easy','medium','hard']  },

//       duration:{
//         type:Number ,//minutes or seconds
//         required:true
//       },
//       isPublished:{
//         type:Boolean,
//         default:false
//       },
//       createdBy:{
//         type:mongoose.Schema.Types.ObjectId,
//         ref:'User'
//       },
//       attempts:{
//         type:Number,
//         default:3
//       },
//       videoId:{
//         type:mongoose.Schema.Types.ObjectId,
//         ref:'Video'
//       },
      
//         ageGroup:  {
//             type: String,
//             enum:["5-8" , "9-12"]
//         },

//       questions:[
//         {
//               question_type:{
//                 type:String,
//                 enum:['multiple-choice','true-false','pronunciation'],
//                 required:true,
//             },
//             question_text:{
//                 type:String,
//                 required:true,
//             },
//             question_image:{
//               type:String,
//               default:null
//             },
//             question_audio:{
//               type:String,
//               default:null,
//             },

//             options:[{
                
//         optionText:{
//             type:String,
//            default:null,},
//         optionImage:{
//           type:String,
//           default:null,
//         }   ,
//         optionAudio:{
//           type:String,
//           default:null,
//         },
//         isCorrect:{
//             type:Boolean,       
//             required:true              
//             },
//         }
//         ],
//             mark:{
//                type: Number,
//                default:0
//             },
//       voiceCheckRequired: { 
//         type: Boolean,
//          default: false } ,
//      correctAnswer: { 
//       type: String,
//        default: null }, // For pronunciation

//         },

//       ],
//    audioUrl: { type: String, default: null },

   
//   //  quizPublished:Boolean,
//    solved:{
//     type:Number,
//     default:0,
//    },
//    solvedBy:{
//     type:mongoose.Schema.Types.ObjectId,
//     ref:'User'
//    }
    


//     },


//     {
//         timestamps:true
//     }
// );



// const Quiz=mongoose.model("Quiz",quizSchema);
// export default Quiz;

import mongoose, { Schema } from "mongoose";

const optionSchema = new Schema({
  optionText: { type: String, default: null },
  optionImage: { type: String, default: null },
  optionAudio: { type: String, default: null },
  isCorrect: { type: Boolean, required: true }
});

const questionSchema = new Schema({
  question_type: {
    type: String,
    enum: ["multiple-choice", "true-false", "voice-answer"],
    required: true
  },
  question_text: { type: String, required: true },
  question_image: { type: String, default: null },
  question_audio: { type: String, default: null },
  options: [optionSchema],
  correctAnswer: { type: String, default: null },
  voiceCheckRequired: { type: Boolean, default: false },
  mark: { type: Number, default: 0 }
});

const quizSchema = new Schema(
  {
    title: { type: String, required: true },
    description: { type: String, required: true },

    category: String,

    level: {
      type: String,
      enum: ["easy", "medium", "hard"]
    },

    duration: { type: Number, required: true },
    ageGroup: {
      type: String,
      enum: ["5-8", "9-12"]
    },

    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      //required: true
    },

    videoId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Video"
    },

    isPublished: { type: Boolean, default: false },
    attempts: { type: Number, default: 3 },

    audioUrl: { type: String, default: null },

    questions: [questionSchema],

    solved: { type: Number, default: 0 },
    solvedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User"
    },

    submissions: [
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
    answers: [
      {
        questionIndex: Number,
        answer: String,
        mark: { type: Number, default: 0 }
      }
    ],
    attemptNumber: { type: Number, default: 1 },
    totalMark: { type: Number, default: 0 },
    createdAt: { type: Date, default: Date.now }
  }
]

  },
  { timestamps: true }
);

const Quiz = mongoose.model("Quiz", quizSchema);
export default Quiz;

