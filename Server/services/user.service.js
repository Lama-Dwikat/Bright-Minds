


import "../models/user.model.js";

//Find User 
export const userService={
    async findByUsername(username){
  const user= userModel.findOne({username:username});
  if (user){
    return user;
  }
  else {
    throw new Error("User not found");
  }

},

   async findUserById (userId){
    const user= userModel.findById(userId);
    if (user){
      return user;
    }
    else {
      throw new Error("User not found");
    }
  
    },



       async findAllUsers(){
        const users= userModel.find();
        return users;
        },

 
//Delete User

 async deleteUserById (userId){
if(findUserById(userId)){
    await userMosdel.findByIdAndDelete (userId);
}
},

 async deleteUserByUsername(username){
    const user= await findByUsername(username);
    if(user){
        await userMosdel.findOneAndDelete({username:username});
    }
},

   async deleteAllUsers (){
    await userMosdel.deleteMany({});
    },


 
//Update User

   async updateUserById (userId){
    const user= await findUserById(userId);
    if(user){
        //update user fields here as needed
        await userModel.findByIdAndUpdate(userId,user);
    }
} ,

   async updateUserByUsername (username,updatedData){
    const user= await findByUsername(username);  }   ,  



//Create User 
 async signup(userData){
    if(findUserBuyUsername(userData.username)){
    throw new Error("Username already exists");
    }
    else if(userData.password.length < 8 || userData.password.length > 64){
        throw new Error("Password must be between 8 and 64 characters");
    }
    else if (userData.username.length < 3 || userData.username.length > 30){
        throw new Error("Username must be between 3 and 30 characters");
    }
    else if(findByEmail(userData.email)){
        throw new Error('Email already exists');}
        else if(findByAge(userData.Date)>5){
            throw new Error('User must be at least 13 years old');
        }
    else{
      const user = new userModel(userData);
      await user.save();
      return user;
    }

} ,

  async signin(username,password){
    const user= await findByUsername(username);
    if(user){
        if(user.username===username && user.password===password){
            return user;
        }
        else{
            throw new Error("Try Again , username or password is not correct");
        }
    }
}

}


    
    

        