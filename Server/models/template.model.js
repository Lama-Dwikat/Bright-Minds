import mongoose from "mongoose";
//import PageSchema from "./Page.js";


const TemplateSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  description: { type: String, maxlength: 500 },
  coverImageUrl: String,
  defaultTheme: { 
    type: String, 
    enum: ["light", "dark", "kids"], 
    default: "light" 
  },
 // defaultPages: { type: [PageSchema], default: [] }
 defaultPages: { 
  type: [
    {
      title: String,
      elements: Array
    }
  ], 
  default: [] 
}
});

const Template = mongoose.models.Template || mongoose.model("Template", TemplateSchema);
export default Template;
