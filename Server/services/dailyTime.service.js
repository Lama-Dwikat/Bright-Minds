// import Dailywatch from "../models/dailyTime.model.js";


// export const dailywatchService={

//  normalizeDate(date=new Date()){
//     return new Date(date.getFullYear(),date.getMonth(),date.getDate());
// },

// async getDailywatchRecord(userId){
//     const today=this.normalizeDate();
//     let record= await Dailywatch.findOne({userId,date:today});
//     if(!record){
//     const newrecord=await Dailywatch.create({userId,date:today});
//      return newrecord;
//     }
       
//     return  record;

// },


// async calculateDailyWatch(userId , minutes){
//     let record = await this.getDailywatchRecord(userId);
//     if (record.dailyWatchMin >= record.limitWatchMin){
//         return  {allowed:false,message:"Daily Watch Limit Reached"};
//     }
//  const newTotal = record.dailyWatchMin + minutes; // minutes can be 0.1667 etc.
// if (newTotal >= record.limitWatchMin) {
//     record.dailyWatchMin = record.limitWatchMin;
//     await record.save();
//     return {allowed:false,message:"Daily Watch Limit Reached"}
// }
// record.dailyWatchMin = newTotal;
// await record.save();


// },

// async canWatch(userId){
//    // const today = this.normalizeDate();
//     let record= await this.getDailywatchRecord(userId);
//     return {allowed:record.dailyWatchMin<record.limitWatchMin};
//  },

//  async calculateTimeRemaining(userId){
//      // const today = this.normalizeDate();
//     let record= await this.getDailywatchRecord(userId);
//      if (record.dailyWatchMin >= record.limitWatchMin){
//         return {allowed:false,message:"Daily Watch Limit Reached"};
//     }
//     const min= record.limitWatchMin-record.dailyWatchMin;
//     return {allowed:true,data:min};

//  },
//  async deleteDailywatch(userId){
//     const today=this.normalizeDate();
//     return  await Dailywatch.findOneAndDelete({userId:userId,date:today});

//  },
 



//  async getUserRecord(userId){
//     return await Dailywatch.find({userId});
    
// },


// async calculateDailyPlay(userId, minutes) {
//     let record = await this.getDailywatchRecord(userId);

//     if (record.dailyPlayMin >= record.limitPlayMin) {
//       return { allowed: false, message: "Daily Game Limit Reached" };
//     }

//     const newTotal = record.dailyPlayMin + minutes;
//     if (newTotal >= record.limitPlayMin) {
//       record.dailyPlayMin = record.limitPlayMin;
//       await record.save();
//       return { allowed: false, message: "Daily Game Limit Reached" };
//     }

//     record.dailyPlayMin = newTotal;
//     await record.save();
//     return { allowed: true, data: newTotal };
//   },

//   async canPlay(userId) {
//     let record = await this.getDailywatchRecord(userId);
//     return { allowed: record.dailyPlayMin < record.limitPlayMin };
//   },

//   async calculatePlayTimeRemaining(userId) {
//     let record = await this.getDailywatchRecord(userId);
//     if (record.dailyPlayMin >= record.limitPlayMin) {
//       return { allowed: false, message: "Daily Game Limit Reached" };
//     }
//     const min = record.limitPlayMin - record.dailyPlayMin;
//     return { allowed: true, data: min };
//   },








// }


import Dailywatch from "../models/dailyTime.model.js";

export const dailywatchService = {
  normalizeDate(date = new Date()) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate());
  },

  async getDailywatchRecord(userId) {
    const today = this.normalizeDate();
    let record = await Dailywatch.findOne({ userId, date: today });
    if (!record) {
      record = await Dailywatch.create({ userId, date: today });
    }
    return record;
  },

  async calculateDailyWatch(userId, minutes) {
    const record = await this.getDailywatchRecord(userId);
    if (record.dailyWatchMin >= record.limitWatchMin) {
      return { allowed: false, message: "Daily Watch Limit Reached" };
    }

    const newTotal = record.dailyWatchMin + minutes;
    record.dailyWatchMin = Math.min(newTotal, record.limitWatchMin);
    await record.save();

    return newTotal >= record.limitWatchMin
      ? { allowed: false, message: "Daily Watch Limit Reached" }
      : { allowed: true, data: record.dailyWatchMin };
  },

  async canWatch(userId) {
    const record = await this.getDailywatchRecord(userId);
    return { allowed: record.dailyWatchMin < record.limitWatchMin };
  },

  async calculateTimeRemaining(userId) {
    const record = await this.getDailywatchRecord(userId);
    if (record.dailyWatchMin >= record.limitWatchMin)
      return { allowed: false, message: "Daily Watch Limit Reached" };
    return { allowed: true, data: record.limitWatchMin - record.dailyWatchMin };
  },

  async deleteDailywatch(userId) {
    const today = this.normalizeDate();
    return await Dailywatch.findOneAndDelete({ userId, date: today });
  },

  async getUserWatchRecord(userId) {
    return await Dailywatch.find({ userId });
  },

  // ----------------- PLAY FUNCTIONS -----------------
  async calculateDailyPlay(userId, minutes) {
    const record = await this.getDailywatchRecord(userId);
    if (record.dailyPlayMin >= record.limitPlayMin) {
      return { allowed: false, message: "Daily Game Limit Reached" };
    }

    const newTotal = record.dailyPlayMin + minutes;
    record.dailyPlayMin = Math.min(newTotal, record.limitPlayMin);
    await record.save();

    return newTotal >= record.limitPlayMin
      ? { allowed: false, message: "Daily Game Limit Reached" }
      : { allowed: true, data: record.dailyPlayMin };
  },

  async canPlay(userId) {
    const record = await this.getDailywatchRecord(userId);
    return { allowed: record.dailyPlayMin < record.limitPlayMin };
  },

  async calculatePlayTimeRemaining(userId) {
    const record = await this.getDailywatchRecord(userId);
    if (record.dailyPlayMin >= record.limitPlayMin)
      return { allowed: false, message: "Daily Game Limit Reached" };
    return { allowed: true, data: record.limitPlayMin - record.dailyPlayMin };
  },
};
