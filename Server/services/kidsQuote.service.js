import axios from "axios";

const fallbackQuotes = [
  { text: "Be kind. It makes the world brighter! 🌸", author: "" },
  { text: "Try again — you get better every time! 💪", author: "" },
  { text: "Small steps every day make big dreams! ⭐", author: "" },
  { text: "Sharing is caring! 🤝", author: "" },
];

function kidFriendly(text) {
  const bad = ["death", "kill", "hate", "war", "violence"];
  const lower = (text || "").toLowerCase();
  if (!text) return null;
  if (bad.some((w) => lower.includes(w))) return null;
  if (text.length > 120) return text.slice(0, 118) + "…";
  return text;
}

export async function getKidsQuote() {
  try {
    // ZenQuotes random
    const resp = await axios.get("https://zenquotes.io/api/random");
    const q = resp.data?.[0];

    const text = kidFriendly(q?.q);
    if (!text) throw new Error("Not kid friendly");

    return { text, author: q?.a || "" };
  } catch (_) {
    return fallbackQuotes[Math.floor(Math.random() * fallbackQuotes.length)];
  }
}
