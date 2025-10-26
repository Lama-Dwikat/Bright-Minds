import mongoose from "mongoose";
import bcrypt from "bcrypt";


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
            unique: true
        },

        password: {
            type: String,
            required: true,
        },

        age: Number,
        ageGroup:  {
            type: String,
            enum:["5-8" , "9-12"]
        },

        profilePicture: String,
        cv: String,
        cvStatus: {
            type: String,
            enum: ["pending", "approved", "rejected"],
            default: "pending"
        },


        parentId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User"
        },

        parentCode: String,
        parentCodeExpires: Date,
        createdAt: {
            type: Date,
            default: Date.now
        }
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
    const expiryTime = new Date();// Set expiry time to 24 hours from now
    expiryTime.setHours(expiryTime.getHours() + 24);
    this.parentCodeExpires = expiryTime;
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