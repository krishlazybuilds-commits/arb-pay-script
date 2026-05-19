"""
Generate Material You style app icons for ARBPay Bot.
Uses Arial Black font for a clean, bold ₹ glyph.
"""

from PIL import Image, ImageDraw, ImageFont
import os

BASE = r'e:\arb-pay-script\arbpay_apk\android\app\src\main\res'
ASSETS = r'e:\arb-pay-script\arbpay_apk\assets\images'
FONT_PATH = r'C:\Windows\Fonts\ariblk.ttf'

# Densities: (folder, launcher_px)
DENSITIES = [
    ('mdpi',    48),
    ('hdpi',    72),
    ('xhdpi',   96),
    ('xxhdpi',  144),
    ('xxxhdpi', 192),
]

YELLOW = (255, 204, 0)
DARK   = (10, 10, 15)


def make_icon(size, bg_color, symbol_color, path):
    """
    Flat rounded-square icon with a centered ₹ glyph.
    Google Material You style — no gradients, no shadows.
    """
    img  = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Rounded square background (corner radius = 22% of size)
    r = int(size * 0.22)
    draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=r, fill=bg_color + (255,))

    # Find font size that fills ~58% of the icon
    target = int(size * 0.58)
    font_size = target
    font = ImageFont.truetype(FONT_PATH, font_size)

    # Measure and adjust
    bbox = font.getbbox('₹')
    glyph_w = bbox[2] - bbox[0]
    glyph_h = bbox[3] - bbox[1]

    # Scale font to fit target
    scale = target / max(glyph_w, glyph_h)
    font_size = int(font_size * scale)
    font = ImageFont.truetype(FONT_PATH, font_size)
    bbox = font.getbbox('₹')
    glyph_w = bbox[2] - bbox[0]
    glyph_h = bbox[3] - bbox[1]

    # Center the glyph
    x = (size - glyph_w) // 2 - bbox[0]
    y = (size - glyph_h) // 2 - bbox[1]

    draw.text((x, y), '₹', font=font, fill=symbol_color + (255,))
    img.save(path)
    print(f'  {os.path.basename(path)} ({size}px)')


def make_foreground(size, symbol_color, path):
    """
    Adaptive icon foreground — transparent bg, just the symbol.
    Canvas is 2x the launcher size (adaptive icon spec).
    """
    canvas = size * 2
    img  = Image.new('RGBA', (canvas, canvas), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    target = int(canvas * 0.40)  # symbol fills 40% of adaptive canvas
    font_size = target
    font = ImageFont.truetype(FONT_PATH, font_size)
    bbox = font.getbbox('₹')
    glyph_w = bbox[2] - bbox[0]
    glyph_h = bbox[3] - bbox[1]
    scale = target / max(glyph_w, glyph_h)
    font_size = int(font_size * scale)
    font = ImageFont.truetype(FONT_PATH, font_size)
    bbox = font.getbbox('₹')
    glyph_w = bbox[2] - bbox[0]
    glyph_h = bbox[3] - bbox[1]

    x = (canvas - glyph_w) // 2 - bbox[0]
    y = (canvas - glyph_h) // 2 - bbox[1]

    draw.text((x, y), '₹', font=font, fill=symbol_color + (255,))
    img.save(path)
    print(f'  {os.path.basename(path)} ({canvas}px foreground)')


print('Generating icons...\n')

for density, px in DENSITIES:
    folder = os.path.join(BASE, f'mipmap-{density}')
    print(f'[{density}]')

    # Light theme: yellow bg + dark symbol
    make_icon(px, YELLOW, DARK,
        os.path.join(folder, 'ic_launcher.png'))
    make_icon(px, YELLOW, DARK,
        os.path.join(folder, 'ic_launcher_round.png'))

    # Dark theme: dark bg + yellow symbol
    make_icon(px, DARK, YELLOW,
        os.path.join(folder, 'ic_launcher_light.png'))

    # Adaptive foregrounds
    make_foreground(px, DARK, os.path.join(folder, 'ic_launcher_foreground.png'))
    make_foreground(px, YELLOW, os.path.join(folder, 'ic_launcher_foreground_yellow.png'))

# In-app header icons (192px)
print('\n[assets]')
make_icon(192, DARK,   YELLOW, os.path.join(ASSETS, 'app_icon_dark.png'))
make_icon(192, YELLOW, DARK,   os.path.join(ASSETS, 'app_icon_light.png'))

print('\nDone!')
