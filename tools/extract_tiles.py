#!/usr/bin/env python3
"""
Extract character tiles from Weltendaemmerung C64 binary.

Extracts 8x8 pixel tiles from the custom character set and saves them as colored PNG files
using the authentic C64 color palette and the game's color mapping logic.
"""

from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Error: PIL/Pillow is required. Install with: pip install Pillow")
    exit(1)

# Binary file location (relative to project root)
BINARY_PATH = Path(__file__).parent.parent / "disassembly" / "archive" / "weltendaemmerung.bin"

# Output directory
OUTPUT_DIR = Path(__file__).parent.parent / "assets" / "tiles"

# Data offsets in binary file
TILE_DATA_START = 0x0DF1  # Offset where tile data begins
TILE_DATA_END = 0x0F21    # Terminator byte ($AB) location

# Tile dimensions
TILE_WIDTH = 8
TILE_HEIGHT = 8
BYTES_PER_TILE = 8

# C64 Color Palette (VICE default palette - RGB tuples)
C64_PALETTE = {
    0x00: (0x00, 0x00, 0x00),  # Black
    0x01: (0xFF, 0xFF, 0xFF),  # White
    0x02: (0x68, 0x37, 0x2B),  # Red
    0x03: (0x70, 0xA4, 0xB2),  # Cyan
    0x04: (0x6F, 0x3D, 0x86),  # Purple
    0x05: (0x58, 0x8D, 0x43),  # Green
    0x06: (0x35, 0x28, 0x79),  # Blue
    0x07: (0xB8, 0xC7, 0x6F),  # Yellow
    0x08: (0x6F, 0x4F, 0x25),  # Orange
    0x09: (0x43, 0x39, 0x00),  # Brown
    0x0A: (0x9A, 0x67, 0x59),  # Light Red
    0x0B: (0x44, 0x44, 0x44),  # Dark Gray
    0x0C: (0x6C, 0x6C, 0x6C),  # Gray
    0x0D: (0x9A, 0xD2, 0x84),  # Light Green
    0x0E: (0x6C, 0x5E, 0xB5),  # Light Blue
    0x0F: (0x95, 0x95, 0x95),  # Light Gray
}

# Game's color lookup table for tile indices $69-$73 (from $1C2A in the code)
# Maps (tile_index - 0x69) -> color code
COLOR_LOOKUP_TABLE = [0x00, 0x00, 0x06, 0x02, 0x01, 0x06, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B]

# Default background color (black)
BACKGROUND_COLOR = 0x00

# Character set base offset: tiles are loaded at $E2F0, charset base at $E000
# So tile 0 = character code ($E2F0 - $E000) / 8 = $5E = 94
CHAR_CODE_BASE = 0x5E  # First tile maps to character code 94


def get_tile_color(tile_index: int) -> int:
    """
    Get the foreground color for a tile based on game's sub_1C01 color mapping.

    The 38 custom tiles are loaded at $E2F0, mapping to character codes $5E-$83 (94-131).

    Color mapping from the game code (based on CHARACTER CODE, not tile index):
    - Char codes $00-$68 (0-104):   Color $0B (Dark Gray)
    - Char codes $69-$73 (105-115): Lookup table
    - Char codes $74-$7A (116-122): Color $07 (Yellow)
    - Char codes $7B+ (123+):       Color $00 (Black)
    """
    # Convert tile index to actual character code used in game
    char_code = CHAR_CODE_BASE + tile_index

    if char_code < 0x69:
        return 0x0B  # Dark Gray
    elif char_code < 0x74:
        lookup_index = char_code - 0x69
        if lookup_index < len(COLOR_LOOKUP_TABLE):
            return COLOR_LOOKUP_TABLE[lookup_index]
        return 0x0B
    elif char_code < 0x7B:
        return 0x07  # Yellow
    else:
        return 0x00  # Black


def extract_tiles(binary_path: Path) -> list[bytes]:
    """Extract tile data from the C64 binary file."""
    with open(binary_path, "rb") as f:
        f.seek(TILE_DATA_START)
        data = f.read(TILE_DATA_END - TILE_DATA_START)

    tiles = []
    for i in range(0, len(data), BYTES_PER_TILE):
        tile_data = data[i:i + BYTES_PER_TILE]
        if len(tile_data) == BYTES_PER_TILE:
            tiles.append(tile_data)

    return tiles


def tile_to_image(tile_data: bytes, fg_color: tuple, bg_color: tuple) -> Image.Image:
    """
    Convert 8-byte tile data to an 8x8 colored PIL Image.

    Each byte represents one row of 8 pixels.
    Bit 7 (MSB) = leftmost pixel, Bit 0 (LSB) = rightmost pixel.
    Bit value 1 = foreground color, 0 = background color.
    """
    img = Image.new("RGB", (TILE_WIDTH, TILE_HEIGHT), bg_color)
    pixels = img.load()

    for row, byte in enumerate(tile_data):
        for col in range(8):
            bit_position = 7 - col
            pixel_value = (byte >> bit_position) & 1
            if pixel_value:
                pixels[col, row] = fg_color

    return img


def save_tiles(tiles: list[bytes], output_dir: Path, use_game_colors: bool = True) -> None:
    """Save all tiles as colored PNG files."""
    output_dir.mkdir(parents=True, exist_ok=True)

    bg_rgb = C64_PALETTE[BACKGROUND_COLOR]

    for i, tile_data in enumerate(tiles):
        if use_game_colors:
            # Use game's color mapping based on tile index
            fg_code = get_tile_color(i)
        else:
            # Use cyan for better visibility
            fg_code = 0x03

        fg_rgb = C64_PALETTE[fg_code]
        img = tile_to_image(tile_data, fg_rgb, bg_rgb)

        filename = output_dir / f"tile_{i:02d}.png"
        img.save(filename)

        color_name = get_color_name(fg_code)
        print(f"Saved: {filename.name} (color: {color_name})")


def get_color_name(color_code: int) -> str:
    """Get human-readable color name."""
    names = {
        0x00: "Black", 0x01: "White", 0x02: "Red", 0x03: "Cyan",
        0x04: "Purple", 0x05: "Green", 0x06: "Blue", 0x07: "Yellow",
        0x08: "Orange", 0x09: "Brown", 0x0A: "Light Red", 0x0B: "Dark Gray",
        0x0C: "Gray", 0x0D: "Light Green", 0x0E: "Light Blue", 0x0F: "Light Gray"
    }
    return names.get(color_code, f"Unknown ({color_code})")


def main():
    print(f"Extracting tiles from: {BINARY_PATH}")
    print(f"Using C64 color palette with game's color mapping\n")

    if not BINARY_PATH.exists():
        print(f"Error: Binary file not found at {BINARY_PATH}")
        return 1

    tiles = extract_tiles(BINARY_PATH)
    print(f"Found {len(tiles)} tiles\n")

    save_tiles(tiles, OUTPUT_DIR, use_game_colors=True)
    print(f"\nAll tiles saved to: {OUTPUT_DIR}")

    return 0


if __name__ == "__main__":
    exit(main())
