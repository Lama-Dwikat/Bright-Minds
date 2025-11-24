import { Schema }  from "mongoose";
import mongoose from "mongoose";

const playListSchema = new mongoose.Schema({

title:{
    type:String,
    required:true,
    trim:true,
},
description:{
    type:String,
},
category:{
    type:String,
    required:true
},
videos:[
    {
        type:mongoose.Schema.Types.ObjectId,
         ref:"Video"
        }
],
isPublished:{
    type:Boolean,
    default:false,
},
createdBy:{
    type:mongoose.Schema.Types.ObjectId,
    ref:"User"
}

},

{
    timestamps:true,
}


);

const PlayList=mongoose.model("PlayList",playListSchema);
export default PlayList