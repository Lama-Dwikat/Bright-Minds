

import  {userService} from '../services/user.service.js';

 export const userController={
    async signup(req,res){
        try{
    const newUser=req.body;
    await userService.signup(newUser);
    res.status(201).send("User Created Successfully");
        }  catch(error){
            res.status(400).send({error:error.message});
        }

    },
    
    async signin (req,res){
        try{
   const userName= req.body.userName;
   const password=req.body.password;
     await userService.signin(userName,password);
     res.status(200).send("Signin Successful");
        }
        catch(error){
            res.status(400).send({error:error.message});
        }},

async getUserById (req,res){
    try{
    const userId=req.params.id;
    await userService.findUserById(userId);
    res.status(200).send("User Found");
    } catch (error){
        res.status(400).send({error:error.message});
    }
},

    async getAllUsers (req,res){
    try{
    await userService.findAllUsers();
    res.status(200).send("Users Found");
    } catch (error){
        res.status(400).send({error:error.message});
    }},

    async deleteUserById (req,res){
        try{
    const userId=req.params.id;
    await userService.deleteUserById(userId);
    res.status(200).send("User Deleted Successfully");
        } catch (error){
            res.status(400).send({error:error.message});
        }
    },

    async deleteUserByUsername (req,res){
        try{
    const username=req.params.username;
    await userService.deleteUserByUsername(username);
    res.status(200).send("User Deleted Successfully");
        } catch (error){
            res.status(400).send({error:error.message});
        }
    },


    async deleteAllUsers (req,res){
        try{
    await userService.deleteAllUsers();
    res.status(200).send("All Users Deleted Successfully");
        } catch (error){
            res.status(400).send({error:error.message});
        }
    },

    async updateUserById (req,res){
        try{
    const userId=req.params.id;
    const updatedData=req.body;
    await userService.updateUserById(userId,updatedData);
    res.status(200).send("User Updated Successfully");
        } catch (error){
            res.status(400).send({error:error.message});
        }
    },

    async updateUserByUsername (req,res){
        try{
    const username=req.params.username;
    const updatedData=req.body;
    await userService.updateUserByUserName(username,updatedData);
    res.status(200).send("User Updated Successfully");
        } catch (error){
            res.status(400).send({error:error.message});
        }
    },
};  