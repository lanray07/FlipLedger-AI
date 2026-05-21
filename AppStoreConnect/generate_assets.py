from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import math

ROOT = Path(__file__).resolve().parents[1]
ASSET_ROOT = ROOT / "AppStoreConnect" / "Assets"
ICON_DIR = ROOT / "FlipLedgerAI" / "Resources" / "Assets.xcassets" / "AppIcon.appiconset"

GREEN = (0, 140, 78)
GREEN_DARK = (0, 96, 60)
GREEN_SOFT = (226, 248, 235)
CHARCOAL = (24, 27, 30)
MUTED = (99, 108, 116)
BG = (246, 248, 247)
WHITE = (255, 255, 255)
LINE = (220, 226, 224)
BLUE = (45, 100, 215)
ORANGE = (218, 132, 36)
PURPLE = (118, 73, 196)

FONT_DIR = Path("C:/Windows/Fonts")
FONT_REGULAR = FONT_DIR / "arial.ttf"
FONT_BOLD = FONT_DIR / "arialbd.ttf"


def font(size, bold=False):
    path = FONT_BOLD if bold else FONT_REGULAR
    return ImageFont.truetype(str(path), size)


def ensure_dirs():
    for path in [
        ASSET_ROOT / "AppIcon",
        ASSET_ROOT / "iPhone-6.9",
        ASSET_ROOT / "iPad-13",
        ASSET_ROOT / "SubscriptionReview",
        ICON_DIR,
    ]:
        path.mkdir(parents=True, exist_ok=True)


def rounded(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def text(draw, xy, value, size, fill=CHARCOAL, bold=False, anchor=None):
    draw.text(xy, value, font=font(size, bold), fill=fill, anchor=anchor)


def wrap(draw, value, max_width, size, bold=False):
    words = value.split()
    lines = []
    current = ""
    f = font(size, bold)
    for word in words:
        trial = word if not current else f"{current} {word}"
        if draw.textlength(trial, font=f) <= max_width:
            current = trial
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def multiline(draw, xy, value, max_width, size, fill=CHARCOAL, bold=False, line_gap=8):
    x, y = xy
    for line in wrap(draw, value, max_width, size, bold):
        text(draw, (x, y), line, size, fill, bold)
        y += size + line_gap
    return y


def gradient(size, top=(248, 252, 249), bottom=(232, 244, 238)):
    width, height = size
    img = Image.new("RGB", size, top)
    pix = img.load()
    for y in range(height):
        t = y / max(1, height - 1)
        color = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        for x in range(width):
            pix[x, y] = color
    return img


def create_icon():
    size = 1024
    img = gradient((size, size), (8, 86, 56), (0, 142, 79))
    draw = ImageDraw.Draw(img)

    rounded(draw, (148, 148, 876, 876), 180, (246, 252, 248))
    rounded(draw, (196, 210, 828, 814), 88, (255, 255, 255), outline=(208, 232, 220), width=8)

    # Ledger rows
    y = 316
    for index, width in enumerate([430, 320, 480]):
        rounded(draw, (284, y, 284 + width, y + 36), 18, GREEN_SOFT)
        y += 92

    # Profit mark
    points = [(300, 670), (430, 560), (548, 608), (730, 430)]
    draw.line(points, fill=GREEN, width=42, joint="curve")
    for point in points:
        draw.ellipse((point[0] - 28, point[1] - 28, point[0] + 28, point[1] + 28), fill=GREEN_DARK)

    text(draw, (512, 504), "FL", 178, fill=CHARCOAL, bold=True, anchor="mm")

    out = ASSET_ROOT / "AppIcon" / "AppIcon-1024.png"
    img.save(out)
    img.save(ICON_DIR / "AppIcon-1024.png")


def phone_frame(draw, x, y, w, h):
    rounded(draw, (x, y, x + w, y + h), 96, (20, 23, 26))
    rounded(draw, (x + 22, y + 22, x + w - 22, y + h - 22), 78, BG)
    draw.rounded_rectangle((x + w * 0.36, y + 34, x + w * 0.64, y + 58), radius=14, fill=(18, 20, 22))
    return (x + 42, y + 82, x + w - 42, y + h - 48)


def tablet_frame(draw, x, y, w, h):
    rounded(draw, (x, y, x + w, y + h), 76, (24, 27, 30))
    rounded(draw, (x + 28, y + 28, x + w - 28, y + h - 28), 52, BG)
    return (x + 58, y + 74, x + w - 58, y + h - 58)


def draw_top_bar(draw, box, title):
    x1, y1, x2, _ = box
    text(draw, (x1, y1), "9:41", 22, fill=CHARCOAL, bold=True)
    text(draw, (x1, y1 + 52), title, 38, fill=CHARCOAL, bold=True)
    rounded(draw, (x2 - 96, y1 + 48, x2 - 36, y1 + 108), 18, GREEN_SOFT)
    text(draw, (x2 - 66, y1 + 78), "+", 30, fill=GREEN, bold=True, anchor="mm")


def card(draw, box, title, value, accent=GREEN, subtitle=None):
    x1, y1, x2, y2 = box
    rounded(draw, box, 22, WHITE, outline=LINE, width=2)
    rounded(draw, (x1 + 24, y1 + 24, x1 + 78, y1 + 78), 16, tuple(int(c * 0.15 + 255 * 0.85) for c in accent))
    draw.ellipse((x1 + 42, y1 + 42, x1 + 60, y1 + 60), fill=accent)
    text(draw, (x1 + 24, y1 + 106), value, 31, fill=CHARCOAL, bold=True)
    text(draw, (x1 + 24, y1 + 152), title, 20, fill=CHARCOAL, bold=True)
    if subtitle:
        text(draw, (x1 + 24, y1 + 184), subtitle, 17, fill=MUTED)


def mini_chart(draw, box, values, accent=GREEN):
    x1, y1, x2, y2 = box
    rounded(draw, box, 22, WHITE, outline=LINE, width=2)
    text(draw, (x1 + 24, y1 + 24), "Monthly profit", 22, fill=CHARCOAL, bold=True)
    left, top, right, bottom = x1 + 28, y1 + 84, x2 - 28, y2 - 36
    for i in range(4):
        yy = top + i * (bottom - top) / 3
        draw.line((left, yy, right, yy), fill=(232, 236, 234), width=2)
    max_v = max(values)
    min_v = min(values)
    pts = []
    for i, val in enumerate(values):
        xx = left + i * (right - left) / (len(values) - 1)
        yy = bottom - (val - min_v) / max(1, max_v - min_v) * (bottom - top)
        pts.append((xx, yy))
    draw.line(pts, fill=accent, width=8, joint="curve")
    for xx, yy in pts:
        draw.ellipse((xx - 7, yy - 7, xx + 7, yy + 7), fill=accent)


def list_row(draw, box, title, subtitle, value=None, accent=GREEN):
    x1, y1, x2, y2 = box
    rounded(draw, box, 20, WHITE, outline=LINE, width=2)
    rounded(draw, (x1 + 20, y1 + 18, x1 + 86, y1 + 84), 18, (235, 240, 238))
    draw.rectangle((x1 + 38, y1 + 38, x1 + 68, y1 + 64), fill=accent)
    text(draw, (x1 + 108, y1 + 20), title, 22, fill=CHARCOAL, bold=True)
    text(draw, (x1 + 108, y1 + 54), subtitle, 17, fill=MUTED)
    if value:
        text(draw, (x2 - 24, y1 + 34), value, 20, fill=accent, bold=True, anchor="ra")


def phone_screen_dashboard(draw, box):
    x1, y1, x2, y2 = box
    draw_top_bar(draw, (x1, y1, x2, y2), "Dashboard")
    text(draw, (x1, y1 + 120), "Profit snapshot", 24, fill=MUTED)
    gap = 18
    cw = (x2 - x1 - gap) / 2
    card(draw, (x1, y1 + 172, x1 + cw, y1 + 356), "Total revenue", "GBP 4,820", GREEN, "Recorded sales")
    card(draw, (x1 + cw + gap, y1 + 172, x2, y1 + 356), "Total profit", "GBP 1,736", GREEN, "After costs")
    card(draw, (x1, y1 + 374, x1 + cw, y1 + 558), "Inventory value", "GBP 2,110", BLUE, "Unsold stock")
    card(draw, (x1 + cw + gap, y1 + 374, x2, y1 + 558), "Avg margin", "36%", ORANGE, "Estimated")
    mini_chart(draw, (x1, y1 + 586, x2, y1 + 862), [12, 18, 15, 26, 31, 44, 39])
    text(draw, (x1, y1 + 900), "Quick actions", 24, fill=CHARCOAL, bold=True)
    actions = ["Add Item", "Record Sale", "AI Listing", "Export"]
    for i, action in enumerate(actions):
        xx = x1 + (i % 2) * (cw + gap)
        yy = y1 + 946 + (i // 2) * 86
        rounded(draw, (xx, yy, xx + cw, yy + 64), 18, WHITE, outline=LINE, width=2)
        text(draw, (xx + 22, yy + 20), action, 18, fill=CHARCOAL, bold=True)


def phone_screen_inventory(draw, box):
    x1, y1, x2, y2 = box
    draw_top_bar(draw, (x1, y1, x2, y2), "Inventory")
    text(draw, (x1, y1 + 120), "Track item cost, source, photos and target price.", 21, fill=MUTED)
    rows = [
        ("Nike vintage jacket", "Clothing / Excellent / Rail A3", "GBP 42"),
        ("Sony headphones", "Electronics / Good / Shelf B1", "GBP 68"),
        ("Ceramic vase set", "Homeware / New / Bin H2", "GBP 31"),
        ("Dr. Martens boots", "Shoes / Good / Rack S4", "GBP 95"),
    ]
    y = y1 + 190
    for title, subtitle, value in rows:
        list_row(draw, (x1, y, x2, y + 110), title, subtitle, value)
        y += 128
    rounded(draw, (x1, y + 20, x2, y + 154), 22, GREEN_SOFT, outline=(190, 224, 204), width=2)
    text(draw, (x1 + 24, y + 46), "Slow-moving stock alerts", 23, fill=CHARCOAL, bold=True)
    multiline(draw, (x1 + 24, y + 82), "See items that have been sitting longest before you buy more stock.", x2 - x1 - 48, 18, fill=MUTED)


def phone_screen_calculator(draw, box):
    x1, y1, x2, y2 = box
    draw_top_bar(draw, (x1, y1, x2, y2), "Profit Calculator")
    fields = [
        ("Purchase price", "GBP 18.00"),
        ("Selling price", "GBP 45.00"),
        ("Platform fee", "GBP 4.95"),
        ("Shipping", "GBP 3.49"),
        ("Packaging", "GBP 0.80"),
        ("Promotion", "GBP 2.00"),
    ]
    y = y1 + 146
    for label, value in fields:
        rounded(draw, (x1, y, x2, y + 72), 18, WHITE, outline=LINE, width=2)
        text(draw, (x1 + 22, y + 22), label, 18, fill=MUTED)
        text(draw, (x2 - 22, y + 20), value, 20, fill=CHARCOAL, bold=True, anchor="ra")
        y += 86
    rounded(draw, (x1, y + 22, x2, y + 252), 26, (18, 104, 69))
    text(draw, (x1 + 28, y + 54), "Estimated net profit", 23, fill=(220, 246, 232), bold=True)
    text(draw, (x1 + 28, y + 98), "GBP 15.76", 50, fill=WHITE, bold=True)
    text(draw, (x1 + 28, y + 170), "Margin 35%   ROI 88%   Break-even GBP 29.24", 20, fill=(220, 246, 232))


def phone_screen_ai(draw, box):
    x1, y1, x2, y2 = box
    draw_top_bar(draw, (x1, y1, x2, y2), "AI Listing")
    rounded(draw, (x1, y1 + 142, x2, y1 + 340), 24, WHITE, outline=LINE, width=2)
    text(draw, (x1 + 24, y1 + 170), "Generated title", 20, fill=MUTED)
    multiline(draw, (x1 + 24, y1 + 210), "Nike Vintage Windbreaker Jacket Size M Excellent Condition", x2 - x1 - 48, 26, fill=CHARCOAL, bold=True)
    rounded(draw, (x1, y1 + 366, x2, y1 + 640), 24, WHITE, outline=LINE, width=2)
    text(draw, (x1 + 24, y1 + 394), "Description draft", 20, fill=MUTED)
    multiline(draw, (x1 + 24, y1 + 432), "Clean preloved jacket with bold colour blocking, zip closure and light wear. Check current marketplace comps before listing.", x2 - x1 - 48, 21, fill=CHARCOAL)
    rounded(draw, (x1, y1 + 668, x2, y1 + 832), 24, GREEN_SOFT, outline=(190, 224, 204), width=2)
    text(draw, (x1 + 24, y1 + 696), "Suggested price range", 21, fill=GREEN_DARK, bold=True)
    text(draw, (x1 + 24, y1 + 742), "GBP 34 - GBP 52", 38, fill=GREEN_DARK, bold=True)
    text(draw, (x1 + 24, y1 + 796), "Check sold comps before publishing.", 18, fill=MUTED)


def phone_screen_analytics(draw, box):
    x1, y1, x2, y2 = box
    draw_top_bar(draw, (x1, y1, x2, y2), "Analytics")
    card(draw, (x1, y1 + 138, x2, y1 + 300), "Average days to sell", "14 days", PURPLE, "Tracked sales")
    labels = ["Vinted", "eBay", "Depop", "Etsy"]
    values = [380, 270, 190, 120]
    rounded(draw, (x1, y1 + 326, x2, y1 + 630), 24, WHITE, outline=LINE, width=2)
    text(draw, (x1 + 24, y1 + 354), "Profit by marketplace", 24, fill=CHARCOAL, bold=True)
    max_v = max(values)
    y = y1 + 414
    for label, value in zip(labels, values):
        text(draw, (x1 + 24, y + 8), label, 18, fill=MUTED)
        rounded(draw, (x1 + 122, y, x1 + 122 + (x2 - x1 - 170) * value / max_v, y + 32), 16, GREEN)
        text(draw, (x2 - 24, y + 4), f"GBP {value}", 18, fill=CHARCOAL, bold=True, anchor="ra")
        y += 48
    mini_chart(draw, (x1, y1 + 660, x2, y1 + 944), [10, 19, 13, 28, 25, 36, 51, 48], ORANGE)


def phone_screen_paywall(draw, box):
    x1, y1, x2, y2 = box
    draw_top_bar(draw, (x1, y1, x2, y2), "Plans")
    text(draw, (x1, y1 + 126), "Unlock FlipLedger AI", 32, fill=CHARCOAL, bold=True)
    multiline(draw, (x1, y1 + 176), "Unlimited tracking, AI listing tools, analytics and exports for serious resellers.", x2 - x1, 21, fill=MUTED)
    plans = [
        ("Pro Monthly", "GBP 9.99/mo", "AI tools, exports and unlimited tracking", GREEN),
        ("Pro Yearly", "GBP 79.99/yr", "Best value for growing resellers", BLUE),
        ("Business Monthly", "GBP 24.99/mo", "Advanced reports and sourcing insights", PURPLE),
    ]
    y = y1 + 300
    for name, price, desc, accent in plans:
        rounded(draw, (x1, y, x2, y + 178), 24, WHITE, outline=accent, width=3 if name == "Pro Yearly" else 2)
        text(draw, (x1 + 24, y + 28), name, 24, fill=CHARCOAL, bold=True)
        text(draw, (x1 + 24, y + 70), price, 31, fill=accent, bold=True)
        text(draw, (x1 + 24, y + 120), desc, 18, fill=MUTED)
        rounded(draw, (x2 - 168, y + 56, x2 - 24, y + 112), 20, accent)
        text(draw, (x2 - 96, y + 84), "Choose", 18, fill=WHITE, bold=True, anchor="mm")
        y += 206
    rounded(draw, (x1, y + 24, x2, y + 146), 22, GREEN_SOFT, outline=(190, 224, 204), width=2)
    multiline(draw, (x1 + 24, y + 50), "Free plan includes 25 inventory items, 10 sales per month and the basic profit calculator.", x2 - x1 - 48, 20, fill=GREEN_DARK, bold=True)
    text(draw, (x1, y + 184), "Restore purchases", 20, fill=GREEN_DARK, bold=True)


PHONE_SCREENS = [
    ("01-dashboard.png", "Track profit clearly", "Revenue, profit, stock value and quick actions in one dashboard.", phone_screen_dashboard),
    ("02-inventory.png", "Know what you own", "Manage purchase cost, source, photos, condition and target price.", phone_screen_inventory),
    ("03-profit-calculator.png", "Avoid fee surprises", "Calculate margin, ROI, break-even price and minimum selling price.", phone_screen_calculator),
    ("04-ai-listing.png", "Draft listings faster", "Generate cautious titles, descriptions, keywords and price ranges.", phone_screen_ai),
    ("05-analytics.png", "Find what sells", "See profit by marketplace, category, month, brand and source.", phone_screen_analytics),
]


def create_phone_screenshot(filename, headline, subhead, renderer):
    w, h = 1320, 2868
    img = gradient((w, h), (252, 255, 253), (229, 243, 236))
    draw = ImageDraw.Draw(img)
    text(draw, (86, 90), "FlipLedger AI", 38, fill=GREEN_DARK, bold=True)
    y = multiline(draw, (86, 174), headline, 760, 76, fill=CHARCOAL, bold=True, line_gap=14)
    multiline(draw, (86, y + 10), subhead, 760, 33, fill=MUTED, line_gap=10)
    frame = phone_frame(draw, 238, 620, 844, 2078)
    renderer(draw, frame)
    rounded(draw, (86, h - 206, w - 86, h - 126), 32, CHARCOAL)
    text(draw, (w / 2, h - 166), "Profit calculations are estimates. Check fees and comps.", 27, fill=WHITE, bold=True, anchor="mm")
    img.save(ASSET_ROOT / "iPhone-6.9" / filename)


def create_ipad_screenshot(filename, headline, subhead, renderer):
    w, h = 2048, 2732
    img = gradient((w, h), (252, 255, 253), (229, 243, 236))
    draw = ImageDraw.Draw(img)
    text(draw, (118, 96), "FlipLedger AI", 44, fill=GREEN_DARK, bold=True)
    y = multiline(draw, (118, 184), headline, 900, 82, fill=CHARCOAL, bold=True, line_gap=16)
    multiline(draw, (118, y + 12), subhead, 900, 34, fill=MUTED, line_gap=10)
    frame = tablet_frame(draw, 470, 560, 1110, 1800)
    renderer(draw, frame)
    rounded(draw, (118, h - 210, w - 118, h - 126), 34, CHARCOAL)
    text(draw, (w / 2, h - 168), "Local-first reseller tracking with cautious AI estimates.", 30, fill=WHITE, bold=True, anchor="mm")
    img.save(ASSET_ROOT / "iPad-13" / filename)


def create_screenshots():
    for item in PHONE_SCREENS:
        create_phone_screenshot(*item)
        create_ipad_screenshot(*item)
    create_phone_screenshot(
        "paywall-review.png",
        "Subscription review asset",
        "Use this screenshot in each App Store Connect subscription Review Information section.",
        phone_screen_paywall,
    )
    generated = ASSET_ROOT / "iPhone-6.9" / "paywall-review.png"
    generated.replace(ASSET_ROOT / "SubscriptionReview" / "paywall-review.png")


def main():
    ensure_dirs()
    create_icon()
    create_screenshots()


if __name__ == "__main__":
    main()
