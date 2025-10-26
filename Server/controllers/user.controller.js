import userService from '../services/user.service.js';
import mongoose from 'mongoose';

export const userController = {

    // Create a new user
    async createUser(req, res) {
        try {
            const user = await userService.createUser(req.body);
            res.status(201).json(user);
        } catch (error) {
            res.status(500).json({ error: error.message });
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



    // Get all users
    async getAllUsers(req, res) {
        try {
            const users = await userService.getAllUsers();
            res.status(200).json(users);
        } catch (error) {
            res.status(500).json({ error: error.message });
        }
    },  
    // Update user by ID
    async updateUser(req, res) {
        try {
            // Prevent updating forbidden fields
         /*   const forbiddenFields = ['password', 'role', '_id', 'createdAt', 'updatedAt'];
            for (const field of forbiddenFields) {
                if (field in req.body) {
                    return res.status(400).json({
                        error: `You are not allowed to update the field: ${field}`
                    });
                }
            }*/
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

     

   // Add more controller methods as needed

}

export default userController;
