
import express from "express";
import {userController} from "../controller/user.controller.js";
 const router = express.Router();

//User Routes
export const userRoutes =   (app) => {
  router.post("/signup", userController.signup);
  router.post("/signin", userController.signin);
  router.get("/", userController.getAllUsers);
  router.delete("/", userController.deleteAllUsers);
  router.put("/id/:id", userController.updateUserById);
  router.get("/id/:id", userController.getUserById);
  router.delete("/id/:id", userController.deleteUserById);
  router.put("/userName/:username", userController.updateUserByUsername); 
  router.delete("/userName/:username", userController.deleteUserByUsername);

 app.use("/api/user", router);
};




 



