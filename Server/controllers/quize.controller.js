
import { get } from "mongoose";
import { quizeService }  from "../services/quize.service.js";

export const quizeController={

    async creatQuize(req,res){
        try{
            const quize=await quizeService.createQuize(req.body);
            if(!quize){
                return res.status(400).json({message:'Quize creation failed'});
            }
            res.status(201).json({message:"Quize created successfully",quize});
        }
        catch(error){
            res.status(500).json({message:error.message})
        }
    },


    async getQuizeById(req,res){
        try{
        const quize=await quizeService.getQuizeById(req.params.id);
        if (!quize){
                return res.status(404).json({message:error.message})
            }
        return res.status(200).json(quize);

        }catch(error){
            res.status(500).json({message:error.message})
    }

    },
    async getQuizeByCreator(req,res){
        try{
        const quize=await quizeService.getQuizeByCreator(req.params.creatorId);
       if (!quize){
                return res.status(404).json({message:error.message})
            }
                return res.status(200).json(quize);

        }catch(error){
            
            res.status(500).json({message:error.message})
    }

    },

    async getAllQuizes(req,res){
        try{
        await quizeService.getAllQuizes()
       res.status(200).json(quizes);
        }catch(error){
            res.status(500).json({message:error.message})       

    } 
},

    async updateQuize(req,res){
        try{
        const updatedQuize=await quizeService.updateQuize(req.params.id,req.body);
        if(!updatedQuize){
            return res.status(404).json({message:'Quize not found'});
        }
        res.status(200).json({message:'Quize updated successfully',updatedQuize});
        }catch(error){
            res.status(500).json({message:error.message})       
    }


    },

   async  updateSingleQuestion (req, res) {
  try {
    const { quizId, questionIndex } = req.params;
    const updatedData = req.body;

    const updatedQuiz = await quizeService.updateSingleQuestion(
      quizId,
      questionIndex,
      updatedData
    );

    if (!updatedQuiz) {
      return res.status(404).json({ message: "Quiz not found" });
    }

    return res.status(200).json({
      message: "Question updated successfully",
      quiz: updatedQuiz,
    });
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }},

  
    async deleteQuize(req,res){         
        try{
        const deletedQuize=await quizeService.deleteQuize(req.params.id);
        if(!deletedQuize){
            return res.status(404).json({message:'Quize not found'});
        }
        res.status(200).json({message:'Quize deleted successfully'});
        }catch(error){
            res.status(500).json({message:error.message})       
    }   

    },      

    async deleteAllQuizes(req,res){ 
        try{        
        await quizeService.deleteAllQuizes();
        res.status(200).json({message:'All quizes deleted successfully'});
        }
        catch(error){
            res.status(500).json({message:error.message})       
    }

    }   ,










}





