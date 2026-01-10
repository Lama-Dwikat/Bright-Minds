import OpenAI from "openai";

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

export async function generateTracingBase64(word) {
  const prompt = `
Create a simple black-and-white tracing worksheet image for kids.
Subject: "${word}".
- clean bold outline only
- white background
- thick smooth lines for tracing
- minimal details
`;

  const img = await client.images.generate({
    model: "gpt-image-1.5",
    prompt,
    n: 1,
    size: "1024x1024",
  });

  return img.data[0].b64_json;
}
