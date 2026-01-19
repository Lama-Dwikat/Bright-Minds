// import {dailywatchService} from "../services/dailyTime.service.js";


// export const dailywatchController={


// async getDailywatchRecord(req,res){
//     try{
//     const  record = await dailywatchService.getDailywatchRecord(req.params.id);
//     return res.status(200).json(record);
//      }catch(err){
//       res.status(500).json({ error: "Failed to get the daily record" });

//      }

//        },


// async calculateDailyWatch(req,res ){
//     try{
//      const {minutes}=req.body;
//     let record =await  dailywatchService.calculateDailyWatch(req.params.id,minutes);
//     return res.status(200).json(record);
//      }catch(err){
//       res.status(500).json({ error: "Failed to calculate daily time" });

//      }
//      },



// async canWatch(req,res){
//     try{
//     const  record = await dailywatchService.canWatch(req.params.id);
//     return res.status(200).json(record);
//      }catch(err){
//       res.status(500).json({ error: "Failed to check watching availability" });

//      }
//  },

//  async calculateTimeRemaining(req,res){

//   try{
//     const  record =await dailywatchService.calculateTimeRemaining(req.params.id);
//     return res.status(200).json(record);
//      }catch(err){
//       res.status(500).json({ error: "Failed to calculate record" });

//      }

//  },
 
//    async deleteDailywatch(req,res){
//     try{
//     const  record =await dailywatchService.deleteDailywatch(req.params.id);
//     return res.status(200).json(record);
//      }catch(err){
//       res.status(500).json({ error: "Failed to delete Record" });

//      }

//        },



//      async getUserWatchRecord(req,res){
//     try{
//     const  record =await dailywatchService.getUserWatchRecord(req.params.id);
//     return res.status(200).json(record);
//      }catch(err){
//       res.status(500).json({ error: "Failed to fetch Records" });

//      }

//        },
//   async calculateDailyPlay(req, res) {
//     try {
//       const { minutes } = req.body;
//       let record = await dailywatchService.calculateDailyPlay(req.params.id, minutes);
//       return res.status(200).json(record);
//     } catch (err) {
//       res.status(500).json({ error: "Failed to calculate daily play time" });
//     }
//   },

//   async canPlay(req, res) {
//     try {
//       const record = await dailywatchService.canPlay(req.params.id);
//       return res.status(200).json(record);
//     } catch (err) {
//       res.status(500).json({ error: "Failed to check game availability" });
//     }
//   },

//   async playTimeRemaining(req, res) {
//     try {
//       const record = await dailywatchService.calculatePlayTimeRemaining(req.params.id);
//       return res.status(200).json(record);
//     } catch (err) {
//       res.status(500).json({ error: "Failed to calculate play time remaining" });
//     }
//   },


//     };


import { dailywatchService } from "../services/dailyTime.service.js";

export const dailywatchController = {
  async getDailywatchRecord(req, res) {
    try {
      const record = await dailywatchService.getDailywatchRecord(req.params.id);
      return res.status(200).json(record);
    } catch (err) {
      return res.status(500).json({ error: "Failed to get the daily record" });
    }
  },

  async calculateDailyWatch(req, res) {
    try {
      const { minutes } = req.body;
      const record = await dailywatchService.calculateDailyWatch(req.params.id, minutes);
      return res.status(200).json(record);
    } catch (err) {
      return res.status(500).json({ error: "Failed to calculate daily watch" });
    }
  },

  async canWatch(req, res) {
    try {
      const record = await dailywatchService.canWatch(req.params.id);
      return res.status(200).json(record);
    } catch (err) {
      return res.status(500).json({ error: "Failed to check watch availability" });
    }
  },

  async calculateTimeRemaining(req, res) {
    try {
      const record = await dailywatchService.calculateTimeRemaining(req.params.id);
      return res.status(200).json(record);
    } catch (err) {
      return res.status(500).json({ error: "Failed to calculate watch time remaining" });
    }
  },

  async deleteDailywatch(req, res) {
    try {
      const record = await dailywatchService.deleteDailywatch(req.params.id);
      return res.status(200).json(record);
    } catch (err) {
      return res.status(500).json({ error: "Failed to delete daily record" });
    }
  },

  async getUserWatchRecord(req, res) {
    try {
      const record = await dailywatchService.getUserWatchRecord(req.params.id);
      return res.status(200).json(record);
    } catch (err) {
      return res.status(500).json({ error: "Failed to fetch records" });
    }
  },

  async calculateDailyPlay(req, res) {
    try {
      const { minutes } = req.body;
      const record = await dailywatchService.calculateDailyPlay(req.params.id, minutes);
      return res.status(200).json(record);
    } catch (err) {
      return res.status(500).json({ error: "Failed to calculate daily play time" });
    }
  },

  async canPlay(req, res) {
    try {
      const record = await dailywatchService.canPlay(req.params.id);
      return res.status(200).json(record);
    } catch (err) {
      return res.status(500).json({ error: "Failed to check game availability" });
    }
  },

  async playTimeRemaining(req, res) {
    try {
      const record = await dailywatchService.calculatePlayTimeRemaining(req.params.id);
      return res.status(200).json(record);
    } catch (err) {
      return res.status(500).json({ error: "Failed to calculate play time remaining" });
    }
  },
};
