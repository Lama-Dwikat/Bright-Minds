import cloudinaryService from "../services/cloudinary.service.js";
import { getKidsQuote } from "../services/kidsQuote.service.js";
import { generateQuoteCardBase64 } from "../services/quoteAi.service.js";

export const kidsQuoteController = {
  // GET /api/kids/quote?withImage=1
  async getQuote(req, res) {
    try {
      const { withImage } = req.query;

      const q = await getKidsQuote();
      const quoteText = q.author ? `${q.text}\n- ${q.author}` : q.text;

      let imageUrl = null;

      if (withImage === "1") {
        const b64 = await generateQuoteCardBase64({ quoteText });
        const buffer = Buffer.from(b64, "base64");

        // ✅ upload to Cloudinary
        imageUrl = await cloudinaryService.uploadBuffer(buffer, "kids-quotes");
      }

      return res.status(200).json({
        success: true,
        quote: q,
        imageUrl, // null or URL
      });
    } catch (e) {
      return res.status(500).json({ success: false, error: e.message });
    }
  },
};
