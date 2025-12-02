import {historyService} from "../services/videoHistory.service.js";


export const historyController={

async createHistory(req,res){ 
    try{
 const history= await historyService.createHistory(req.body);
 return res.status(201).json(history);

}catch(error){
     res.status(500).json({error:error.message});
    }  

},

async getHistory( req,res){
    try{
 const history= await historyService.getHistory(req.params.id);
 return res.status(200).json(history);

}catch(error){
     res.status(500).json({error:error.message});
    }  },

async getLastWatch(req,res){
    try{
  const limit=Number(req.query.limit)||10;      
 const history= await historyService.getLastWatch(req.params.id,limit);
 return res.status(200).json(history);
}catch(error){
     res.status(500).json({error:error.message});
    }  
},

  async clearHistory(req,res) {
    try{
 const history= await historyService.clearHistory(req.params.id);
 return res.status(200).json(history);

}catch(error){
     res.status(500).json({error:error.message});
    }    },
  

  async updateDuration(req,res) {
        try{
 const{durationWatched}=req.body
 const history= await historyService.updateDuration(req.params.id,durationWatched);

 return res.status(200).json(history);

}catch(error){
     res.status(500).json({error:error.message});
    }  
  },




}