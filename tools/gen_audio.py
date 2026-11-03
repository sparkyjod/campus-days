#!/usr/bin/env python3
"""Phase 5: generate all Campus Days audio procedurally (no downloads, no
licences to track — pure synthesis, CC0 by construction). Outputs 16-bit
mono 22050 Hz WAVs into ../assets/audio/:
  ambient_loop.wav — soft wind/birdsong bed (filtered noise + chirps)
  music_loop.wav   — gentle chord-pad loop (I–V–vi–IV, sine/triangle)
  ui_click.wav     — short UI blip
  phone_buzz.wav   — two-tone notification buzz
  footstep.wav     — soft thud
  bell.wav         — campus bell (struck sine partials, decays)
Deterministic (fixed seed) so re-runs reproduce identical files.
"""
import math
import random
import struct
import wave
import os

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
os.makedirs(OUT, exist_ok=True)
rng = random.Random(20261103)


def write_wav(name, samples):
    peak = max(1e-6, max(abs(s) for s in samples))
    scale = 0.9 / peak
    frames = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s * scale)) * 32767))
                      for s in samples)
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(frames)
    print(name, len(samples), "samples (%.1fs)" % (len(samples) / SR))


def ambient():
    dur = 30.0
    n = int(SR * dur)
    out = [0.0] * n
    # wind: slowly varying filtered noise (moving average over noise)
    noise = [rng.uniform(-1, 1) for _ in range(n)]
    win = 0.0
    for i, v in enumerate(noise):
        win += 0.002 * (v - win)
        out[i] += win * 0.35 * (0.7 + 0.3 * math.sin(2 * math.pi * i / (SR * 7.0)))
    # birdsong chirps: random short sine sweeps
    t = 0.5
    while t < dur - 0.5:
        f0 = rng.uniform(2200, 3400)
        f1 = f0 * rng.uniform(0.7, 1.4)
        d = rng.uniform(0.08, 0.22)
        amp = rng.uniform(0.05, 0.14)
        start = int(t * SR)
        for i in range(int(d * SR)):
            if start + i >= n:
                break
            ph = 2 * math.pi * (f0 * i / SR + (f1 - f0) * i * i / (2 * SR * d * SR))
            env = math.sin(math.pi * i / (d * SR))
            out[start + i] += amp * env * math.sin(ph)
        t += rng.uniform(0.7, 2.4)
    # distant chatter murmur: band-limited noise bursts, very low
    t = 1.0
    while t < dur - 1.0:
        d = rng.uniform(0.4, 1.2)
        start = int(t * SR)
        base = rng.uniform(300, 600)
        for i in range(int(d * SR)):
            if start + i >= n:
                break
            out[start + i] += 0.03 * math.sin(2 * math.pi * base * i / SR) * rng.uniform(0.4, 1.0)
        t += rng.uniform(1.5, 4.0)
    write_wav("ambient_loop.wav", out)


def music():
    # 4 chords x 8s = 32s pad loop, root + fifth + third partials, soft attack
    chords = [(261.63, 329.63, 392.00), (196.00, 246.94, 293.66),
              (220.00, 261.63, 329.63), (174.61, 220.00, 261.63)]
    out = []
    for ci, (r, third, fifth) in enumerate(chords):
        for i in range(int(SR * 8.0)):
            t = i / SR
            env = min(1.0, t / 0.6) * (1.0 if t < 7.0 else max(0.0, (8.0 - t)))
            s = (math.sin(2 * math.pi * r * t) * 0.5
                 + math.sin(2 * math.pi * third * t) * 0.35
                 + math.sin(2 * math.pi * fifth * t) * 0.35
                 + math.sin(2 * math.pi * r * 2 * t) * 0.08)
            out.append(s * 0.22 * env)
    write_wav("music_loop.wav", out)


def blip(name, freq, dur, amp=0.5, kind="sine"):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        env = (1.0 - t / dur)
        if kind == "sine":
            out.append(amp * env * math.sin(2 * math.pi * freq * t))
        else:
            out.append(amp * env * (1.0 if math.sin(2 * math.pi * freq * t) > 0 else -1.0) * 0.5)
    write_wav(name, out)


def buzz():
    out = []
    for rep in range(2):
        for i in range(int(SR * 0.16)):
            t = i / SR
            out.append(0.35 * math.sin(2 * math.pi * 180 * t) * (1.0 - t / 0.16))
        out.extend([0.0] * int(SR * 0.10))
    write_wav("phone_buzz.wav", out)


def footstep():
    n = int(SR * 0.12)
    out = []
    for i in range(n):
        t = i / SR
        out.append(0.6 * (1.0 - t / 0.12) ** 2 * rng.uniform(-1, 1) * math.exp(-t * 30))
    write_wav("footstep.wav", out)


def bell():
    n = int(SR * 2.5)
    out = []
    for i in range(n):
        t = i / SR
        s = (math.sin(2 * math.pi * 660 * t) * 0.5
             + math.sin(2 * math.pi * 990 * t) * 0.25
             + math.sin(2 * math.pi * 1320 * t) * 0.12)
        out.append(s * math.exp(-t * 1.4))
    write_wav("bell.wav", out)


ambient()
music()
blip("ui_click.wav", 880, 0.07)
buzz()
footstep()
bell()
print("done ->", OUT)
