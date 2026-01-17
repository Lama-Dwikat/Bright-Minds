import mongoose from "mongoose";
import dotenv from "dotenv";
dotenv.config();

import ChallengeTemplate from "../models/challengeTemplate.model.js";

const challengeTemplates = [
  { title: "Morning Adhkar", category: "religious", sticker: "🌅" },
  { title: "Evening Adhkar", category: "religious", sticker: "🌙" },
  { title: "Say Alhamdulillah 20 times", category: "religious", sticker: "🤲" },
  { title: "Say SubhanAllah 20 times", category: "religious", sticker: "✨" },
  { title: "Send Salawat 20 times", category: "religious", sticker: "🕊️" },

  { title: "Read a short story (10 minutes)", category: "reading", sticker: "📖" },
  { title: "Read 2 pages from a book", category: "reading", sticker: "📚" },
  { title: "Learn 3 new words", category: "reading", sticker: "📝" },
  { title: "Tell your parent what you learned today", category: "reading", sticker: "🗣️" },

  { title: "Drink 5 cups of water", category: "health", sticker: "💧" },
  { title: "Brush your teeth twice", category: "health", sticker: "🪥" },
  { title: "Eat one fruit today", category: "health", sticker: "🍎" },
  { title: "Sleep early (before 10 PM)", category: "health", sticker: "😴" },

  { title: "Walk for 10 minutes", category: "sport", sticker: "🚶" },
  { title: "Do 10 jumping jacks", category: "sport", sticker: "🤸" },
  { title: "Stretch for 3 minutes", category: "sport", sticker: "🧘" },
  { title: "Dance for 5 minutes", category: "sport", sticker: "💃" },

  { title: "Say 'Thank you' 3 times", category: "behavior", sticker: "🙏" },
  { title: "Help at home (one small task)", category: "behavior", sticker: "🏠" },
  { title: "Be kind to someone today", category: "behavior", sticker: "❤️" },
  { title: "Share a toy or help a friend", category: "behavior", sticker: "🤝" },

  { title: "Draw how you feel today", category: "art", sticker: "🎨" },
  { title: "Color one picture", category: "art", sticker: "🖍️" },
  { title: "Draw your favorite thing", category: "art", sticker: "✏️" },
  { title: "Create a simple craft (with parent)", category: "art", sticker: "✂️" },

  { title: "Clean your room for 5 minutes", category: "nature", sticker: "🧹" },
  { title: "Keep your space tidy today", category: "nature", sticker: "🧺" },
  { title: "Water a plant (if you have one)", category: "nature", sticker: "🪴" },
  { title: "Throw trash in the bin", category: "nature", sticker: "🗑️" },
];

async function run() {
  try {
    await mongoose.connect(process.env.MONGO_URI);

    for (const t of challengeTemplates) {
      await ChallengeTemplate.updateOne(
        { title: t.title, category: t.category },
        { $set: t }, // ✅ update existing + insert if not exist
        { upsert: true }
      );
    }

    console.log("✅ Challenge Templates seeded successfully WITH stickers");
    process.exit(0);
  } catch (e) {
    console.error("❌ Seed error:", e);
    process.exit(1);
  }
}

run();
