// import multer from "multer";

// //const storage = multer.memoryStorage(); // store files in memory as Buffer
// import path from "path";
// const storage = multer.diskStorage({
//   destination: function (req, file, cb) {
//     cb(null, "uploads/");
//   },
//   filename: function (req, file, cb) {
//     cb(null, Date.now() + "-" + file.originalname);
//   },
// });


// const fileFilter = (req, file, cb) => {
//   if (file.fieldname === "profilePicture") {
//     if (file.mimetype === "image/png") cb(null, true);
//     else cb(new Error("Only .png files are allowed for profile pictures"));

//   }else if (file.fieldname === "cv") {
//   // Accept common PDF MIME types
//   if (
//     file.mimetype === "application/pdf" ||
//     file.mimetype === "application/x-pdf" ||
//     file.mimetype === "application/octet-stream"
//   ) cb(null, true);
//   else cb(new Error("Only .pdf files are allowed for CVs"));
// }

//   else {
//     cb(new Error("Unexpected field"));
//   }
// };


// export const upload = multer({
//   storage,
//   fileFilter,
//   limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max
// });
