import math
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

def create_app_icon(size=512, maskable=False):
    # Create image with RGBA
    img = Image.new("RGBA", (size, size), (10, 15, 29, 255)) # #0a0f1d
    draw = ImageDraw.Draw(img)

    center = size / 2.0
    scale = size / 512.0
    
    # Safe margin for maskable icon is 10-20%
    content_scale = 0.75 if maskable else 0.92
    s = scale * content_scale

    # 1. Background radial glow
    glow_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_img)
    glow_radius = int(180 * s)
    for r in range(glow_radius, 0, -5):
        alpha = int(35 * (1.0 - r / glow_radius))
        glow_draw.ellipse(
            [center - r, center - r, center + r, center + r],
            fill=(0, 240, 255, alpha)
        )
    img = Image.alpha_composite(img, glow_img)
    draw = ImageDraw.Draw(img)

    # 2. Tech circuit / grid lines in background
    grid_color = (25, 45, 75, 120)
    step = int(40 * s)
    for offset in range(-int(200 * s), int(200 * s), step):
        y = center + offset
        draw.line([(center - 210 * s, y), (center + 210 * s, y)], fill=grid_color, width=max(1, int(1 * s)))
        x = center + offset
        draw.line([(x, center - 210 * s), (x, center + 210 * s)], fill=grid_color, width=max(1, int(1 * s)))

    # Outer border beveled frame (for non-maskable)
    if not maskable:
        pad = 20 * scale
        r_outer = 64 * scale
        # Hexagonal or rounded rect frame
        draw.rounded_rectangle([pad, pad, size - pad, size - pad], radius=int(r_outer), outline=(0, 240, 255, 180), width=max(2, int(3 * scale)))
        draw.rounded_rectangle([pad + 6*scale, pad + 6*scale, size - pad - 6*scale, size - pad - 6*scale], radius=int(r_outer - 6*scale), outline=(0, 150, 255, 60), width=max(1, int(1.5 * scale)))

    # 3. Expanding EMP Shockwave Rings (representing Signal Break pulse)
    pulse_rings = [
        (160 * s, (0, 240, 255, 100), max(2, int(3 * s))),
        (125 * s, (255, 183, 0, 160), max(2, int(3.5 * s))),
        (90 * s, (0, 240, 255, 220), max(3, int(4 * s))),
    ]
    for r, col, w in pulse_rings:
        draw.ellipse([center - r, center - r, center + r, center + r], outline=col, width=w)
        # Pulse arcs / ticks
        for angle_deg in [0, 90, 180, 270]:
            rad = math.radians(angle_deg)
            x1 = center + (r - 12 * s) * math.cos(rad)
            y1 = center + (r - 12 * s) * math.sin(rad)
            x2 = center + (r + 12 * s) * math.cos(rad)
            y2 = center + (r + 12 * s) * math.sin(rad)
            draw.line([(x1, y1), (x2, y2)], fill=(255, 255, 255, 200), width=max(2, int(3 * s)))

    # 4. Stylized Tactical Shield Emblem
    shield_pts = [
        (center, center - 130 * s),        # Top apex
        (center + 115 * s, center - 70 * s), # Top right
        (center + 95 * s, center + 60 * s),  # Mid right
        (center, center + 140 * s),        # Bottom apex
        (center - 95 * s, center + 60 * s),  # Mid left
        (center - 115 * s, center - 70 * s), # Top left
    ]
    # Semi-transparent shield fill
    shield_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shield_layer)
    s_draw.polygon(shield_pts, fill=(12, 35, 65, 210), outline=(0, 240, 255, 255))
    s_draw.line(shield_pts + [shield_pts[0]], fill=(0, 240, 255, 255), width=max(3, int(5 * s)))
    
    # Inner shield accent
    inner_shield = [
        (center, center - 105 * s),
        (center + 85 * s, center - 55 * s),
        (center + 70 * s, center + 45 * s),
        (center, center + 110 * s),
        (center - 70 * s, center + 45 * s),
        (center - 85 * s, center - 55 * s),
    ]
    s_draw.polygon(inner_shield, fill=(8, 24, 48, 160), outline=(255, 183, 0, 220))
    s_draw.line(inner_shield + [inner_shield[0]], fill=(255, 183, 0, 200), width=max(2, int(2.5 * s)))

    img = Image.alpha_composite(img, shield_layer)
    draw = ImageDraw.Draw(img)

    # 5. Golden Glowing EMP Core in Center
    core_r = 38 * s
    # Outer gold core glow
    for cr in range(int(core_r * 1.5), 0, -3):
        a = int(120 * (1.0 - cr / (core_r * 1.5)))
        draw.ellipse([center - cr, center - cr, center + cr, center + cr], fill=(255, 190, 0, a))
    # Diamond core
    diamond = [
        (center, center - core_r),
        (center + core_r, center),
        (center, center + core_r),
        (center - core_r, center),
    ]
    draw.polygon(diamond, fill=(255, 220, 80, 255), outline=(255, 255, 255, 255))
    draw.line(diamond + [diamond[0]], fill=(255, 255, 255, 255), width=max(2, int(3 * s)))
    
    # Inner white hot spark
    spark_r = 14 * s
    draw.ellipse([center - spark_r, center - spark_r, center + spark_r, center + spark_r], fill=(255, 255, 255, 255))

    # 6. Operative Delta Chevron on Top
    chevron_pts = [
        (center, center - 65 * s),
        (center + 24 * s, center - 35 * s),
        (center + 14 * s, center - 35 * s),
        (center, center - 50 * s),
        (center - 14 * s, center - 35 * s),
        (center - 24 * s, center - 35 * s),
    ]
    draw.polygon(chevron_pts, fill=(0, 240, 255, 255))

    return img


def create_banner_logo(width=800, height=240):
    img = Image.new("RGBA", (width, height), (10, 15, 29, 255))
    draw = ImageDraw.Draw(img)
    
    # Background subtle cyber grid & cyan aura
    aura = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    a_draw = ImageDraw.Draw(aura)
    for r in range(160, 0, -4):
        a = int(30 * (1.0 - r / 160.0))
        a_draw.ellipse([120 - r, 120 - r, 120 + r, 120 + r], fill=(0, 240, 255, a))
    img = Image.alpha_composite(img, aura)
    draw = ImageDraw.Draw(img)

    # Paste emblem on left
    emblem = create_app_icon(size=200, maskable=False)
    img.paste(emblem, (20, 20), emblem)

    # Typography
    # Try finding system font or fall back to default
    font_large = None
    font_sub = None
    system_fonts = [
        "/System/Library/Fonts/Supplemental/Futura.ttc",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/Library/Fonts/Arial.ttf"
    ]
    for sf in system_fonts:
        if os.path.exists(sf):
            try:
                font_large = ImageFont.truetype(sf, 62)
                font_sub = ImageFont.truetype(sf, 26)
                break
            except Exception:
                continue

    if font_large is None:
        font_large = ImageFont.load_default()
        font_sub = ImageFont.load_default()

    # Draw Title: "LAST STAND"
    tx = 250
    ty = 48
    draw.text((tx, ty), "LAST STAND", font=font_large, fill=(0, 240, 255, 255))
    # Drop glow / accent line
    draw.line([(tx, ty + 78), (tx + 480, ty + 78)], fill=(0, 240, 255, 180), width=3)
    draw.line([(tx, ty + 83), (tx + 360, ty + 83)], fill=(255, 183, 0, 180), width=2)

    # Subtitle: "SIGNAL BREAK" with tracking
    draw.text((tx + 4, ty + 96), "SIGNAL BREAK", font=font_sub, fill=(255, 183, 0, 255))
    draw.text((tx + 240, ty + 100), "• TACTICAL EMP SURVIVAL", font=font_sub, fill=(160, 190, 220, 220))

    return img


def generate_svg_icon():
    return """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <radialGradient id="bgGlow" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#143058" stop-opacity="1"/>
      <stop offset="65%" stop-color="#0e1a32" stop-opacity="1"/>
      <stop offset="100%" stop-color="#0a0f1d" stop-opacity="1"/>
    </radialGradient>
    <radialGradient id="coreGlow" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="30%" stop-color="#ffdc50"/>
      <stop offset="70%" stop-color="#ff9900"/>
      <stop offset="100%" stop-color="#ff6600" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="shieldGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#0a2a4a"/>
      <stop offset="50%" stop-color="#103860"/>
      <stop offset="100%" stop-color="#06182c"/>
    </linearGradient>
    <filter id="neonCyan" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="6" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>

  <!-- Background -->
  <rect width="512" height="512" rx="64" fill="url(#bgGlow)"/>
  <rect x="16" y="16" width="480" height="480" rx="52" fill="none" stroke="#00f0ff" stroke-width="3" stroke-opacity="0.7"/>

  <!-- Circuit lines -->
  <path d="M 60 256 H 180 M 332 256 H 452 M 256 60 V 160 M 256 352 V 452" stroke="#00f0ff" stroke-width="2" stroke-opacity="0.35"/>
  <circle cx="180" cy="256" r="4" fill="#00f0ff"/>
  <circle cx="332" cy="256" r="4" fill="#00f0ff"/>

  <!-- Disruption Pulse Rings -->
  <circle cx="256" cy="256" r="160" fill="none" stroke="#00f0ff" stroke-width="3" stroke-opacity="0.4" stroke-dasharray="12 8"/>
  <circle cx="256" cy="256" r="125" fill="none" stroke="#ffb700" stroke-width="3.5" stroke-opacity="0.6"/>
  <circle cx="256" cy="256" r="90" fill="none" stroke="#00f0ff" stroke-width="4" stroke-opacity="0.85" filter="url(#neonCyan)"/>

  <!-- Tactical Shield -->
  <polygon points="256,126 371,186 351,316 256,396 161,316 141,186" fill="url(#shieldGrad)" stroke="#00f0ff" stroke-width="5" filter="url(#neonCyan)"/>
  <polygon points="256,151 341,201 326,296 256,366 186,296 171,201" fill="#07182c" fill-opacity="0.75" stroke="#ffb700" stroke-width="2.5"/>

  <!-- Golden EMP Core -->
  <circle cx="256" cy="256" r="55" fill="url(#coreGlow)"/>
  <polygon points="256,218 294,256 256,294 218,256" fill="#ffe168" stroke="#ffffff" stroke-width="3"/>
  <circle cx="256" cy="256" r="14" fill="#ffffff"/>

  <!-- Chevron Top -->
  <polygon points="256,191 280,221 270,221 256,206 242,221 232,221" fill="#00f0ff"/>
</svg>"""


def generate_svg_logo():
    return """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 240" width="800" height="240">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#0e182a"/>
      <stop offset="100%" stop-color="#070b14"/>
    </linearGradient>
    <linearGradient id="textCyan" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#00f0ff"/>
      <stop offset="100%" stop-color="#38bdf8"/>
    </linearGradient>
  </defs>

  <rect width="800" height="240" rx="16" fill="url(#bg)"/>
  <rect x="4" y="4" width="792" height="232" rx="12" fill="none" stroke="#00f0ff" stroke-width="1.5" stroke-opacity="0.3"/>

  <!-- Embedded Logo Emblem (scaled to 180x180 at x=30, y=30) -->
  <g transform="translate(30, 30) scale(0.3515)">
    <circle cx="256" cy="256" r="160" fill="none" stroke="#00f0ff" stroke-width="6" stroke-opacity="0.4" stroke-dasharray="16 10"/>
    <circle cx="256" cy="256" r="125" fill="none" stroke="#ffb700" stroke-width="7" stroke-opacity="0.6"/>
    <circle cx="256" cy="256" r="90" fill="none" stroke="#00f0ff" stroke-width="8" stroke-opacity="0.9"/>
    <polygon points="256,126 371,186 351,316 256,396 161,316 141,186" fill="#103860" stroke="#00f0ff" stroke-width="10"/>
    <polygon points="256,151 341,201 326,296 256,366 186,296 171,201" fill="#07182c" stroke="#ffb700" stroke-width="5"/>
    <polygon points="256,218 294,256 256,294 218,256" fill="#ffe168" stroke="#ffffff" stroke-width="6"/>
    <circle cx="256" cy="256" r="14" fill="#ffffff"/>
  </g>

  <!-- Typography -->
  <text x="240" y="105" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif" font-weight="900" font-size="62" letter-spacing="4" fill="url(#textCyan)">LAST STAND</text>
  
  <line x1="240" y1="126" x2="740" y2="126" stroke="#00f0ff" stroke-width="3" stroke-opacity="0.8"/>
  <line x1="240" y1="132" x2="600" y2="132" stroke="#ffb700" stroke-width="2" stroke-opacity="0.7"/>

  <text x="242" y="168" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif" font-weight="800" font-size="26" letter-spacing="6" fill="#ffb700">SIGNAL BREAK</text>
  <text x="500" y="168" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif" font-weight="600" font-size="20" letter-spacing="2" fill="#94a3b8">TACTICAL EMP SURVIVAL</text>
</svg>"""


def main():
    out_dir = "assets/branding"
    os.makedirs(out_dir, exist_ok=True)
    
    print("Generating master 512x512 app icon...")
    icon_512 = create_app_icon(512, maskable=False)
    icon_512.save(os.path.join(out_dir, "icon-512.png"))

    print("Generating 512x512 maskable icon (safe zone padded)...")
    icon_maskable = create_app_icon(512, maskable=True)
    icon_maskable.save(os.path.join(out_dir, "icon-maskable-512.png"))

    print("Generating 192x192 Android icon...")
    icon_192 = icon_512.resize((192, 192), Image.Resampling.LANCZOS)
    icon_192.save(os.path.join(out_dir, "icon-192.png"))

    print("Generating 180x180 Apple Touch Icon...")
    icon_180 = icon_512.resize((180, 180), Image.Resampling.LANCZOS)
    icon_180.save(os.path.join(out_dir, "apple-touch-icon.png"))

    print("Generating 144x144 icon...")
    icon_144 = icon_512.resize((144, 144), Image.Resampling.LANCZOS)
    icon_144.save(os.path.join(out_dir, "icon-144.png"))

    print("Generating 32x32 favicon...")
    icon_32 = icon_512.resize((32, 32), Image.Resampling.LANCZOS)
    icon_32.save(os.path.join(out_dir, "favicon-32x32.png"))

    print("Generating favicon.ico...")
    icon_16 = icon_512.resize((16, 16), Image.Resampling.LANCZOS)
    icon_512.save(os.path.join(out_dir, "favicon.ico"), format="ICO", sizes=[(16, 16), (32, 32), (48, 48), (64, 64)])

    print("Generating banner logo...")
    banner = create_banner_logo(800, 240)
    banner.save(os.path.join(out_dir, "logo-banner.png"))

    print("Writing SVG icon and logo...")
    with open(os.path.join(out_dir, "icon.svg"), "w") as f:
        f.write(generate_svg_icon())
    with open(os.path.join(out_dir, "logo.svg"), "w") as f:
        f.write(generate_svg_logo())

    # Also update root icon.svg for Godot editor project icon
    with open("icon.svg", "w") as f:
        f.write(generate_svg_icon())

    print("\nAll branding assets successfully created in assets/branding/ and icon.svg updated!")

if __name__ == "__main__":
    main()
