import jwt from "jsonwebtoken";
import User from "../models/user.model.js"; 

export  const authMiddleware = {

    async authentication (req , res,next){
  try {
   
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ message: "Access denied. No token provided." });
    }

    const token = authHeader.split(" ")[1];

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
      if (!decoded || !decoded.id) {
        return res.status(401).json({ message: "Invalid token structure." });
      }
    //const user = await User.findById(decoded.id).select("-password");
    const user = await User.findById(decoded.id).select("_id name email role");

    
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    req.user = user;

    next();
  } catch (error) {
    console.error("Auth Error:", error.message);
      res.status(401).json({ message: "Invalid or expired token." });
  }
   }
};

export default authMiddleware ;