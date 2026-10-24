#!/usr/bin/env python3
"""Geometric iOS AppIcon for CurrencyConverter (1024x1024)."""
from PIL import Image, ImageDraw, ImageFont
import math
import os

S = 1024
img = Image.new("RGB", (S, S), "#4FAD8D")
draw = ImageDraw.Draw(img)

# soft radial lift toward center
for r in range(720, 0, -12):
    t = r / 720.0
    # lerp between center lift and base
    c0 = (0x7A, 0xD0, 0xB2)
    c1 = (0x4F, 0xAD, 0x8D)
    col = tuple(int(c0[i] * (1 - t) + c1[i] * t) for i in range(3))
    draw.ellipse([S/2 - r, S/2 - r, S/2 + r, S/2 + r], fill=col)

def circle_ellipse(cx, cy, rad):
    return [cx - rad, cy - rad, cx + rad, cy + rad]

# ---- exchange arrows (circular loop) ----
cx = cy = S / 2
R = 360
stroke = 36
mint = "#A8DEC8"

# two thick arcs with arrowheads (top arc L->R, bottom arc R->L)
def draw_arc_arrow(bbox, start, end, width, fill, head_at_end=True):
    # draw arc as many small segments for PIL
    x0, y0, x1, y1 = bbox
    a0 = math.radians(start)
    a1 = math.radians(end)
    steps = 80
    pts = []
    for i in range(steps + 1):
        t = i / steps
        ang = a0 + (a1 - a0) * t
        pts.append(((x0 + x1) / 2 + (x1 - x0) / 2 * math.cos(ang),
                    (y0 + y1) / 2 + (y1 - y0) / 2 * math.sin(ang)))
    draw.line(pts, fill=fill, width=width)

    # arrowhead at end
    tip_ang = a1 if head_at_end else a0
    tip = pts[-1] if head_at_end else pts[0]
    # tangent direction
    if head_at_end:
        dx = pts[-1][0] - pts[-2][0]
        dy = pts[-1][1] - pts[-2][1]
    else:
        dx = pts[0][0] - pts[1][0]
        dy = pts[0][1] - pts[1][1]
    L = math.hypot(dx, dy) or 1
    dx, dy = dx / L, dy / L
    # perpendicular
    px, py = -dy, dx
    head = 72
    back = 52
    p1 = tip
    p2 = (tip[0] - dx * back + px * head, tip[1] - dy * back + py * head)
    p3 = (tip[0] - dx * back - px * head, tip[1] - dy * back - py * head)
    draw.polygon([p1, p2, p3], fill=fill)

arrow_box = circle_ellipse(cx, cy, R)
# top arc: 200° -> 340° (left to right along top), head at end (right)
draw_arc_arrow(arrow_box, 200, 340, stroke, mint, head_at_end=True)
# bottom arc: 20° -> 160° (right to left along bottom), head at end (left)
draw_arc_arrow(arrow_box, 20, 160, stroke, mint, head_at_end=True)

# ---- two coins ----
coin_r = 200
# left coin (CNY) and right coin (USD)
lx, ly = S/2 - 130, S/2 - 10
rx, ry = S/2 + 130, S/2 + 10
cream_outer = "#E8C878"
cream_fill = "#F4E4BC"
cream_inner = "#E8C878"

def draw_coin(cx, cy, rad):
    # outer
    draw.ellipse(circle_ellipse(cx, cy, rad), fill=cream_outer)
    # face
    draw.ellipse(circle_ellipse(cx, cy, rad - 18), fill=cream_fill)
    # inner ring
    draw.ellipse(circle_ellipse(cx, cy, rad - 42), outline=cream_inner, width=10)

draw_coin(lx, ly, coin_r)
draw_coin(rx, ry, coin_r)

# ---- currency glyphs ----
font_path = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
if not os.path.exists(font_path):
    font_path = "/System/Library/Fonts/Helvetica.ttc"
font = ImageFont.truetype(font_path, 220)

def draw_symbol(cx, cy, text, color="#1F7A5C"):
    bbox = draw.textbbox((0, 0), text, font=font)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    x = cx - w / 2 - bbox[0]
    y = cy - h / 2 - bbox[1]
    draw.text((x, y), text, font=font, fill=color)

draw_symbol(lx, ly, "¥", "#1F7A5C")
draw_symbol(rx, ry, "$", "#1F7A5C")

# save
out = "/Users/mr.zhang/XiaomiMiMoProjects/CurrencyConverter/CurrencyConverter/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
img.save(out, "PNG")
print("wrote", out, img.size)

# also save a session preview copy
preview = "/Users/mr.zhang/XiaomiMiMoProjects/CurrencyConverter/scripts/AppIcon-preview.png"
img.save(preview, "PNG")
print("preview", preview)
