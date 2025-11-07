import mongoose from "mongoose";

const ActivityLogSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true }, 
  storyId: { type: mongoose.Schema.Types.ObjectId, ref: "Story" }, 
  pageNumber: { type: Number }, 
  prompt: { type: String },  
  status: { 
    type: String, 
    enum: ["success", "error"], 
    required: true 
  },
  role: { 
    type: String, 
    enum: ["child", "supervisor", "admin"], 
    default: "child" 
  },
  errorMessage: { type: String }, 
  createdAt: { type: Date, default: Date.now }
});

const ActivityLog = mongoose.model("ActivityLog", ActivityLogSchema);

export default ActivityLog;
