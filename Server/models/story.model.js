import mongoose from "mongoose";

const ElementSchema = new mongoose.Schema({
  type: { type: String, enum: ["text","image","drawing","shape","sticker","audio"], required: true },//type of element
  content: String,
  //url: String,// for images, drawings, audio files if it is uploaded to cloudinary
  media: {
  mediaType: { type: String, enum: ["image","audio","video","drawing"] },
  url: String,
  page: Number, 
  elementOrder: Number 
  },
  dataUrl: String, //used if need to store base64 data not recommended
  x: { type: Number, default: 0 },
  y: { type: Number, default: 0 },
  width: Number,
  height: Number,
  fontSize: Number,
  fontFamily: String,
  fontColor: String,
  align: { type: String, enum: ["left","center","right"], default: "left" },
  order: Number
}, { _id: false });//it is embeded schema

const PageSchema = new mongoose.Schema({
  pageNumber: { type: Number, required: true },
  backgroundColor: String,
  backgroundImage: String, // URL
  audioUrl: String, // narration per page (optional)
  elements: [ElementSchema]
}, { _id: false });//it is embeded schema

const StorySchema = new mongoose.Schema({
  title: { type: String, required: true, trim: true },
  childId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  supervisorId: { type: mongoose.Schema.Types.ObjectId, ref: "User" }, // assigned reviewer
  //parentId: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
  //parentApproval: { type: Boolean, default: false },
  templateId: { type: mongoose.Schema.Types.ObjectId, ref: "Template" },
  coverImage: String,
  theme: String,
  pages: [PageSchema], // array of pages
  audioNarration: String, // full story audio (URL)
  //status: { type: String, enum: ["draft","pending","approved","rejected","needs_edit"], default: "draft" },
  status: { type: String, enum: ["draft","pending","approved","rejected","needs_edit","published"], default: "draft" },
  rating: { type: Number, min: 1, max: 5 },
  feedback: String,
  publicVisibility: { type: Boolean, default: false },
  isDraft: { type: Boolean, default: true },
  supervisorCommentsSeen: { type: Boolean, default: false },
  tags: [String],
  likesCount: { type: Number, default: 0 },
  viewsCount: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now },

  startedBy: { type: String, enum: ["child","supervisor"], default: "child" },
 continuedByChild: { type: Boolean, default: false },
 aiGenerated: { type: Boolean, default: false },
 publishedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },

aiPrompts: [
  {
    prompt: { type: String, required: false },
    role: { type: String, required: false },
    _id: false
  }
]
,
 baseStoryId: { type: mongoose.Schema.Types.ObjectId, ref: "Story" },
 lastEditedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
 lastEditedRole: { type: String, enum: ["child","supervisor","parent","admin"] },


  updatedAt: Date
}, { timestamps: true });

StorySchema.index({ childId:1, status:1 });
StorySchema.index({ title: "text", "pages.elements.content": "text" }); // text index for search
StorySchema.index({ publicVisibility: 1 });

//const Story = mongoose.model("Story", StorySchema);
const Story = mongoose.models.Story || mongoose.model("Story", StorySchema);
export default Story;

