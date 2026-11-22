"""Primitives de generation d'images pour le blog (Pillow).

Style commun avec le site : fond slate tres fonce, accent orange, cartes
arrondies, typographie Segoe UI. Les images sont rendues en 2x puis reduites
(LANCZOS) pour un rendu net.

Exemple d'utilisation :

    import sys
    sys.path.insert(0, "scripts")
    from blog_images import make_cover, make_figure

    make_cover(
        "tmp/blog/mon-slug/cover.webp",
        label="DEVOPS  ·  ELIXIR",
        title_lines=["Livrer Phoenix", "sans downtime"],
        subtitle_lines=["Retour d'experience sur un deploiement"],
        meta="Hermann GOLO  ·  retour d'experience",
    )

    make_figure(
        "tmp/blog/mon-slug/figure.webp",
        label="ARCHITECTURE",
        title_lines=["Trois composants,", "un seul contrat"],
        subtitle="Le chemin d'une requete en production.",
        cards=[("01", "Edge", "TLS, cache, routage"), ("02", "Application", "BEAM, sessions")],
    )
"""

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONT_DIR = r"C:\Windows\Fonts"
F_BOLD = os.path.join(FONT_DIR, "segoeuib.ttf")
F_REG = os.path.join(FONT_DIR, "segoeui.ttf")

BG_TOP = (8, 13, 26)
BG_BOT = (17, 25, 43)
CARD = (24, 33, 52)
CARD2 = (19, 27, 44)
BORDER = (56, 71, 96)
WHITE = (248, 250, 252)
MUTED = (156, 172, 194)
ORANGE = (249, 115, 22)
ORANGE_LIGHT = (253, 186, 116)
ORANGE_DARK = (154, 52, 18)

SCALE = 2


def s(value):
    return int(round(value * SCALE))


def font(path, size):
    return ImageFont.truetype(path, s(size))


def gradient_bg(width, height):
    top = np.array(BG_TOP, dtype=np.float64)
    bot = np.array(BG_BOT, dtype=np.float64)
    t = np.linspace(0.0, 1.0, height).reshape(height, 1, 1)
    arr = top.reshape(1, 1, 3) * (1 - t) + bot.reshape(1, 1, 3) * t
    return Image.fromarray(np.uint8(np.repeat(arr, width, axis=1)), "RGB")


def add_glow(img, center, radius, color=ORANGE, alpha=80):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x, y = center
    for i in range(6, 0, -1):
        r = int(radius * i / 6)
        a = max(int(alpha * (1 - i / 7)), 0)
        d.ellipse([x - r, y - r, x + r, y + r], fill=color + (a,))
    layer = layer.filter(ImageFilter.GaussianBlur(max(1, radius // 5)))
    base = img.convert("RGBA")
    base.alpha_composite(layer)
    return base.convert("RGB")


def add_grid(img, step=100):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for x in range(0, img.size[0], s(step)):
        d.line([(x, 0), (x, img.size[1])], fill=(148, 163, 184, 13), width=1)
    for y in range(0, img.size[1], s(step)):
        d.line([(0, y), (img.size[0], y)], fill=(148, 163, 184, 13), width=1)
    base = img.convert("RGBA")
    base.alpha_composite(layer)
    return base.convert("RGB")


def wrap(draw, text, fnt, max_width):
    lines, current = [], ""
    for word in text.split():
        candidate = (current + " " + word).strip()
        if draw.textbbox((0, 0), candidate, font=fnt)[2] <= max_width:
            current = candidate
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def save_webp(img, path, final_width, final_height, quality=92):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    img.convert("RGB").resize((final_width, final_height), Image.LANCZOS).save(
        path, "WEBP", quality=quality, method=6
    )


def make_cover(path, label, title_lines, subtitle_lines, meta=None, width=1600, height=900):
    W, H = s(width), s(height)
    img = gradient_bg(W, H)
    img = add_glow(img, (s(int(width * 0.86)), s(int(height * 0.14))), s(int(width * 0.33)), ORANGE, 95)
    img = add_glow(img, (s(int(width * 0.08)), s(int(height * 0.9))), s(int(width * 0.28)), (56, 189, 248), 26)
    img = add_grid(img)
    d = ImageDraw.Draw(img)
    pad = s(120)

    d.text((pad, s(96)), label, font=font(F_BOLD, 24), fill=ORANGE_LIGHT)
    y = s(168)
    title_font = font(F_BOLD, 100)
    for line in title_lines:
        d.text((pad, y), line, font=title_font, fill=WHITE)
        y += s(117)
    d.rounded_rectangle([pad, y + s(23), pad + s(180), y + s(32)], radius=s(4), fill=ORANGE)
    y += s(60)
    sub_font = font(F_REG, 38)
    for line in subtitle_lines:
        d.text((pad, y), line, font=sub_font, fill=MUTED)
        y += s(52)
    if meta:
        d.text((pad, y + s(38)), meta, font=font(F_BOLD, 25), fill=(203, 213, 225))

    # bande audio -> document
    base_y = s(height - 100)
    rng = np.random.default_rng(7)
    n_bars, bar_w, gap = 56, s(7), s(6)
    x0 = pad
    amps = np.abs(np.sin(np.linspace(0, 3.4 * math.pi, n_bars))) * 0.72 + 0.28
    amps = amps * rng.uniform(0.5, 1.0, n_bars)
    max_amp = s(74)
    for i, a in enumerate(amps):
        hb = max(s(7), int(max_amp * a))
        x = x0 + i * (bar_w + gap)
        d.rounded_rectangle(
            [x, base_y - hb // 2, x + bar_w, base_y + hb // 2],
            radius=bar_w // 2,
            fill=ORANGE if i % 9 else ORANGE_LIGHT,
        )
    wave_end = x0 + n_bars * (bar_w + gap) + s(26)
    d.rounded_rectangle([wave_end, base_y - s(2), wave_end + s(56), base_y + s(2)], radius=s(2), fill=(100, 116, 139))
    d.polygon(
        [(wave_end + s(56), base_y - s(9)), (wave_end + s(78), base_y), (wave_end + s(56), base_y + s(9))],
        fill=(148, 163, 184),
    )
    line_x = wave_end + s(110)
    for i in range(5):
        ly = base_y - s(40) + i * s(20)
        wl = s(330) if i % 2 == 0 else s(250)
        d.rounded_rectangle(
            [line_x, ly, line_x + wl, ly + s(7)],
            radius=s(3),
            fill=(203, 213, 225) if i == 0 else (100, 116, 139),
        )

    save_webp(img, path, width, height)
    return path


def make_figure(path, label, title_lines, subtitle, cards, footer=None, width=1400, columns=2):
    rows = (len(cards) + columns - 1) // columns
    card_h = 200
    gap_y = 28
    start_y = 330
    height = start_y + rows * (card_h + gap_y) + (118 if footer else 20) + 30
    W, H = s(width), s(height)
    img = gradient_bg(W, H)
    img = add_glow(img, (s(int(width * 0.9)), s(80)), s(int(width * 0.4)), ORANGE, 55)
    img = add_grid(img)
    d = ImageDraw.Draw(img)
    pad = s(90)

    d.text((pad, s(70)), label, font=font(F_BOLD, 24), fill=ORANGE_LIGHT)
    y = s(112)
    title_font = font(F_BOLD, 54)
    for line in title_lines:
        d.text((pad, y), line, font=title_font, fill=WHITE)
        y += s(66)
    d.text((pad, y + s(18)), subtitle, font=font(F_REG, 24), fill=MUTED)

    card_w = (W - pad * 2 - s(30) * (columns - 1)) // columns
    for i, (num, title, desc) in enumerate(cards):
        col, row = i % columns, i // columns
        x = pad + col * (card_w + s(30))
        cy = s(start_y) + row * (s(card_h) + s(gap_y))
        d.rounded_rectangle([x, cy, x + card_w, cy + s(card_h)], radius=s(20), fill=CARD, outline=BORDER, width=s(2))
        if num:
            d.rounded_rectangle([x + s(28), cy + s(28), x + s(90), cy + s(80)], radius=s(10), fill=ORANGE_DARK)
            d.text((x + s(40), cy + s(34)), num, font=font(F_BOLD, 26), fill=ORANGE_LIGHT)
        d.text((x + s(108), cy + s(30)), title, font=font(F_BOLD, 32), fill=WHITE)
        desc_font = font(F_REG, 23)
        for j, line in enumerate(wrap(d, desc, desc_font, card_w - s(136))):
            d.text((x + s(108), cy + s(100) + j * s(30)), line, font=desc_font, fill=MUTED)

    if footer:
        fy = s(start_y) + rows * (s(card_h) + s(gap_y)) + s(6)
        d.rounded_rectangle([pad, fy, W - pad, fy + s(108)], radius=s(16), fill=(32, 28, 19), outline=(120, 63, 4), width=s(2))
        d.text((pad + s(34), fy + s(20)), footer, font=font(F_BOLD, 23), fill=(253, 224, 171))

    save_webp(img, path, width, height)
    return path
