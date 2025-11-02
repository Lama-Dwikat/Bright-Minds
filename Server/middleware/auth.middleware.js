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

    const decoded = jwt.verify(token, process.env.JWT_SECRET); // ضعي السر في .env

    const user = await User.findById(decoded.id).select("-password");
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    req.user = user;

    next();
  } catch (error) {
    res.status(401).json({ message: "Invalid or expired token" });
  }
   }
};

export default authMiddleware ;