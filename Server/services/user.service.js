import User from "../models/user.model.js";
import mongoose from "mongoose";


export  const userService = {
     
    // Create a new user
    async createUser(userData) {
        const newUser = new User(userData);
        if (newUser.role === "parent") {
            newUser.generateParentCode();
        }   
        return await newUser.save();
    },

    // Get user by ID
    async getUserById(id) {
        return await User.findById(id);
    },



    // Get all users
    async getAllUsers() {
        return await User.find();
    },

    // Update user by ID
    async updateUser(id, userData) {
        return await User.findByIdAndUpdate(id, userData, { new: true });
    },

    // Delete user by ID
    async deleteUser(id) {
        return await User.findByIdAndDelete(id);
    },

    // Get user ID by username
    async getUserIdByUsername(username) {
        const user = await User.findOne({ username : username }).select("_id");
        return user ? user._id : null;
    },
     
    // Get user by email
    async getUserByEmail(email) {
        return await User.findOne({ email: email });
    },

    // Get users by role
    async getUsersByRole(role) {
        return await User.find({ role: role });
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

  

};

export default userService;

 