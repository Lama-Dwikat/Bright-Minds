


import mongoose, { Schema } from "mongoose";
import User from "./user.model.js";





var videoSchema= new mongoose.Schema(

{
title:{
    type:String,
    required:true,
    //unique:true,
    trim:true,
},
description:{
    type:String,
   // required:true,
},
category:{
    type:String,
    required:true
},
url:{
    type:String,
    required:true
},
  thumbnailUrl: {
      type: String, 
    },
isPublished:{
    type:Boolean,
    default:false
},
ageGroup:{
    type:String,
    required:true,
    enum:["5-8","9-12"]
},
createdBy:{
   type:mongoose.Schema.Types.ObjectId,
   ref:"User"
},
views:{
    type:Number,
    default:0},

  recommended:{
    type:Boolean,
    default:false
  }   ,

} , 


{
timestamps:true
}

);

const Video=mongoose.model("Video",videoSchema);
export default Video