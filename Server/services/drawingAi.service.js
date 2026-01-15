import OpenAI from "openai";

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

export async function generateTracingBase64(word) {
  const prompt = `
Create a simple black-and-white tracing worksheet image for kids.
Subject: "${word}".
Rules:
- clean bold outline only
- white background
- thick smooth lines for tracing
- minimal details
- no shading, no gray, no colors
- no text
`;

  const img = await client.images.generate({
    model: "gpt-image-1.5",
    prompt,
    n: 1,
    size: "1024x1024",
  });

  return img.data[0].b64_json;
}

function commonColorByNumberSpec(subject, regionsCount) {
  return `
Subject: "${subject}"
Target: kids color-by-number worksheet.
Segmentation requirement:
- exactly ${regionsCount} regions
- regions are large and easy for kids
- avoid tiny islands and thin slivers
- keep shapes closed and well-separated
Style:
- simple composition, minimal details
- white background
`;
}

export async function generateColorByNumberOutlineBase64(subject, regionsCount) {
  const prompt = `
${commonColorByNumberSpec(subject, regionsCount)}
Output (OUTLINE + NUMBERS):
- black outlines only
- thick smooth lines
- no shading, no gray, no colors
- put one clear number inside each region
- numbers must be between 1 and ${regionsCount} only
- each region must contain exactly one number
- no other text
- do not add extra regions beyond ${regionsCount}
`;

  const img = await client.images.generate({
    model: "gpt-image-1.5",
    prompt,
    n: 1,
    size: "1024x1024",
  });

  return img.data[0].b64_json;
}

export async function generateColorByNumberMaskBase64(subject, regionsCount) {
  const prompt = `
${commonColorByNumberSpec(subject, regionsCount)}
Output (MASK IMAGE):
- flat solid-color segmentation mask (ID mask)
- no outlines, no numbers, no text
- each region must be filled with a unique solid color
- colors must be highly distinct from each other
- no gradients, no shadows, no texture
- no anti-aliasing on region borders (hard edges)
- background outside all regions must be pure white (#FFFFFF)
- do not add extra regions beyond ${regionsCount}
`;

  const img = await client.images.generate({
    model: "gpt-image-1.5",
    prompt,
    n: 1,
    size: "1024x1024",
  });

  return img.data[0].b64_json;
}
