import "../controllers/task.controller.js"
import express from "express"
import { taskController } from "../controllers/task.controller.js";


 export const taskRouter= express.Router();

 taskRouter.post('/tasks/addTask',taskController.addTask);
 taskRouter.get('/tasks/getAllTasks',taskController.getAllTasks);
 taskRouter.get('/tasks/getTodayTasks/:id',taskController.getTodayTasks);
 taskRouter.put('/tasks/updateTask/:id',taskController.updateTask);
 taskRouter.delete('/tasks/deleteTask/:id',taskController.deleteTask);
