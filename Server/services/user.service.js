import User from "../models/user.model.js";
import mongoose from "mongoose";
import bcrypt from "bcrypt";
import cors from 'cors';


export  const userService = {
     
    // Create a new user
    async createUser(userData) {

 const existingUser = await User.findOne({ email: userData.email });
    if (existingUser) throw new Error("Email already exists");

    if (userData.password.length < 8 || userData.password.length > 64)
      throw new Error("Password must be between 8 and 64 characters");

      const newUser = new User(userData);
        if (newUser.role === "parent") {
            newUser.generateParentCode();
        }   
        return await newUser.save();
       },
       

  async signin(email, password) {
  const user = await User.findOne({ email: email });
  if (!user) throw new Error("Invalid email or password");

  const validPassword = await bcrypt.compare(password, user.password);
  if (!validPassword) throw new Error("Invalid email or password");

  return user;
},


    // Update user by ID
    async updateUser(id, userData) {
        return await User.findByIdAndUpdate(id, userData, { new: true });
    },

    // update user by email
        async updateUserByEmail(email, updatedData) {
    await userModel.findOneAndUpdate({ email }, updatedData, { new: true });
    },


    // Delete user by ID
    async deleteUser(id) {
        return await User.findByIdAndDelete(id);
    },


    //delete all users
     async deleteAllUsers(){
        await User.deleteMany()
     },




    // Get user by ID
    async getUserById(id) {
        return await User.findById(id);
    },

    //Get user by name
     async getUserByName(name) {
         return await User.findOne({ name: name });

    },
    // Get user by email
    async getUserByEmail(email) {
        return await User.findOne({ email: email });
    },

    // Get users by role
    async getUsersByRole(role) {
        return await User.find({ role: role });
    },

        // Get all users
    async getAllUsers() {
        return await User.find();
    },

    // Approve CV
    async approveCV(userId) {
        return await User.findByIdAndUpdate(
            userId,
            { cvStatus: "approved" },
            { new: true }
        );
    },

    // Reject CV
    async rejectCV(userId) {
        return await User.findByIdAndUpdate(
            userId,
            { cvStatus: "rejected" },
            { new: true }
        );
    },


  //     async uploadFiles(userId, profilePicture, cv) {
  //   const user = await User.findById(userId);
  //   if (!user) throw new Error("User not found");

  //   if (profilePicture) {
  //     user.profilePicture = {
  //       data: profilePicture.buffer,
  //       contentType: profilePicture.mimetype,
  //     };
  //   }

  //   if (cv) {
  //     user.cv = {
  //       data: cv.buffer,
  //       contentType: cv.mimetype,
  //     };
  //   }

  //   await user.save();
  //   return user;
  // },

  

};

export default userService;

 