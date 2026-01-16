import Dailywatch from "../models/dailyTime.model.js";


export const dailywatchService={

 normalizeDate(date=new Date()){
    return new Date(date.getFullYear(),date.getMonth(),date.getDate());
},

async getDailywatchRecord(userId){
    const today=this.normalizeDate();
    let record= await Dailywatch.findOne({userId,date:today});
    if(!record){
    const newrecord=await Dailywatch.create({userId,date:today});
     return newrecord;
    }
       
    return  record;

},


async calculateDailyWatch(userId , minutes){
    let record = await this.getDailywatchRecord(userId);
    if (record.dailyWatchMin >= record.limitWatchMin){
        return  {allowed:false,message:"Daily Watch Limit Reached"};
    }
 const newTotal = record.dailyWatchMin + minutes; // minutes can be 0.1667 etc.
if (newTotal >= record.limitWatchMin) {
    record.dailyWatchMin = record.limitWatchMin;
    await record.save();
    return {allowed:false,message:"Daily Watch Limit Reached"}
}
record.dailyWatchMin = newTotal;
await record.save();


},

async canWatch(userId){
   // const today = this.normalizeDate();
    let record= await this.getDailywatchRecord(userId);
    return {allowed:record.dailyWatchMin<record.limitWatchMin};
 },

 async calculateTimeRemaining(userId){
     // const today = this.normalizeDate();
    let record= await this.getDailywatchRecord(userId);
     if (record.dailyWatchMin >= record.limitWatchMin){
        return {allowed:false,message:"Daily Watch Limit Reached"};
    }
    const min= record.limitWatchMin-record.dailyWatchMin;
    return {allowed:true,data:min};

 },
 async deleteDailywatch(userId){
    const today=this.normalizeDate();
    return  await Dailywatch.findOneAndDelete({userId:userId,date:today});

 },
 
 async getUserRecord(userId){
    return await Dailywatch.find({userId});
       

},










}