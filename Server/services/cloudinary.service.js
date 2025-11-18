import dotenv from "dotenv";
dotenv.config();  //  import cloudinary
import { v2 as cloudinary } from "cloudinary";
import streamifier from "streamifier";

console.log("LOADED FROM SERVICE:");
console.log("CLOUD NAME:", process.env.CLOUDINARY_CLOUD_NAME);
console.log("API KEY:", process.env.CLOUDINARY_API_KEY);
console.log("API SECRET:", process.env.CLOUDINARY_API_SECRET);

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

const cloudinaryService = {
  uploadBuffer(buffer, folder = "stories") {
    return new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        { folder },
        (error, result) => {
          if (error) {
            console.error("Cloudinary ERROR:", error);
            return reject(error);
          }
          resolve(result.secure_url);
        }
      );
      streamifier.createReadStream(buffer).pipe(stream);
    });
  },

  async uploadFile(filePath, folder = "stories") {
    const result = await cloudinary.uploader.upload(filePath, { folder });
    return result.secure_url;
  },
};

export default cloudinaryService;
