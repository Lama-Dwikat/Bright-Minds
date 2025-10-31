const mongoose = require("mongoose");
const PageSchema = require("./Page");

const TemplateSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  description: { type: String, maxlength: 500 },
  coverImageUrl: String,
  defaultTheme: { 
    type: String, 
    enum: ["light", "dark", "kids"], 
    default: "light" 
  },
  defaultPages: { type: [PageSchema], default: [] }
});

const Template = mongoose.model("Template", TemplateSchema);
export default Template;
