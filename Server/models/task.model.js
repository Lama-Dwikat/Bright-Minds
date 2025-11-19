import mongoose, { Schema } from "mongoose";
import User from "../models/user.model.js";

const taskModel=new Schema({
 

    description:String,
    supervisorId:{
        type:mongoose.Schema.Types.ObjectId,
        ref:'User'
    },
    done:Boolean,

  date: {
    type: Date,
    required:true,
   default: Date.now
}
},
{
    timestamps:true,
}
);

 const Task = mongoose.model("Task",taskModel);
 export default Task