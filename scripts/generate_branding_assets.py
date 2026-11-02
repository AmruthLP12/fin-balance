#!/usr/bin/env python3
"""
FinBalance Branding & Logo Asset Generator
Generates clean geometric fintech icons representing:
  - Assets (+) Emerald Green #10B981
  - Liabilities (-) Cobalt Blue #2563EB
  - Balance & Wealth: Golden Amber #F59E0B pivot
Across Android mipmaps, Web icons, favicon, and splash screen drawables.
"""

import os
from PIL import Image, ImageDraw

def render_logo(size=1024, is_maskable=False, is_transparent=False):
    # Render at 2x for supersampled antialiasing
    scale = 2
    render_size = size * scale
    
    if is_transparent:
        img = Image.new('RGBA', (render_size, render_size), (0, 0, 0, 0))
    else:
        # Deep Obsidian Navy background
        img = Image.new('RGBA', (render_size, render_size), (8, 14, 26, 255))
    
    draw = ImageDraw.Draw(img)
    
    # Coordinates in normalized 0.0 - 1.0 range
    # If maskable, scale geometry into 65% safe zone
    geo_scale = 0.65 if is_maskable else 0.82
    cx, cy = render_size / 2.0, render_size / 2.0
    r = (render_size / 2.0) * geo_scale
    
    # 1. Background subtle rounded card if not transparent and not maskable
    if not is_transparent and not is_maskable:
        card_r = render_size * 0.92 / 2.0
        corner_r = render_size * 0.22
        card_box = [cx - card_r, cy - card_r, cx + card_r, cy + card_r]
        draw.rounded_rectangle(card_box, radius=corner_r, fill=(11, 19, 36, 255), outline=(30, 41, 59, 255), width=int(4 * scale))

    # 2. Left / Top Wing: ASSETS (+) in Emerald Green
    # Upward diamond-trapezoid polygon
    green_light = (16, 185, 129, 255) # #10B981
    green_dark = (5, 150, 105, 255)   # #059669
    
    # Points for Assets Wing
    p1 = (cx - r * 0.72, cy)
    p2 = (cx - r * 0.18, cy - r * 0.72)
    p3 = (cx, cy - r * 0.50)
    p4 = (cx - r * 0.38, cy - r * 0.04)
    draw.polygon([p1, p2, p3, p4], fill=green_light)
    
    # Top-right anchor of the assets bracket
    p5 = (cx, cy - r * 0.50)
    p6 = (cx + r * 0.28, cy - r * 0.72)
    p7 = (cx + r * 0.44, cy - r * 0.52)
    p8 = (cx + r * 0.16, cy - r * 0.30)
    draw.polygon([p5, p6, p7, p8], fill=green_dark)

    # 3. Right / Bottom Wing: LIABILITIES (-) in Cobalt Blue
    blue_light = (59, 130, 246, 255) # #3B82F6
    blue_dark = (37, 99, 235, 255)   # #2563EB
    
    p9 = (cx + r * 0.72, cy)
    p10 = (cx + r * 0.18, cy + r * 0.72)
    p11 = (cx, cy + r * 0.50)
    p12 = (cx + r * 0.38, cy + r * 0.04)
    draw.polygon([p9, p10, p11, p12], fill=blue_dark)
    
    # Bottom-left anchor of liabilities bracket
    p13 = (cx, cy + r * 0.50)
    p14 = (cx - r * 0.28, cy + r * 0.72)
    p15 = (cx - r * 0.44, cy + r * 0.52)
    p16 = (cx - r * 0.16, cy + r * 0.30)
    draw.polygon([p13, p14, p15, p16], fill=blue_light)

    # 4. Central Equilibrium Fulcrum (NET WORTH BALANCE) in Golden Amber
    # Sharp diamond in center
    gold = (245, 158, 11, 255) # #F59E0B
    gold_glow = (251, 191, 36, 255)
    d_size = r * 0.24
    
    diamond = [
        (cx, cy - d_size),
        (cx + d_size, cy),
        (cx, cy + d_size),
        (cx - d_size, cy),
    ]
    draw.polygon(diamond, fill=gold)
    
    # Inner diamond facet
    d_inner = r * 0.12
    diamond_inner = [
        (cx, cy - d_inner),
        (cx + d_inner, cy),
        (cx, cy + d_inner),
        (cx - d_inner, cy),
    ]
    draw.polygon(diamond_inner, fill=gold_glow)

    # Downscale smoothly to requested size
    final_img = img.resize((size, size), Image.Resampling.LANCZOS)
    return final_img


def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    
    # 1. Android Mipmaps
    android_res = os.path.join(base_dir, 'android', 'app', 'src', 'main', 'res')
    mipmap_targets = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    
    print("Generating Android mipmap launcher icons...")
    for folder, size in mipmap_targets.items():
        folder_path = os.path.join(android_res, folder)
        os.makedirs(folder_path, exist_ok=True)
        img = render_logo(size=size, is_maskable=False)
        out_path = os.path.join(folder_path, 'ic_launcher.png')
        img.save(out_path, 'PNG')
        print(f"  -> Saved {out_path} ({size}x{size})")

    # 2. Web Icons & Favicon
    web_dir = os.path.join(base_dir, 'web')
    web_icons_dir = os.path.join(web_dir, 'icons')
    os.makedirs(web_icons_dir, exist_ok=True)
    
    print("\nGenerating Web icons and favicon...")
    # Favicon 32x32
    fav = render_logo(size=32, is_maskable=False)
    fav_path = os.path.join(web_dir, 'favicon.png')
    fav.save(fav_path, 'PNG')
    print(f"  -> Saved {fav_path} (32x32)")
    
    # 192 & 512 Standard
    icon_192 = render_logo(size=192, is_maskable=False)
    icon_192.save(os.path.join(web_icons_dir, 'Icon-192.png'), 'PNG')
    print("  -> Saved web/icons/Icon-192.png (192x192)")

    icon_512 = render_logo(size=512, is_maskable=False)
    icon_512.save(os.path.join(web_icons_dir, 'Icon-512.png'), 'PNG')
    print("  -> Saved web/icons/Icon-512.png (512x512)")

    # 192 & 512 Maskable (safe zone)
    mask_192 = render_logo(size=192, is_maskable=True)
    mask_192.save(os.path.join(web_icons_dir, 'Icon-maskable-192.png'), 'PNG')
    print("  -> Saved web/icons/Icon-maskable-192.png (192x192 maskable)")

    mask_512 = render_logo(size=512, is_maskable=True)
    mask_512.save(os.path.join(web_icons_dir, 'Icon-maskable-512.png'), 'PNG')
    print("  -> Saved web/icons/Icon-maskable-512.png (512x512 maskable)")

    print("\nAll FinBalance branding assets generated successfully!")

if __name__ == '__main__':
    main()

