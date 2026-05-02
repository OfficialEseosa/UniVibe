"""
UniVibe app icon generator.
Outputs a 1024x1024 PNG — flutter_launcher_icons handles the Android mipmap sizes.
"""
from PIL import Image, ImageDraw, ImageFont

SIZE = 1024

# Brand colours
BG_TOP    = (30, 126, 255)   # lighter blue top
BG_BOT    = (15,  65, 185)   # deeper blue bottom
WHITE     = (255, 255, 255)
TINT      = (200, 222, 252)  # shadow face of board
DARK      = (10,  50, 140)   # tassel / button


def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


# ── Canvas ──────────────────────────────────────────────────────────────────
img  = Image.new("RGB", (SIZE, SIZE), BG_TOP)
draw = ImageDraw.Draw(img)

# Vertical gradient background
for y in range(SIZE):
    draw.line([(0, y), (SIZE, y)], fill=lerp_color(BG_TOP, BG_BOT, y / SIZE))

cx = SIZE // 2   # 512

# ── Layout constants ─────────────────────────────────────────────────────────
# Vertically centre the mortarboard + "UV" in the canvas:
#   board_top_y  ≈  88
#   cap_bottom_y ≈  622
#   "UV" baseline ≈  830
#   bottom pad   ≈  194  (19 %)

BD         = 340    # board half-diagonal
board_cy   = 88 + BD          # board diamond centre  = 428
cap_w      = 255               # half-width of cylinder
cap_h      = 120               # cylinder height
cap_t      = 24                # cylinder top/bottom ellipse semi-minor
body_top_y = board_cy + 52    # = 480
bottom_y   = body_top_y + cap_h   # = 600


# ── 1. Cap cylinder ──────────────────────────────────────────────────────────
# bottom ellipse first (hidden behind walls)
draw.ellipse([cx-cap_w, bottom_y-cap_t, cx+cap_w, bottom_y+cap_t], fill=TINT)
# side walls
draw.rectangle([cx-cap_w, body_top_y, cx+cap_w, bottom_y], fill=WHITE)
# top ellipse on top of walls
draw.ellipse([cx-cap_w, body_top_y-cap_t, cx+cap_w, body_top_y+cap_t], fill=WHITE)


# ── 2. Board diamond ─────────────────────────────────────────────────────────
board_pts = [
    (cx,        board_cy - BD),   # top vertex   y = 88
    (cx + BD,   board_cy),        # right vertex x = 852
    (cx,        board_cy + 46),   # bottom vertex y = 474
    (cx - BD,   board_cy),        # left vertex  x = 172
]

# Left face (white – lit side)
draw.polygon([board_pts[0], board_pts[3], board_pts[2]], fill=WHITE)
# Right face (tinted – shadow side)
draw.polygon([board_pts[0], board_pts[1], board_pts[2]], fill=TINT)
# Thin outline for crispness
draw.polygon(board_pts, outline=(170, 200, 240), width=3)


# ── 3. Button on top ─────────────────────────────────────────────────────────
bx, by = cx, board_cy - BD    # (512, 88)
btn_r  = 22
draw.ellipse([bx-btn_r, by-btn_r, bx+btn_r, by+btn_r], fill=DARK)
draw.ellipse([bx-btn_r+6, by-btn_r+6, bx+btn_r-6, by+btn_r-6], fill=WHITE)


# ── 4. Tassel ─────────────────────────────────────────────────────────────────
# Hangs from the right vertex of the board.
tr_x, tr_y  = cx + BD, board_cy      # (852, 428)
drop        = 165
cord_x      = tr_x + 14              # slight offset rightward = 866
cord_bot_y  = tr_y + drop            # = 593
pompon_r    = 28

# Short horizontal jog then vertical drop
draw.line([(tr_x, tr_y), (cord_x, tr_y)], fill=DARK, width=10)
draw.line([(cord_x, tr_y), (cord_x, cord_bot_y)], fill=DARK, width=10)
# Pompon
draw.ellipse([cord_x-pompon_r, cord_bot_y,
              cord_x+pompon_r, cord_bot_y+pompon_r*2], fill=DARK)
# Fringe (3 threads)
fring_y = cord_bot_y + pompon_r * 2
for dx in (-11, 0, 11):
    draw.line([(cord_x+dx, fring_y), (cord_x+dx, fring_y+38)],
              fill=DARK, width=7)


# ── 5. "UV" monogram ─────────────────────────────────────────────────────────
try:
    font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 200)
    text = "UV"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw   = bbox[2] - bbox[0]
    tx   = cx - tw // 2 - bbox[0]
    ty   = bottom_y + 48              # ~648
    draw.text((tx, ty), text, font=font, fill=WHITE)
except Exception as e:
    print("Font skipped:", e)


# ── Save ──────────────────────────────────────────────────────────────────────
out = "C:/Users/rapha/Desktop/mad/inclass/univibe/assets/icon/icon.png"
img.save(out, "PNG")
print(f"Saved {SIZE}x{SIZE} PNG to {out}")
