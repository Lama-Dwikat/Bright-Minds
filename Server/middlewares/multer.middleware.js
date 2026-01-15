/*import multer from "multer";

const storage = multer.diskStorage({
  destination: "uploads/",
  filename: (_, file, cb) => {
    cb(null, Date.now() + "-" + file.originalname);
  }
});

export default multer({ storage });
*/

import multer from "multer";
import path from "path";

const storage = multer.diskStorage({
  destination: "uploads/",
  filename: (_, file, cb) => {
    const ext = path.extname(file.originalname || "").toLowerCase();
    const baseName = path.basename(file.originalname || "file", ext); // بدون الامتداد
    cb(null, `${Date.now()}-${baseName}${ext}`);
  },
});

const allowedExt = [".png", ".jpg", ".jpeg", ".webp"];
const allowedMime = ["image/png", "image/jpeg", "image/webp"];

function fileFilter(req, file, cb) {
  const ext = path.extname(file.originalname || "").toLowerCase();
  const mime = (file.mimetype || "").toLowerCase();

  const okByExt = allowedExt.includes(ext);
  const okByMime = allowedMime.includes(mime);

  if (okByExt || okByMime) return cb(null, true);

  cb(new Error("Only image files are allowed"));
}

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 8 * 1024 * 1024 },
});

export default upload;
