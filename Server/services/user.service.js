import { userModel } from "../models/user.model.js";

export const userService = {
  async findByUsername(username) {
    const user = await userModel.findOne({ userName: username });
    if (!user) throw new Error("User not found");
    return user;
  },

  async findUserById(userId) {
    const user = await userModel.findById(userId);
    if (!user) throw new Error("User not found");
    return user;
  },

  async findAllUsers() {
    return await userModel.find();
  },

  async deleteUserById(userId) {
    await userModel.findByIdAndDelete(userId);
  },
     async deleteByUserName(username) {
    await userModel.findOneAndDelete({ userName: username });
    
     },
     async deleteAllUsers() {
    await userModel.deleteMany({});
  },

  async updateUserById(userId, updatedData) {
    await userModel.findByIdAndUpdate(userId, updatedData, { new: true });
  },

    async updateUserByUserName(userName, updatedData) {
    await userModel.findOneAndUpdate({ userName }, updatedData, { new: true });
    },
    
  async signup(userData) {
    const existingUser = await userModel.findOne({ userName: userData.userName });
    if (existingUser) throw new Error("Username already exists");

    if (userData.password.length < 8 || userData.password.length > 64)
      throw new Error("Password must be between 8 and 64 characters");

    if (userData.userName.length < 3 || userData.userName.length > 30)
      throw new Error("Username must be between 3 and 30 characters");

    const newUser = new userModel(userData);
    await newUser.save();
    return newUser;
  },

  async signin(userName, password) {
    const user = await userModel.findOne({ userName });
    if (!user || user.password !== password)
      throw new Error("Invalid username or password");
    return user;
  },

};
