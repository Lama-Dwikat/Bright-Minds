import OpenAI from "openai";

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

export async function generateCopyDrawingBase64(word) {
  const prompt = `
Create a single printable worksheet image for kids, 1024x1024.
Layout:
- White background.
- Put a small reference drawing of "${word}" in the top-left corner only (about 20% of width/height).
- The rest of the page must be blank white space for the child to draw.
Style:
- simple clean line art, black outlines only, no shading, no colors.
- minimal details.
`;

  const img = await client.images.generate({
    model: "gpt-image-1.5",
    prompt,
    n: 1,
    size: "1024x1024",
  });

  return img.data[0].b64_json;
}
