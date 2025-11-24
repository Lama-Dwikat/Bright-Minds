
import mongoose, { Schema } from "mongoose";

const quizeSchema = new Schema (
    {

    title : {
       type:String,
        required:true,
      },
    
      description:{
        type:String,
        required:true,
      },
      category:String,
      level:{type:String,
        enum:['easy','medium','hard']  },

      duration:{
        type:Number ,//minutes or seconds
        required:true
      },
      isPublished:{
        type:Boolean,
        default:false
      },
      createdBy:{
        type:mongoose.Schema.Types.ObjectId,
        ref:'User'
      },
      attempts:{
        type:Number,
        default:3
      },
      questions:[
        {
              question_type:{
                type:String,
                enum:['multiple-choice','true-false'],
                required:true,
            },
            question_text:{
                type:String,
                required:true,
            },
            question_image:{
              type:String,
              default:null
            },
            question_audio:{
              type:String,
              default:null,
            },

            options:[{
                
        optionText:{
            type:String,
            required:true},
        optionImage:{
          type:String,
          default:null,
        }   ,
        optionText:{
          type:String,
          default:null,
        },

        isCorrect:{
            type:Boolean,       
            required:true              
            },
        }
        ],
            mark:{
               type: Number,
               default:0
            }
        }
      ],
   audioUrl: { type: String, default: null },

   
   quizPublished:Boolean,
   views:{
    type:Number,
    default:0,
   }
    


    },


    {
        timestamps:true
    }
);


// quizeSchema.pre('save',function(next){
//     this.totalMark=this.questions.reduce((sum,q)=>sum+(q.mark||0),0);
//     next();
// })
const Quize=mongoose.model("Quize",quizeSchema);
export default Quize;


