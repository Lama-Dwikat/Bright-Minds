import {taskService} from  "../services/task.service.js"

export const taskController={

async addTask(req, res) {
  try {
    // MUST use await
    const newTask = await taskService.addTask(req.body);

    // send success response
    return res.status(201).json({
      message: "Task added successfully",
      newTask
    });

  } catch (error) {

    if (error.message === "task already exist") {
      return res.status(400).json({ error: error.message });
    }

    return res.status(500).json({ error: error.message });
  }
}
,

async getAllTasks(){
    try{
        const tasks=taskService.getAllTasks()
        if(!tasks)
         return res.status(404).json({message:"error while fetching tasks"})
        return res.status(200).json(tasks);
    }catch(error){
            res.status(500).json({ error: error.message });
        
    }
},

    async getTodayTasks(req,res){
        try{
          const {id }= req.params;
         // const {date}=req.query
          const tasks= await taskService.getTodayTasks(id);
            if (!tasks || tasks.length === 0) {
      return res.status(404).json({ message: "Error while fetching tasks" });
    }
    return res.status(200).json(tasks);
           }catch(error){
            res.status(500).json({ error: error.message });
        
    }
        },
    async updateTask(req,res){
        try{
        const task = await taskService.updateTask(req.params.id,req.body);
         if(!task)
         return res.status(404).json({message:"task not exist"})
        return res.status(200).json(task)
        }catch(error){
            res.status(500).json({ error: error.message });
          }
          },
       
    async deleteTask(req,res){
          try{
            const task= await taskService.deleteTask(req.params.id)
            if(!task)
         return res.status(404).json({message:"task not exist"})
        return res.status(200).json(task)
       }catch(error){
            res.status(500).json({ error: error.message });
        
          }
         },
           }




