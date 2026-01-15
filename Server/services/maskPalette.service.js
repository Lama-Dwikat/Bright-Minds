import axios from "axios";
import sharp from "sharp";

function rgbToHex(r, g, b) {
  const toHex = (x) => x.toString(16).padStart(2, "0");
  return `#${toHex(r)}${toHex(g)}${toHex(b)}`.toUpperCase();
}

function hexToRgb(hex) {
  const h = hex.replace("#", "");
  const r = parseInt(h.slice(0, 2), 16);
  const g = parseInt(h.slice(2, 4), 16);
  const b = parseInt(h.slice(4, 6), 16);
  return { r, g, b };
}

function dist2(a, b) {
  const dr = a.r - b.r;
  const dg = a.g - b.g;
  const db = a.b - b.b;
  return dr * dr + dg * dg + db * db;
}

export async function extractMaskPaletteFromUrl(maskUrl, regionsCount, options = {}) {
  const {
    maxSize = 512,
    whiteThreshold = 245,
    mergeTolerance = 18,
  } = options;

  const resp = await axios.get(maskUrl, { responseType: "arraybuffer" });
  const input = Buffer.from(resp.data);

  const img = sharp(input).ensureAlpha();

  const meta = await img.metadata();
  const w0 = meta.width || 0;
  const h0 = meta.height || 0;

  const scale = Math.min(1, maxSize / Math.max(w0, h0));
  const w = Math.max(1, Math.round(w0 * scale));
  const h = Math.max(1, Math.round(h0 * scale));

  const { data } = await img
    .resize(w, h, { kernel: sharp.kernel.nearest })
    .raw()
    .toBuffer({ resolveWithObject: true });

  const counts = new Map();

  for (let i = 0; i < data.length; i += 4) {
    const r = data[i];
    const g = data[i + 1];
    const b = data[i + 2];
    const a = data[i + 3];

    if (a < 10) continue;
    if (r >= whiteThreshold && g >= whiteThreshold && b >= whiteThreshold) continue;

    const hex = rgbToHex(r, g, b);
    counts.set(hex, (counts.get(hex) || 0) + 1);
  }

  const sorted = [...counts.entries()].sort((a, b) => b[1] - a[1]);

  const merged = [];
  const tol2 = mergeTolerance * mergeTolerance;

  for (const [hex, count] of sorted) {
    const rgb = hexToRgb(hex);

    let placed = false;
    for (const m of merged) {
      if (dist2(rgb, m.rgb) <= tol2) {
        m.count += count;
        placed = true;
        break;
      }
    }

    if (!placed) merged.push({ hex, rgb, count });
    if (merged.length >= regionsCount * 4) break;
  }

  merged.sort((a, b) => b.count - a.count);

  const palette = merged.slice(0, regionsCount).map((m, idx) => ({
    number: idx + 1,
    maskColorHex: m.hex,
  }));

  if (palette.length !== regionsCount) {
    return palette;
  }

  return palette;
}

export function nearestMaskNumber(maskPalette, hex) {
  const t = hexToRgb(hex);
  let best = null;

  for (const p of maskPalette) {
    const c = hexToRgb(p.maskColorHex);
    const d = dist2(t, c);
    if (!best || d < best.d) best = { number: p.number, d };
  }

  return best?.number ?? null;
}
