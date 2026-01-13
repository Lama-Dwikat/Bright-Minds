import OpenAI from "openai";

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

/**
 * Generate a cute kids-friendly quote-card image (PNG) and return base64 (no data: prefix).
 */
export async function generateQuoteCardBase64({ quoteText }) {
  const prompt =
    `Create a cute, kid-friendly quote card. ` +
    `Pastel colors, simple illustration, no scary elements, clean background. ` +
    `Include this quote text clearly on the image:\n"${quoteText}"\n` +
    `Style: modern, minimal, rounded shapes, playful.`;

  // ✅ OpenAI image generation (base64)
  const result = await openai.images.generate({
    model: "gpt-image-1",
    prompt,
    size: "1024x1024",
  });

  // result.data[0].b64_json contains base64
  const b64 = result?.data?.[0]?.b64_json;
  if (!b64) throw new Error("Failed to generate quote image");

  return b64;
}
