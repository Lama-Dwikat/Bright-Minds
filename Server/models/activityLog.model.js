import mongoose from "mongoose";

const ActivityLogSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true }, // المستخدم
  storyId: { type: mongoose.Schema.Types.ObjectId, ref: "Story", required: true }, // القصة المرتبطة
  pageNumber: { type: Number }, // رقم الصفحة إذا كان النشاط مرتبط بصفحة معينة
  prompt: { type: String },       // النص الذي أرسله المستخدم للذكاء الاصطناعي
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
  errorMessage: { type: String }, // رسالة الخطأ إذا فشلت العملية
  createdAt: { type: Date, default: Date.now }
});

const ActivityLog = mongoose.model("ActivityLog", ActivityLogSchema);

export default ActivityLog;
