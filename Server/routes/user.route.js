
import express from "express";
import {userController} from "../controller/user.controller.js";
export const router = express.Router();

//User Routes
export const userRoutes =   (app) => {
  router.post("/signup", userController.signup);
  router.post("/signin", userController.signin);
  router.get("/:id", userController.getUserById);
  router.get("/", userController.getAllUsers);
  router.delete("/id/:id", userController.deleteUserById);
  router.delete("/username/:username", userController.deleteUserByUsername);
  router.delete("/", userController.deleteAllUsers);
  router.put("/id/:id", userController.updateUserById);
  router.put("/username/:username", userController.updateUserByUsername); 

  app.use("/api/user", router);
};




 



