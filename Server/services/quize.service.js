

import { get } from "mongoose";
import Quize from "../models/quize.model.js";
import axios from "axios";



export const quizeService = {

async createQuize(data){
    const existingQuize=await Quize.findOne({title:data.title,createdBy:data.createdBy});
    if(existingQuize)
        throw new Error('Quize with this title already exists');
    const newQuize=new Quize(data);
    return await newQuize.save();

},

async getQuizeById(id){
   return await Quize.findById(id);},

 async getQuizeByCreator(creatorId){
    return await Quize.find({createdBy:creatorId});
 },  

  async getQuizeByTitle(title){
    return await Quize.find({title:title});
  },

  async getAllQuizes(){
    return await Quize.find();
  },

async updateQuize(id, updatedData) {
  return await Quize.findByIdAndUpdate(
    id,
    { $set: updatedData },
    { new: true, runValidators: true }
  );
},
async updateSingleQuestion(quizId, questionIndex, updatedData) {
  let updateFields = {};
  Object.keys(updatedData).forEach(key => {
    updateFields[`questions.${questionIndex}.${key}`] = updatedData[key];
  });

  return await Quize.findByIdAndUpdate(
    quizId,
    { $set: updateFields },
    { new: true }
  );
},

    async deleteQuize(id){  
    return await Quize.findByIdAndDelete(id);   
    },  
    async deleteAllQuizes(){
        await Quize.deleteMany()
     },







  }