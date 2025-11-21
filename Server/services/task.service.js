import Task from "../models/task.model.js"

export const taskService={

async addTask(data){
  const exisitingTask=await  Task.findOne({description:data.description , supervisorId:data.supervisorId});
  if(exisitingTask)
    throw new Error ("task already exist ")
  const newTask =  new Task(data);
  return await newTask.save();
},

async getAllTasks(){
 return await Task.find()
},


 async getTodayTasks(supervisorId) {
  return await Task.find({
    supervisorId: supervisorId,
   // date: { $lte: date },   // less or equal
    done: false            // not done yet
  });
},

async updateTask(id, taskData) {
    return await Task.findOneAndUpdate(
        { _id: id },  // <-- use a filter object
        taskData,
        { new: true }
    );
},
async deleteTask(id){
    return await Task.findByIdAndDelete(id);
}


}