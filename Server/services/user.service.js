import "./Models/user.model.js";




export const userService = () =>{


    async function getUserByUsername(username){
    const user = await User.findById(userId);
    if(user){
    return user;}
    else{
        throw new Error("User not found");
    }
}


    async function signUp(userData){
        const userExists=await User.findOne({username:userData.userName})
        if(userExists){
    throw new Error('Username already exists');
}
else if(userData.password.length < 8 || userData.password.length > 64){
    throw new Error('Password must be between 8 and 64 characters');
}
else if (userData.userName.length < 3 || userData.userName.length > 30){
    throw new Error('Username must be between 3 and 30 characters');
}
else{
  const user = new User(userData);
  await user.save();
  return user;

    }
}




async function signIn(username,password){
    const user = await User.findByUsername(username);
    if(user){
        if(user.userName===username && user.password===password){
            return user;
        }
        else{
            throw new Error("Try Again , username or password is not correct");
        }
    }}

    async function getAllUsers(){
        const users = await User.find();
        return users;
    }



async function getUserById(userId){
    const user = await User.findById(userId);
    if(user){
        return user;
    }
    else{
        throw new Error("User not found");
    }      }

    async function updateUser(userId,updateData){
    const user = await User.findByIdAndUpdate(userId,updateData,{new:true});
    if(user){
        return user;
    }
    else{
        throw new Error("User not found");

    }
    }

    async function deleteUser(userId){
    const user = await User.findByIdAndDelete(userId);
    if(user){
        return user;
    }
    else{
        throw new Error("User not found");
    }
    }
    
    return{
        signUp,
        signIn,
        getAllUsers,
        getUserById,
        updateUser,
        deleteUser,
        getUserByUsername
    };






};