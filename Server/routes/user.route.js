import express from 'express';
import { userController } from '../controllers/user.controller.js';
export const userRouter = express.Router();

// User routes
userRouter.post('/users/createUser', userController.createUser);
userRouter.post('/users/signIn',userController.signin)
userRouter.get('/users/getme/:id', userController.getUserById);
userRouter.delete('/users/deleteme/:id', userController.deleteUser);
userRouter.delete('/users/deleteAll', userController.deleteAllUsers);
userRouter.put('/users/updateprofile/:id', userController.updateUser);
userRouter.put('/users/updateprofileByEmail/:email', userController.updateUserByEmail);
userRouter.get('/users/id/:id', userController.getUserById);
userRouter.get('/users/name/:name', userController.getUserByName);
userRouter.get('/users/email/:email', userController.getUserByEmail);
userRouter.get('/users/role/:role', userController.getUsersByRole);
userRouter.get('/users/getall', userController.getAllUsers);
userRouter.post('/users/approvestatus/:id', userController.approveCV);
userRouter.post('/users/rejectstatus/:id', userController.rejectCV);
userRouter.post('/users/link-child', userController.linkChildToParent);


