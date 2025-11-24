import mongoose from "mongoose";
import bcrypt from "bcrypt";
import multer from "multer";



const userSchema = mongoose.Schema(
    {
        
        name: {
            type: String,
            required: true,
            trim: true,
             
        },
        
        role: {
            type: String,
            enum: ["child", "parent", "supervisor", "admin"], 
            required: true
        },
        
        email: {
            type: String,
           // sparse: true,
            unique: true , 
            required:true,
           match:/^[a-zA-Z0-9._%+-]+@gmail\.com$/

        },

        password: {
            type: String,
            required: true,
            minlength:8,
            maxlength:64
        },

        age: Date,


        ageGroup:  {
            type: String,
            enum:["5-8" , "9-12"]
        },

        // profilePicture: String,
        
        // cv: String,

        // Store files as binary buffers
        profilePicture: { 
        data: Buffer,
         contentType: String
         },

        cv: {
         data: Buffer,
          contentType: String },

        cvStatus: {
            type: String,
            enum: ["pending", "approved", "rejected"],
            default: "pending",
        },


        parentId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User"
        },

        parentCode: String,
        parentCodeExpires: Date,


        supervisorId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User"
        },

 

       videoHistory: [
         {
           video: { type: mongoose.Schema.Types.ObjectId, ref: "Video" },
           watchedAt: { type: Date },
         }
       ],
          favouriteVideos: [
         {
           video: { type: mongoose.Schema.Types.ObjectId, ref: "Video" },
         }
       ],
         // Fields to track watch time
         dailyVidoeTime: { type: Number,default: 0 }, // in minutes
         lastVideoDate: { type: Date },
         dailyVideoLimit: { type: Number, default: 20 } // daily limit in minutes




    },


    {
        // Enable timestamps for createdAt and updatedAt fields
        timestamps: true
    }  
);

// Hash password before saving the user
userSchema.pre("save", async function (next) {
  if (!this.isModified("password")) return next(); // Only hash if password is new or modified
  const salt = await bcrypt.genSalt(10); // Generate salt
  this.password = await bcrypt.hash(this.password, salt);// Hash the password
  next();
});

// Method to generate a unique parent code
userSchema.methods.generateParentCode = function () {
  if (this.role === "parent") {
    this.parentCode = Math.floor(100000 + Math.random() * 900000).toString();// 6-digit code
    // const expiryTime = new Date();// Set expiry time to 24 hours from now
    // expiryTime.setHours(expiryTime.getHours() + 24);
    // this.parentCodeExpires = expiryTime;
  }
};

// Method to validate the parent code
userSchema.methods.isParentCodeValid = function (code) {
  return (
    this.parentCode === code &&
    this.parentCodeExpires &&
    this.parentCodeExpires > new Date()
  );
};






const User = mongoose.model("User", userSchema);
export default User;

