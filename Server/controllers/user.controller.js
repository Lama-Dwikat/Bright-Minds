import {userService} from '../services/user.service.js';
import mongoose, { get } from 'mongoose';
import jwt from "jsonwebtoken";
import User from "../models/user.model.js";

export const userController = {


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




      async signin (req,res){
        try{
       const email= req.body.email;
      const password=req.body.password;

      const user = await userService.signin(email, password);

      const token = jwt.sign(
        { id: user._id, role: user.role ,name:user.name,ageGroup:user.ageGroup,  

    //     profilePicture: user.profilePicture
    //   ? user.profilePicture.data.toString('base64')  // convert buffer to Base64
    // : null
   // profilePicture: user.profilePicture?.data?.toString('base64') ?? null


      
    }, 
        process.env.JWT_SECRET,           
        { expiresIn: "7d" }               
      );
       
       res.status(200).json({
        message: "Signin Successful",
        token,
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          role: user.role,
           cvStatus: user.cvStatus ?? "not_required",          // profilePicture: user.profilePicture
        },
      });

        }
        catch(error){
            res.status(400).send({error:error.message });
            
        }},






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
        res.status(200).json(user)
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




// Link child to parent using parentCode
async linkChildToParent(req, res) {
    try {
        const { childId, parentCode } = req.body;

        if (!childId || !parentCode) {
            return res.status(400).json({ error: "childId and parentCode are required" });
        }

        const child = await userService.getUserById(childId);
        if (!child) return res.status(404).json({ error: "Child not found" });

        const parent = await userService.getUserByParentCode(parentCode);
        if (!parent) return res.status(404).json({ error: "Invalid parent code" });

        child.parentId = parent._id;
        await child.save();

        res.status(200).json({ message: "Child linked to parent successfully" });

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
},

    async updateCvStatus(req, res) {
        try {
            const { status } = req.body;
            const user = await userService.updateCvStatus(req.params.id, status);
            res.status(200).json(user);
        } catch (error) {
            if(error.message==="CV status can only be updated for supervisors"){
                return res.status(400).json({error: error.message});
            }
            res.status(500).json({ error: error.message });
        }
    },

    async addAGeGroupToSupervisor(req, res) {
        try {
            const {ageGroup}=req.body;
            const user =await userService.addAGeGroupToSupervisor(req.params.id, ageGroup);
            res.status(200).json(user); 
        }
       catch(error){
        if(error.message==="Only supervisors can add age groups" || error.message==="User not found"){
            return res.status(400).json({error: error.message});
        }
        res.status(500).json({ error: error.message });

    }

    },


    async getKidsForSupervisor(req, res) {
        try {
            const supervisorId = req.params.id;
            const kids = await userService.getKidsForSupervisor(supervisorId);
            res.status(200).json(kids);
        } catch (error) {
            res.status(500).json({ error: error.message });
        }
    },
    

    async addFavouriteVideo(req, res) {
    try {
      const { videoId } = req.body; // data from client
      const updatedUser = await userService.addFavouriteVideo(req.params.id, videoId);
      return res.status(200).json(updatedUser);
    } catch (error) {
      return res.status(500).json({ error: error.message });
    }
  },

  async deleteFavouriteVideo(req, res) {
    try {
      const { videoId } = req.body;
      const updatedUser = await userService.deleteFavouriteVideo(req.params.id, videoId);
      return res.status(200).json(updatedUser);
    } catch (error) {
      return res.status(500).json({ error: error.message });
    }},


     async getUserFavourite(req,res){
        try{
     const user = await userService.getUserFavourite(req.params.id);
  return res.status(200).json(user);
    } catch (error) {
      return res.status(500).json({ error: error.message });                  }
       },
       
   /*  async getParentKids(req,res){
        try{
     const user = await userService.getParentKids(req.params.parentId);
  return res.status(200).json(user);
    } catch (error) {
      return res.status(500).json({ error: error.message });                  }
       },*/
       async getParentKids(req, res) {
  try {
    const { parentId } = req.params;

    const kids = await User.find({
      parentId: parentId,
      role: "child",
    }).select("_id name email age ageGroup parentId");

    return res.status(200).json(kids);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
},


/*(req, res) {
  try {
    if (req.user.role !== "parent") {
      return res.status(403).json({ error: "Only parents can view kids" });
    }
    const kids = await userService.getParentKids(req.user._id);
    return res.status(200).json(kids);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
}*/
async getMyKids(req, res) {
  try {
    if (req.user.role !== "parent") {
      return res.status(403).json({ error: "Only parents can view kids" });
    }

    const kids = await userService.getParentKids(req.user._id);
    return res.status(200).json(kids);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
},

//  Parent links a child using child's email
async linkChildToParentByEmail(req, res) {
  try {
    const { childEmail } = req.body;

    if (!childEmail) {
      return res.status(400).json({ error: "childEmail is required" });
    }

    // only parent can link
    if (req.user.role !== "parent") {
      return res.status(403).json({ error: "Only parents can link children" });
    }

    const email = childEmail.toLowerCase().trim();

    // find child
    const child = await userService.getUserByEmail(email);
    if (!child) {
      return res.status(404).json({ error: "Child must register first" });
    }

    if (child.role !== "child") {
      return res.status(400).json({ error: "Email is not for a child account" });
    }

    // already linked to another parent?
    if (child.parentId && child.parentId.toString() !== req.user._id.toString()) {
      return res.status(409).json({ error: "Child already linked to another parent" });
    }

    child.parentId = req.user._id;
    await child.save();

    return res.status(200).json({
      message: "Child linked successfully",
      child: { id: child._id, name: child.name, email: child.email, parentId: child.parentId },
    });

  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
},
// Parent unlink child (remove parentId)
async unlinkChild(req, res) {
  try {
    const { childId } = req.body;

    if (!childId) return res.status(400).json({ error: "childId is required" });

    if (req.user.role !== "parent") {
      return res.status(403).json({ error: "Only parents can unlink children" });
    }

    const child = await User.findById(childId);
    if (!child) return res.status(404).json({ error: "Child not found" });

    // ensure this child belongs to THIS parent
    if (!child.parentId || child.parentId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ error: "This child is not linked to you" });
    }

    child.parentId = null;
    await child.save();

    return res.status(200).json({ message: "Unlinked ✅" });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
},
// GET /api/users/my-cv
async getMyCv(req, res) {
  try {
    if (req.user.role !== "supervisor") {
      return res.status(403).json({ error: "Only supervisors can view CV" });
    }

    const u = await User.findById(req.user._id);
    if (!u) return res.status(404).json({ error: "User not found" });

    if (!u.cv || !u.cv.data) {
      return res.status(404).json({ error: "No CV uploaded" });
    }

    res.set("Content-Type", u.cv.contentType || "application/pdf");
    return res.status(200).send(u.cv.data); // send pdf bytes
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
},

        async getAdmins(req,res){
        try{
     const user = await userService.getAdmins();
  return res.status(200).json(user);
    } catch (error) {
      return res.status(500).json({ error: error.message });                  }
       },

           async getSupervisos(req,res){
        try{
     const user = await userService.getSupervisors();
  return res.status(200).json(user);
    } catch (error) {
      return res.status(500).json({ error: error.message });                  }
       },

}
