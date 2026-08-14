#!/usr/bin/env python3
"""Generate Rizzr OG share card (1200x630) on Midnight Aura brand."""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math, os

OUT = os.path.expanduser("~/projects/rizzr/frontend/assets/img/og-card.png")
W, H = 1200, 630
BG = "#050508"
CORAL = (255, 51, 102)     # #FF3366
VIOLET = (112, 0, 255)     # #7000FF
WHITE = (255, 255, 255, 255)
MUTED = (200, 180, 200, 255)

img = Image.new("RGB", (W, H), BG)
draw = ImageDraw.Draw(img, "RGBA")

# --- ambient orbs (soft coral upper-left, violet bottom-right) ---
def orb(cx, cy, radius, color, alpha=110):
    layer = Image.new("RGBA", (W, H), (0,0,0,0))
    d = ImageDraw.Draw(layer)
    for r in range(radius, 0, -3):
        a = int(alpha * (1 - r/radius))
        d.ellipse([cx-r, cy-r, cx+r, cy+r], fill=color + (a,))
    layer = layer.filter(ImageFilter.GaussianBlur(40))
    img.paste(layer, (0,0), layer)

orb(-150, 60, 520, CORAL, 95)      # top-left coral
orb(W+120, H-80, 560, VIOLET, 110) # bottom-right violet
orb(W/2, -200, 380, VIOLET, 60)

# --- subtle gradient band behind headline area ---
for y in range(H):
    t = y / H
    g = (
        int(12 + 20*t),
        int(6 + 10*t),
        int(14 + 22*t),
        0,
    )
    draw.line([(0, y), (W, y)], fill=(g[0], g[1], g[2], 255))

# --- top-left wordmark: mic emblem + "Rizzr" ---
MIC_COLOR = (255, 60, 110, 255)
def padded_font(size, path):
    return ImageFont.truetype(path, size)

font_hl = None
for p in ["/System/Library/Fonts/Supplemental/Arial Bold.ttf",
          "/Library/Fonts/Arial Bold.ttf",
          "/System/Library/Fonts/Helvetica.ttc",
          "/System/Library/Fonts/Supplemental/Arial.ttf"]:
    try:
        font_hl = padded_font(84, p)
        break
    except Exception:
        continue
font_sl = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 40)
if not font_hl:
    font_hl = ImageFont.load_default()

# wordmark at top-left (mic drawn inline next to text)
def draw_mic(cx, cy, s, col):
    d = ImageDraw.Draw(img, "RGBA")
    stroke = max(3, int(s*0.06))
    d.ellipse([cx-s, cy-s, cx+s, cy+s], fill=(255,255,255,30))  # soft tile
    # capsule body
    d.rounded_rectangle([cx-s*0.32, cy-s*0.78, cx+s*0.32, cy+s*0.22],
                        radius=s*0.32, outline=col, width=stroke)
    # cradle
    d.arc([cx-s*0.55, cy-s*0.25, cx+s*0.55, cy+s*0.55], 180, 360, fill=col, width=stroke)
    # stand
    d.line([cx, cy+s*0.45, cx, cy+s*0.72], fill=col, width=stroke)

draw_mic(70, 66, 34, MIC_COLOR)
draw.text((120, 24), "Rizzr", font=font_hl, fill=WHITE)

# --- tagline ---
tag = "Got a voice note? Rizzr it."
draw.text((120, 128), tag, font=font_sl, fill=MUTED)

# --- big headline ---
headline = "Perfect replies,\nzero panic."
lh = 100
y0 = 250
draw.multiline_text((120, y0), headline, font=font_hl, fill=WHITE, spacing=8)

# --- subline ---
sub = "Send a voice note. Rizzr writes 3 confident replies back — in seconds."
sub_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 34)
draw.text((120, y0+230), sub, font=sub_font, fill=MUTED)

# --- bottom gradient accent bar + "rizzr.com" ---
for x in range(W):
    t = x / W
    c = (int(255*(1-t)+112*t), int(51*(1-t)+0*t), int(102*(1-t)+255*t), 255)
    draw.line([(x, H-6), (x, H)], fill=c)

mono = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 30)
draw.text((120, H-70), "rizzr.com", font=mono, fill=(150,150,160,255))

# --- decorate right side with a subtle mic glyph watermark ---
draw_mic(W-150, 280, 96, (255,255,255, 20))

img = img.convert("RGB")
img.save(OUT, "PNG")
print("saved", OUT, img.size)
