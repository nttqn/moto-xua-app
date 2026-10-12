// Synthesises every sound in the game into assets/audio as 16-bit mono WAV.
// Run from the project root: node tool/gen_audio.js
const fs = require('fs');
const path = require('path');

const RATE = 22050;
const OUT = path.join(__dirname, '..', 'assets', 'audio');
fs.mkdirSync(OUT, { recursive: true });

// Small deterministic noise source so reruns give identical files.
let seed = 12345;
const noise = () => {
  seed = (seed * 1103515245 + 12345) & 0x7fffffff;
  return seed / 0x3fffffff - 1;
};

function write(name, samples, peak = 0.8) {
  let max = 0;
  for (const s of samples) max = Math.max(max, Math.abs(s));
  const gain = max > 0 ? peak / max : 1;
  const data = Buffer.alloc(samples.length * 2);
  samples.forEach((s, i) => data.writeInt16LE(Math.round(s * gain * 32767), i * 2));
  const head = Buffer.alloc(44);
  head.write('RIFF', 0);
  head.writeUInt32LE(36 + data.length, 4);
  head.write('WAVEfmt ', 8);
  head.writeUInt32LE(16, 16);
  head.writeUInt16LE(1, 20);
  head.writeUInt16LE(1, 22);
  head.writeUInt32LE(RATE, 24);
  head.writeUInt32LE(RATE * 2, 28);
  head.writeUInt16LE(2, 32);
  head.writeUInt16LE(16, 34);
  head.write('data', 36);
  head.writeUInt32LE(data.length, 40);
  fs.writeFileSync(path.join(OUT, name), Buffer.concat([head, data]));
  console.log(name, (samples.length / RATE).toFixed(2) + 's');
}

const buf = (seconds) => new Float64Array(Math.round(seconds * RATE));

// One-pole low-pass, in place.
function lowpass(x, cutoff) {
  const a = 1 - Math.exp((-2 * Math.PI * cutoff) / RATE);
  let y = 0;
  for (let i = 0; i < x.length; i++) {
    y += a * (x[i] - y);
    x[i] = y;
  }
  return x;
}

// Single-cylinder four-stroke at idle: one soft thump per firing, 26 of
// them in exactly one second so the file loops without a click. The game
// changes the playback rate to rev it.
function engine() {
  const x = buf(1);
  const fires = 26;
  const period = x.length / fires;
  const rasp = lowpass(Float64Array.from(buf(1), noise), 1800);
  for (let i = 0; i < x.length; i++) {
    const phase = (i % period) / period;
    const t = phase * (period / RATE);
    const thump = Math.exp(-phase * 7);
    x[i] =
      thump * (Math.sin(2 * Math.PI * 82 * t) + 0.55 * Math.sin(2 * Math.PI * 164 * t + 0.4)) +
      thump * thump * 0.5 * rasp[i] +
      0.08 * Math.sin((2 * Math.PI * 52 * i) / RATE);
  }
  for (let i = 0; i < x.length; i++) x[i] = Math.tanh(x[i] * 1.6);
  write('engine.wav', x, 0.6);
}

function crash() {
  const x = buf(0.9);
  const hiss = lowpass(Float64Array.from(x, noise), 2600);
  for (let i = 0; i < x.length; i++) {
    const t = i / RATE;
    const clang =
      Math.sin(2 * Math.PI * 523 * t) + Math.sin(2 * Math.PI * 811 * t) + Math.sin(2 * Math.PI * 1367 * t);
    x[i] =
      hiss[i] * Math.exp(-t * 6) * 1.4 +
      clang * Math.exp(-t * 14) * 0.35 +
      Math.sin(2 * Math.PI * 70 * t) * Math.exp(-t * 18);
    // Scrape along the tarmac afterwards.
    if (t > 0.15) x[i] += hiss[i] * 0.5 * Math.exp(-(t - 0.15) * 5) * (0.6 + 0.4 * Math.sin(t * 90));
  }
  write('crash.wav', x, 0.85);
}

function whoosh() {
  const x = buf(0.32);
  const air = Float64Array.from(x, noise);
  let y = 0;
  for (let i = 0; i < x.length; i++) {
    const t = i / x.length;
    const cutoff = 500 + 3200 * Math.sin(Math.PI * t);
    const a = 1 - Math.exp((-2 * Math.PI * cutoff) / RATE);
    y += a * (air[i] - y);
    x[i] = y * Math.sin(Math.PI * t) ** 2;
  }
  write('whoosh.wav', x, 0.7);
}

function tone(name, notes, peak = 0.6) {
  // notes: [frequency, start seconds, length seconds]
  const end = Math.max(...notes.map((n) => n[1] + n[2]));
  const x = buf(end + 0.05);
  for (const [f, start, len] of notes) {
    const from = Math.round(start * RATE);
    const count = Math.round(len * RATE);
    for (let i = 0; i < count && from + i < x.length; i++) {
      const t = i / RATE;
      const env = Math.min(1, t * 200) * Math.exp((-t * 4) / len);
      x[from + i] += env * (Math.sin(2 * Math.PI * f * t) + 0.3 * Math.sin(4 * Math.PI * f * t));
    }
  }
  write(name, x, peak);
}

function bump() {
  const x = buf(0.16);
  for (let i = 0; i < x.length; i++) {
    const t = i / RATE;
    x[i] = Math.sin(2 * Math.PI * (130 - 300 * t) * t) * Math.exp(-t * 28) + noise() * 0.2 * Math.exp(-t * 60);
  }
  write('bump.wav', x, 0.7);
}

engine();
crash();
whoosh();
bump();
tone('beep.wav', [[660, 0, 0.16]]);
tone('go.wav', [[990, 0, 0.45]]);
// Pentatonic runs: up for a win, down for a flop.
tone('win.wav', [[523, 0, 0.18], [587, 0.14, 0.18], [698, 0.28, 0.18], [784, 0.42, 0.18], [1047, 0.56, 0.6]]);
tone('fail.wav', [[392, 0, 0.25], [330, 0.22, 0.25], [262, 0.44, 0.6]]);
tone('click.wav', [[880, 0, 0.06]], 0.4);
tone('coin.wav', [[1175, 0, 0.08], [1568, 0.07, 0.25]], 0.5);
