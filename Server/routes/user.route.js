import express from 'express';
import { userController } from '../controllers/user.controller.js';
export const userRouter = express.Router();

// User routes
userRouter.post('/users/createUser', userController.createUser);
userRouter.get('/users/getme/:id', userController.getUserById);
userRouter.get('/users/getall', userController.getAllUsers);
userRouter.put('/users/updateprofile/:id', userController.updateUser);
userRouter.delete('/users/deleteme/:id', userController.deleteUser);
userRouter.post('/users/approvestatus/:id', userController.approveCV);
userRouter.post('/users/rejectstatus/:id', userController.rejectCV);
userRouter.get('/users/email/:email', userController.getUserByEmail);
userRouter.get('/users/role/:role', userController.getUsersByRole);

