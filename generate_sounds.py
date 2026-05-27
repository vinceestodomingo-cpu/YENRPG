import wave
import struct
import math
import random
import os

def write_wav(filename, data, sample_rate=44100):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with wave.open(filename, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(sample_rate)
        for sample in data:
            # clip and pack
            s = max(-32768, min(32767, int(sample * 32767)))
            f.writeframesraw(struct.pack('<h', s))

# 1. UI Click: Short high beep
sr = 44100
dur = 0.05
click_data = []
for i in range(int(sr * dur)):
    t = i / sr
    env = 1.0 - (i / (sr * dur))
    val = math.sin(2 * math.pi * 800 * t) * env * 0.5
    click_data.append(val)
write_wav('Assets/Sounds/click.wav', click_data)

# 2. Sword Swing: Whoosh (filtered noise with fade in/out)
dur = 0.25
swing_data = []
for i in range(int(sr * dur)):
    t = i / sr
    # Envelope: quick attack, slower release
    if t < 0.05:
        env = t / 0.05
    else:
        env = 1.0 - ((t - 0.05) / 0.2)
    # Pitch drop effect + noise
    freq = 600 - (t * 2000)
    if freq < 100: freq = 100
    noise = random.uniform(-1, 1) * 0.5
    val = (math.sin(2 * math.pi * freq * t) * 0.3 + noise) * env * 0.5
    swing_data.append(val)
write_wav('Assets/Sounds/swing.wav', swing_data)

# 3. Hit: Crunchy noise
dur = 0.15
hit_data = []
for i in range(int(sr * dur)):
    t = i / sr
    env = math.exp(-t * 30) # fast decay
    noise = random.uniform(-1, 1)
    val = noise * env * 0.8
    hit_data.append(val)
write_wav('Assets/Sounds/hit.wav', hit_data)

print("Generated sounds in Assets/Sounds/")
