
import mongoose from "mongoose";


const videohistorySchema = new mongoose.Schema({
  userId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: "User", required: true },
  videoId: { 
    type: mongoose.Schema.Types.ObjectId,
     ref: "Video", required: true },
  watchedAt: {
     type: Date, 
    required:true },
    
  durationWatched: { 
    type: Number ,
  default:0,} // optional: seconds
},
{ 
  timestamps:true,
}
);

videohistorySchema.index({ userId: 1, watchedAt: -1 }); // fast queries for "last watched"

const Videohistory=mongoose.model("Videohistory",videohistorySchema);
export default Videohistory;


