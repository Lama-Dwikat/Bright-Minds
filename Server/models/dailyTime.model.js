import mongoose, { Mongoose } from "mongoose";

const dailywatchSchema=new mongoose.Schema({
userId:{
    type:mongoose.Schema.ObjectId,
    ref:'User',
},
limitWatchMin:{
    type:Number,
    default:30
},
dailyWatchMin:{
    type:Number,
    default:0,
},
date:{
    type:Date,
    required:true,
},
limitPlayMin:{
    type:Number,
    default:30
},
dailyPlayMin:{
    type:Number,
    default:0,
},
},
{

    timestamps:true
}
);
dailywatchSchema.index({ userId: 1, date: 1 }, { unique: true });

const Dailywatch=mongoose.model("Dailywatch",dailywatchSchema);
export default Dailywatch;


