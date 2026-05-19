"""
Generate Material You style adaptive icon foregrounds for ARBPay Bot.
- Dark icon:  #FFCC00 (yellow) ₹ symbol on transparent bg
- Light icon: #0A0A0F (dark)   ₹ symbol on transparent bg

The background color is set in the XML (ic_launcher_background / ic_launcher_dark_background).
The foreground PNG is just the symbol with transparency — Android composites them.

Adaptive icon foreground should be 108x108dp with the safe zone being the
center 72x72dp circle. We generate at 4x scale then resize for each density.
"""

from PIL import Image, ImageDraw, ImageFont
import os, math

# ── Config ────────────────────────────────────────────────────────────────────
CANVAS   = 432   # 108dp * 4x — full adaptive icon canvas
SAFE     = 288   # 72dp * 4x  — safe zone (what's always visible)
PADDING  = 72    # extra padding inside safe zone for the symbol

# Densities: (folder_suffix, scale_factor relative to mdpi=48px)
DENSITIES = [
    ('mdpi',    1.0,  48),
    ('hdpi',    1.5,  72),
    ('xhdpi',   2.0,  96),
    ('xxhdpi',  3.0, 144),
    ('xxxhdpi', 4.0, 192),
]

BASE = r'e:\arb-pay-script\arbpay_apk\android\app\src\main\res'

def draw_rupee(draw, cx, cy, size, color):
    """Draw a clean ₹ symbol using geometric primitives."""
    lw = max(2, size // 14)   # line width scales with size
    s  = size * 0.72          # symbol bounding box

    x0 = cx - s/2
    y0 = cy - s/2
    x1 = cx + s/2
    y1 = cy + s/2

    top_y    = y0
    bar1_y   = y0 + s * 0.22
    bar2_y   = y0 + s * 0.44
    bottom_y = y1

    # Vertical stem
    stem_x = x0 + s * 0.18
    draw.line([(stem_x, top_y), (stem_x, bottom_y)], fill=color, width=lw)

    # Top horizontal bar (full width)
    draw.line([(x0, top_y), (x1, top_y)], fill=color, width=lw)

    # Second horizontal bar
    draw.line([(x0, bar1_y), (x1, bar1_y)], fill=color, width=lw)

    # Arc for the "P" shape (top right)
    arc_box = [stem_x, top_y, x1, bar1_y * 2 - top_y]
    draw.arc(arc_box, start=270, end=90, fill=color, width=lw)

    # Diagonal line from bar2 to bottom-right
    draw.line([(x0, bar2_y), (x1, bottom_y)], fill=color, width=lw)

    # Short bar at bar2 level
    draw.line([(x0, bar2_y), (cx + s*0.1, bar2_y)], fill=color, width=lw)


def make_foreground(symbol_color, out_path, final_size):
    """Create a foreground PNG: transparent bg + colored ₹ symbol."""
    # Work at 4x then resize
    img = Image.new('RGBA', (CANVAS, CANVAS), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx = CANVAS // 2
    cy = CANVAS // 2
    symbol_size = SAFE - PADDING * 2

    draw_rupee(draw, cx, cy, symbol_size, symbol_color + (255,))

    # Resize to target density size
    img = img.resize((final_size, final_size), Image.LANCZOS)
    img.save(out_path)
    print(f'  Saved {out_path}')


def make_flat_icon(bg_color, symbol_color, out_path, size):
    """Create a flat PNG icon (for legacy mipmap fallback)."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Rounded square background
    r = size // 5  # corner radius
    draw.rounded_rectangle([0, 0, size-1, size-1], radius=r, fill=bg_color + (255,))

    # Symbol
    draw_rupee(draw, size//2, size//2, int(size * 0.62), symbol_color + (255,))

    img.save(out_path)
    print(f'  Saved {out_path}')


print('Generating icons...')

for density, scale, px in DENSITIES:
    folder = os.path.join(BASE, f'mipmap-{density}')

    # Yellow foreground (for dark bg adaptive icon)
    make_foreground(
        symbol_color=(255, 204, 0),
        out_path=os.path.join(folder, 'ic_launcher_foreground_yellow.png'),
        final_size=px * 2,  # adaptive foreground is 2x the launcher size
    )

    # Dark foreground (for yellow bg adaptive icon)
    make_foreground(
        symbol_color=(10, 10, 15),
        out_path=os.path.join(folder, 'ic_launcher_foreground.png'),
        final_size=px * 2,
    )

    # Flat legacy icons
    make_flat_icon(
        bg_color=(255, 204, 0), symbol_color=(10, 10, 15),
        out_path=os.path.join(folder, 'ic_launcher.png'),
        size=px,
    )
    make_flat_icon(
        bg_color=(10, 10, 15), symbol_color=(255, 204, 0),
        out_path=os.path.join(folder, 'ic_launcher_light.png'),
        size=px,
    )
    make_flat_icon(
        bg_color=(255, 204, 0), symbol_color=(10, 10, 15),
        out_path=os.path.join(folder, 'ic_launcher_round.png'),
        size=px,
    )

print('\nDone!')
