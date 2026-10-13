// Synthesises the menu theme into assets/audio/menu.wav: a slow bolero in
// A minor, the rhythm of old Vietnamese "nhạc vàng", with a plucked guitar,
// a sliding monochord-like lead and the crackle of a worn record. It loops
// seamlessly: note tails and the echo wrap round the end of the buffer.
//
// Run from the project root: node tool/gen_music.js
const fs = require('fs');
const path = require('path');

const SR = 22050;
const BEAT = 0.75; // seconds: 80 bpm
const BARS = 16;
const LEN = Math.round(BARS * 4 * BEAT * SR);
const mix = new Float64Array(LEN);

// Deterministic noise so every run produces the same file.
let seed = 19750430;
const rand = () => {
  seed = (seed + 0x6d2b79f5) | 0;
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};

const NOTE = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 };
const hz = (name) => {
  const sharp = name[1] === '#';
  const semis = NOTE[name[0]] + (sharp ? 1 : 0) + 12 * (Number(name.slice(sharp ? 2 : 1)) + 1);
  return 440 * 2 ** ((semis - 69) / 12);
};

const put = (i, v) => {
  mix[((i % LEN) + LEN) % LEN] += v;
};

/** Plucked nylon string (Karplus-Strong). */
function pluck(freq, start, dur, amp) {
  const n = Math.max(2, Math.round(SR / freq));
  const line = new Float64Array(n);
  let prev = 0;
  for (let i = 0; i < n; i++) {
    // Low-passed noise burst: a soft thumb rather than a pick.
    prev = prev * 0.55 + (rand() * 2 - 1) * 0.45;
    line[i] = prev;
  }
  const from = Math.round(start * SR);
  const count = Math.round(dur * SR);
  let k = 0;
  for (let i = 0; i < count; i++) {
    const next = (k + 1) % n;
    const out = line[k];
    line[k] = (line[k] + line[next]) * 0.4975;
    k = next;
    const fade = Math.min(1, (count - i) / (0.05 * SR));
    put(from + i, out * amp * fade);
  }
}

/**
 * The lead: one long bowed-sounding line that slides from note to note and
 * wavers once it has settled, in the manner of a đàn bầu.
 * notes: [name, beats] in order from `start` beats; null name = rest.
 */
function lead(notes, startBeat, amp) {
  let beat = startBeat;
  let phase = 0;
  let freq = null;
  let level = 0;
  for (const [name, beats] of notes) {
    const from = Math.round(beat * BEAT * SR);
    const count = Math.round(beats * BEAT * SR);
    const target = name ? hz(name) : null;
    if (freq === null && target) freq = target * 0.94; // scoop up into the first note
    for (let i = 0; i < count; i++) {
      const t = i / SR;
      if (target) {
        freq += (target - freq) * (1 - Math.exp(-1 / (0.045 * SR)));
        level += (1 - level) * (1 - Math.exp(-1 / (0.03 * SR)));
      } else {
        level += (0 - level) * (1 - Math.exp(-1 / (0.08 * SR)));
      }
      // Vibrato only blooms after the note has been held a moment.
      const bloom = Math.min(1, Math.max(0, (t - 0.22) / 0.35));
      const f = freq * (1 + 0.011 * bloom * Math.sin(2 * Math.PI * 5.4 * t));
      phase += (2 * Math.PI * f) / SR;
      // Ease off toward the end of each note so phrases breathe.
      const swell = 0.75 + 0.25 * Math.sin((Math.PI * i) / count);
      const tone =
        Math.sin(phase) + 0.42 * Math.sin(2 * phase + 0.3) + 0.2 * Math.sin(3 * phase) + 0.08 * Math.sin(5 * phase);
      put(from + i, tone * amp * level * swell);
    }
    beat += beats;
    if (!target) freq = null;
  }
}

/** A dry tick: brushed shaker on the offbeats, wood block on the accents. */
function tick(start, amp, bright) {
  const from = Math.round(start * SR);
  const count = Math.round(0.06 * SR);
  let lp = 0;
  for (let i = 0; i < count; i++) {
    const t = i / SR;
    const n = rand() * 2 - 1;
    lp += (n - lp) * (bright ? 0.9 : 0.35);
    const wood = bright ? 0 : Math.sin(2 * Math.PI * 760 * t) * 0.8;
    put(from + i, (n - lp * (bright ? 0.6 : 0) + wood) * amp * Math.exp(-t * (bright ? 70 : 55)));
  }
}

// Am Dm G C | F Dm E7 Am, played twice.
const CHORDS = {
  Am: ['A2', 'E3', 'A3', 'C4', 'E4'],
  Dm: ['D3', 'A3', 'D4', 'F4', 'A4'],
  G: ['G2', 'D3', 'G3', 'B3', 'D4'],
  C: ['C3', 'G3', 'C4', 'E4', 'G4'],
  F: ['F2', 'C3', 'F3', 'A3', 'C4'],
  E7: ['E2', 'B2', 'E3', 'G#3', 'D4'],
};
const PROGRESSION = ['Am', 'Dm', 'G', 'C', 'F', 'Dm', 'E7', 'Am'];

for (let bar = 0; bar < BARS; bar++) {
  const c = CHORDS[PROGRESSION[bar % 8]];
  const t0 = bar * 4 * BEAT;
  const at = (beats) => t0 + beats * BEAT + (rand() - 0.5) * 0.012; // a human hand
  // Bolero: bass on one and three, the chord rolled in between.
  pluck(hz(c[0]), at(0), 2.2, 0.55);
  pluck(hz(c[1]), at(2), 1.8, 0.42);
  const roll = [
    [0.5, 2], [1, 3], [1.5, 4], [2.5, 3], [3, 2], [3.5, 3],
  ];
  for (const [beats, string] of roll) {
    pluck(hz(c[string]), at(beats), 1.4, beats === 1.5 ? 0.3 : 0.24);
  }
  // Shaker on every eighth, wood block answering on two-and and four.
  for (let e = 0; e < 8; e++) tick(t0 + e * BEAT * 0.5, e % 2 ? 0.05 : 0.03, true);
  tick(t0 + 1.5 * BEAT, 0.07, false);
  tick(t0 + 3 * BEAT, 0.09, false);
}

// The tune: eight bars low and plain, eight bars higher and fuller.
lead(
  [
    ['E4', 1.5], ['A4', 0.5], ['C5', 2],
    ['D5', 1.5], ['C5', 0.5], ['A4', 2],
    ['G4', 1], ['A4', 1], ['B4', 2],
    ['C5', 3], ['E5', 1],
    ['A4', 1.5], ['C5', 0.5], ['D5', 1], ['C5', 1],
    ['A4', 1], ['F4', 1], ['D4', 2],
    ['E4', 1], ['G#4', 1], ['B4', 1], ['D5', 1],
    ['C5', 1], ['A4', 2.5], [null, 0.5],
    ['E5', 2], ['D5', 1], ['C5', 1],
    ['D5', 1.5], ['F5', 0.5], ['E5', 1], ['D5', 1],
    ['D5', 2], ['B4', 1], ['G4', 1],
    ['C5', 1], ['E5', 1], ['G5', 2],
    ['A5', 1.5], ['G5', 0.5], ['F5', 1], ['E5', 1],
    ['D5', 2], ['F5', 1], ['D5', 1],
    ['E5', 1.5], ['D5', 0.5], ['B4', 1], ['G#4', 1],
    ['A4', 3.5], [null, 0.5],
  ],
  0,
  0.2,
);

// Echo standing in for a small tiled room, wrapped so the loop is seamless.
const wet = new Float64Array(LEN);
for (const [delay, gain] of [[0.089, 0.28], [0.137, 0.22], [0.211, 0.16], [0.353, 0.1]]) {
  const d = Math.round(delay * SR);
  for (let i = 0; i < LEN; i++) wet[i] += mix[(i - d + LEN) % LEN] * gain;
}
let damp = 0;
for (let i = 0; i < LEN; i++) {
  damp += (wet[i] - damp) * 0.35;
  mix[i] += damp;
}

// An old record: rolled-off top, a slow wobble in level, dust in the groove.
let lp = 0;
for (let i = 0; i < LEN; i++) {
  lp += (mix[i] - lp) * 0.62;
  const wobble = 1 + 0.03 * Math.sin((2 * Math.PI * 4 * i) / LEN);
  mix[i] = lp * wobble;
}
let peak = 0;
for (let i = 0; i < LEN; i++) peak = Math.max(peak, Math.abs(mix[i]));
for (let i = 0; i < LEN; i++) mix[i] = (mix[i] / peak) * 0.62;
for (let i = 0; i < LEN; i++) {
  mix[i] += (rand() * 2 - 1) * 0.004;
  if (rand() < 0.00035) {
    const pop = (rand() * 2 - 1) * (0.03 + rand() * 0.05);
    for (let k = 0; k < 14; k++) mix[(i + k) % LEN] += pop * Math.exp(-k / 3);
  }
}

const data = Buffer.alloc(LEN * 2);
let sum = 0;
let clip = 0;
for (let i = 0; i < LEN; i++) {
  const v = Math.max(-1, Math.min(1, mix[i]));
  if (Math.abs(mix[i]) > 1) clip++;
  sum += v * v;
  data.writeInt16LE(Math.round(v * 32767), i * 2);
}
const head = Buffer.alloc(44);
head.write('RIFF', 0);
head.writeUInt32LE(36 + data.length, 4);
head.write('WAVEfmt ', 8);
head.writeUInt32LE(16, 16);
head.writeUInt16LE(1, 20);
head.writeUInt16LE(1, 22);
head.writeUInt32LE(SR, 24);
head.writeUInt32LE(SR * 2, 28);
head.writeUInt16LE(2, 32);
head.writeUInt16LE(16, 34);
head.write('data', 36);
head.writeUInt32LE(data.length, 40);
const out = path.join(__dirname, '..', 'assets', 'audio', 'menu.wav');
fs.writeFileSync(out, Buffer.concat([head, data]));
console.log(
  `menu.wav ${(LEN / SR).toFixed(1)}s, ${(data.length / 1e6).toFixed(2)} MB, ` +
    `rms ${(20 * Math.log10(Math.sqrt(sum / LEN))).toFixed(1)} dB, clipped ${clip}`,
);
