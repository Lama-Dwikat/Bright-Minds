import userService from '../services/user.service.js';
import mongoose from 'mongoose';

export const userController = {

    // Create a new user
    // async createUser(req, res) {
    //     try {
    //         const user = await userService.createUser(req.body);
    //         res.status(201).json(user);
    //     } catch (error) {
    //    if (error.message === "Email already exists") {
    //     return res.status(400).json({ error: error.message });
    //     }
    //    res.status(500).json({ error: error.message });
    //   }

    // },
    async createUser(req, res) {
  try {
    const userData = req.body;

  if (userData.profilePicture) {
  userData.profilePicture = {
    data: Buffer.from(userData.profilePicture, "base64"),
    contentType: "image/png", // consider using 'mime' package for dynamic detection
  };
}

if (userData.cv) {
  userData.cv = {
    data: Buffer.from(userData.cv, "base64"),
    contentType: "application/pdf",
  };
}


    const user = await userService.createUser(userData);
    res.status(201).json(user);
  } catch (error) {
    if (error.message === "Email already exists") {
      return res.status(400).json({ error: error.message });
    }
    res.status(500).json({ error: error.message });
  }
},



  async signin(req, res) {
  try {
    const email = req.body.email;
    const password = req.body.password;

    // This calls the service that checks email/password
    const user = await userService.signin(email, password);

    // Send user details (with role) back to Flutter
    res.status(200).json({
      message: "Signin Successful",
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role
      }
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
        },





        // Update user by ID
    async updateUser(req, res) {
        try {
            // Proceed with the update
            const user = await userService.updateUser(req.params.id, req.body);
            if (!user) {
            return res.status(404).json({ error: 'User not found' });
            }
            res.status(200).json(user);

            } catch (error) {
            res.status(500).json({ error: error.message });
        }
    },

        // Update user by ID
    async updateUserByEmail(req, res) {
        try {
            // Proceed with the update
            const user = await userService.updateUserByEmail(req.params.email, req.body);
            if (!user) {
            return res.status(404).json({ error: 'User not found' });
            }
            res.status(200).json(user);
            } catch (error) {
            res.status(500).json({ error: error.message });
        }
    },


    // Delete user by ID
    async deleteUser(req, res) {
        try {
            const user = await userService.deleteUser(req.params.id);
            if (!user) {
                return res.status(404).json({ error: 'User not found' });
            }
            res.status(200).json({ message: 'User deleted successfully' });
        } catch (error) {
            res.status(500).json({ error: error.message });
        }
    },

    

    //Delete all users
    async deleteAllUsers(req,res){
        try{
         await userService.deleteAllUsers()
         res.status(200).send("All users deleted")
       }catch(error){
       res.status(500).send({error: error.message})
       }
    },


        
    // Get user by ID
    async getUserById(req, res) {
        try {
            const user = await userService.getUserById(req.params.id);
            if (!user) {
                return res.status(404).json({ error: 'User not found' });
            }
            res.status(200).json(user);
        } catch (error) {
            res.status(500).json({ error: error.message });
        }
    },

    async getUserByName(req,res){
     try{

        const user =  await userService.getUserByName(req.params.name)
        res.status(200).send("User found")
     }catch(error){
     res.status(404).message("User not found")
   }
   },

    // Get user by email
   async getUserByEmail(req, res) {
       try {
           const user = await userService.getUserByEmail(req.params.email);
           if (!user) {
               return res.status(404).json({ error: 'User not found' });
           }
           res.status(200).json(user);
       } catch (error) {
           res.status(500).json({ error: error.message });
       }
   },

   // Get users by role
   async getUsersByRole(req, res) {
       try {
           const users = await userService.getUsersByRole(req.params.role);
           res.status(200).json(users);
       } catch (error) {
           res.status(500).json({ error: error.message });
       }
   },   

    // Get all users
    async getAllUsers(req, res) {
        try {
            const users = await userService.getAllUsers();
            res.status(200).json(users);
        } catch (error) {
            res.status(500).json({ error: error.message });
        }
    },  

  


   
     
 // Approve CV
    async approveCV(req, res) {
        try {
            const user = await userService.approveCV(req.params.id);
            if (!user) {
                return res.status(404).json({ error: 'User not found' });
            }
            res.status(200).json(user);
        } catch (error) {
            res.status(500).json({ error: error.message });
        }
    },

    // Reject CV     
    async rejectCV(req, res) {
        try {
            const user = await userService.rejectCV(req.params.id);
            if (!user) {
                return res.status(404).json({ error: 'User not found' });
            }
            res.status(200).json(user);
        } catch (error) {
            res.status(500).json({ error: error.message });
        }   

   },


//     async uploadFiles (req, res)  {
//   try {
//     const userId = req.params.id;
//     user.profilePicture = req.files['profilePicture'][0].path;
// user.cv = req.files['cv'][0].path;
// await user.save();


//     const user = await User.findById(userId);
//     if (!user) return res.status(404).json({ message: "User not found" });

//     if (profilePicture) {
//       user.profilePicture = {
//         data: profilePicture.buffer,
//         contentType: profilePicture.mimetype,
//       };
//     }

//    if (cv) {
//   user.cv = {
//     data: cv.buffer,
//     contentType: cv.mimetype,
//   };
//   user.cvStatus = "pending"; // <-- Add this
// }


//     await user.save();
//     res.status(200).json({ message: "Files uploaded successfully", user });
//   } catch (err) {
//     res.status(500).json({ error: err.message });
//   }
//   },



}

export default userController;
