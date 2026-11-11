"""Extract exact pixel crops from the approved Ludo Lovers board artwork.

Usage (from repository root):
  python scripts/extract_approved_board_layers.py

Requires Pillow. Never writes to or modifies the canonical source.
The cropped board retains every original star/safe cell and home pocket.
"""
from pathlib import Path
from PIL import Image
import json

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "apps/mobile/assets/images/board/ludo_board_glass.webp"
DEST = ROOT / "apps/mobile/assets/images/board/extracted"
REFERENCE_WIDTH, REFERENCE_HEIGHT = 864, 1536
REGIONS = {
    "board_exact": (15, 307, 850, 1158),
    "header_logo": (284, 0, 580, 306),
    "avatar_aldo": (35, 64, 194, 232),
    "avatar_you": (670, 64, 829, 232),
    "avatar_bob": (37, 1172, 183, 1315),
    "avatar_emma": (680, 1172, 825, 1315),
    "dice_decorative_reference": (293, 1181, 575, 1403),
    "chat_reference": (31, 1395, 146, 1535),
    "more_reference": (716, 1395, 833, 1535),
    "turn_banner_reference": (265, 1396, 595, 1486),
}

def main():
    with Image.open(SOURCE) as image:
        width, height = image.size
        if width * REFERENCE_HEIGHT != height * REFERENCE_WIDTH:
            raise ValueError(f"Unexpected aspect ratio: {width}x{height}")
        DEST.mkdir(parents=True, exist_ok=True)
        manifest = {"source": str(SOURCE.relative_to(ROOT)), "size": [width, height], "parts": {}}
        for name, rect in REGIONS.items():
            scaled = (
                round(rect[0] * width / REFERENCE_WIDTH),
                round(rect[1] * height / REFERENCE_HEIGHT),
                round(rect[2] * width / REFERENCE_WIDTH),
                round(rect[3] * height / REFERENCE_HEIGHT),
            )
            image.crop(scaled).save(DEST / f"{name}.png")
            manifest["parts"][name] = list(scaled)
        (DEST / "manifest.json").write_text(json.dumps(manifest, indent=2))
        print(f"Extracted {len(REGIONS)} unchanged source crops into {DEST}")

if __name__ == "__main__":
    main()
