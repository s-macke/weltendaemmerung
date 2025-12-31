#!/usr/bin/env python3
"""
Extract and render the game map from Weltendaemmerung C64 binary.

Decompresses the map from its RLE format and renders it with correct C64 colors.
"""

from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Error: PIL/Pillow is required. Install with: pip install Pillow")
    exit(1)

# Binary file location
BINARY_PATH = Path(__file__).parent.parent / "disassembly" / "archive" / "weltendaemmerung.bin"

# Output paths
OUTPUT_DIR = Path(__file__).parent.parent / "assets"
MAP_OUTPUT = OUTPUT_DIR / "map.png"
MAP_WITH_UNITS_OUTPUT = OUTPUT_DIR / "map_with_units.png"

# Map dimensions
MAP_WIDTH = 80
MAP_HEIGHT = 40

# Tile dimensions
TILE_SIZE = 8

# File offsets (accounting for 2-byte PRG load address header)
TILE_DATA_OFFSET = 0x0DF1   # $15F0 - $0801 + 2
MAP_DATA_OFFSET = 0x0F89    # $1788 - $0801 + 2
UNIT_DATA_OFFSET = 0x0858   # $1057 - $0801 + 2 (unit placement table)

# Number of tiles
NUM_TILES = 38

# Unit type names (German/English)
UNIT_NAMES = [
    ("Schwertträger", "Swordsmen"),      # 0
    ("Bogenschützen", "Archers"),        # 1
    ("Adler", "Eagles"),                 # 2
    ("Lanzenträger", "Lancers"),         # 3
    ("Kriegsschiff", "Warship"),         # 4
    ("Reiterei", "Cavalry"),             # 5
    ("Katapult", "Catapult"),            # 6
    ("Blutsauger", "Bloodsucker"),       # 7
    ("Axtmänner", "Axemen"),             # 8
    ("Feldherr", "Commander"),           # 9
    ("Lindwurm", "Dragon/Wyrm"),         # 10
    ("Rammbock", "Battering Ram"),       # 11
    ("Wagenfahrer", "Wagon Driver"),     # 12
    ("Wolfsreiter", "Wolf Riders"),      # 13
    ("Unit14", "Unit14"),                # 14
    ("Unit15", "Unit15"),                # 15
]

# C64 Color Palette (RGB tuples)
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

# Background color (Green - set via raster interrupt during map display)
BG_COLOR = 0x05  # Green

# Color lookup table for char codes $69-$73 (terrain types)
COLOR_LOOKUP = [0x00, 0x00, 0x06, 0x02, 0x01, 0x06, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B]


def get_tile_color(char_code: int) -> int:
    """
    Get foreground color for a character code based on game's color mapping.

    Color mapping (from sub_1C01 in the game code):
    - $00-$68: Dark Gray ($0B)
    - $69-$73: Lookup table (terrain colors)
    - $74-$7A: Yellow ($07) - unit icons
    - $7B+:    Black ($00) - unit icons
    """
    if char_code < 0x69:
        return 0x0B  # Dark Gray (UI elements)
    elif char_code < 0x74:
        idx = char_code - 0x69
        if idx < len(COLOR_LOOKUP):
            return COLOR_LOOKUP[idx]
        return 0x0B
    elif char_code < 0x7B:
        return 0x07  # Yellow (unit icons)
    else:
        return 0x00  # Black (unit icons)


def load_tiles(binary_data: bytes) -> dict:
    """Load tile graphics data from binary."""
    tiles = {}
    offset = TILE_DATA_OFFSET

    for i in range(NUM_TILES):
        tile_data = binary_data[offset:offset + 8]
        char_code = 0x5E + i  # Tiles map to char codes $5E-$83
        tiles[char_code] = tile_data
        offset += 8

    return tiles


def decompress_map(binary_data: bytes) -> list:
    """
    Decompress the map data using the game's RLE algorithm.

    Algorithm (from sub_1721):
    - Read byte from source
    - If byte == $FF: terminate
    - If byte < $04: output (byte + $72) once
    - Otherwise:
      - High nibble = repeat count
      - Low nibble: terrain code calculation
        - If < 8: terrain = nibble + $6A
        - If >= 8: terrain = nibble - $11 + $6A (wraps around)
    """
    map_data = []
    offset = MAP_DATA_OFFSET

    while len(map_data) < MAP_WIDTH * MAP_HEIGHT:
        byte = binary_data[offset]
        offset += 1

        if byte == 0xFF:
            break

        if byte < 0x04:
            # Special case: output (byte + $72) once
            terrain = byte + 0x72
            map_data.append(terrain)
        else:
            # RLE: high nibble = count, low nibble = terrain code
            count = (byte >> 4) & 0x0F
            low = byte & 0x0F

            if low < 0x08:
                terrain = low + 0x6A
            else:
                # 6502 subtraction with underflow: low - $11 wraps
                terrain = ((low - 0x11) & 0xFF) + 0x6A
                # Clamp to valid range
                if terrain > 0x83:
                    terrain = terrain & 0xFF

            for _ in range(count):
                map_data.append(terrain)

    return map_data


def parse_unit_placement(binary_data: bytes) -> dict:
    """
    Parse the unit placement data from the binary.

    Format:
    - $8X: Unit type marker (X = 0-15)
    - X, Y pairs: Coordinates for each unit
    - $FF: End of data

    Returns dict mapping unit_type -> list of (x, y) positions
    """
    units = {i: [] for i in range(16)}
    offset = UNIT_DATA_OFFSET
    current_type = None

    while offset < len(binary_data):
        byte = binary_data[offset]

        if byte == 0xFF:
            break
        elif byte >= 0x80:
            current_type = byte - 0x80
            offset += 1
        else:
            if current_type is not None and offset + 1 < len(binary_data):
                x = binary_data[offset]
                y = binary_data[offset + 1]
                units[current_type].append((x, y))
                offset += 2
            else:
                offset += 1

    return units


def render_tile(img: Image.Image, tiles: dict, char_code: int, x: int, y: int):
    """Render a single tile at the given position with correct color."""
    # Get tile graphics (default to char $69/meadow if not found)
    if char_code in tiles:
        tile_data = tiles[char_code]
    elif char_code >= 0x5E and char_code <= 0x83:
        # Map to available tiles
        tile_data = tiles.get(char_code, tiles.get(0x69, b'\x00' * 8))
    else:
        # Use meadow tile for unknown codes
        tile_data = tiles.get(0x69, b'\x00' * 8)

    # Get colors
    fg_color = C64_PALETTE[get_tile_color(char_code)]
    bg_color = C64_PALETTE[BG_COLOR]

    pixels = img.load()

    # Render 8x8 tile
    for row in range(8):
        if row < len(tile_data):
            byte = tile_data[row]
        else:
            byte = 0

        for col in range(8):
            bit = (byte >> (7 - col)) & 1
            px = x * TILE_SIZE + col
            py = y * TILE_SIZE + row
            pixels[px, py] = fg_color if bit else bg_color


def main():
    print(f"Loading binary: {BINARY_PATH}")

    if not BINARY_PATH.exists():
        print(f"Error: Binary file not found at {BINARY_PATH}")
        return 1

    with open(BINARY_PATH, "rb") as f:
        binary_data = f.read()

    print(f"Binary size: {len(binary_data)} bytes")

    # Load tile graphics
    print("Loading tile graphics...")
    tiles = load_tiles(binary_data)
    print(f"Loaded {len(tiles)} tiles (char codes $5E-$83)")

    # Decompress map
    print("Decompressing map...")
    map_data = decompress_map(binary_data)
    print(f"Decompressed {len(map_data)} tiles (expected {MAP_WIDTH * MAP_HEIGHT})")

    # Analyze terrain distribution
    terrain_counts = {}
    for char_code in map_data:
        terrain_counts[char_code] = terrain_counts.get(char_code, 0) + 1

    terrain_names = {
        0x69: "Wiese (Meadow)",
        0x6A: "Fluss (River)",
        0x6B: "Wald (Forest)",
        0x6C: "Ende (Edge)",
        0x6D: "Sumpf (Swamp)",
        0x6E: "Tor (Gate)",
        0x6F: "Gebirge (Mountains)",
        0x70: "Pflaster (Pavement)",
        0x71: "Mauer (Wall)",
        0x72: "Terrain variant 1",
        0x73: "Terrain variant 2",
    }

    print("\nTerrain distribution:")
    for code in sorted(terrain_counts.keys()):
        name = terrain_names.get(code, f"Unknown ${code:02X}")
        print(f"  ${code:02X}: {terrain_counts[code]:4d} tiles - {name}")

    # Create output image
    img_width = MAP_WIDTH * TILE_SIZE
    img_height = MAP_HEIGHT * TILE_SIZE

    print(f"\nRendering {img_width}x{img_height} pixel map...")
    img = Image.new("RGB", (img_width, img_height), C64_PALETTE[BG_COLOR])

    # Render all tiles
    for y in range(MAP_HEIGHT):
        for x in range(MAP_WIDTH):
            idx = y * MAP_WIDTH + x
            if idx < len(map_data):
                char_code = map_data[idx]
                render_tile(img, tiles, char_code, x, y)

    # Save terrain-only map
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    img.save(MAP_OUTPUT)
    print(f"\nTerrain map saved to: {MAP_OUTPUT}")

    # Parse unit placement
    print("\nParsing unit placement data...")
    units = parse_unit_placement(binary_data)

    # Count and display unit distribution
    total_units = 0
    eldoin_count = 0
    dailor_count = 0

    print("\nUnit distribution:")
    for unit_type in range(16):
        if units[unit_type]:
            count = len(units[unit_type])
            total_units += count
            german, english = UNIT_NAMES[unit_type]

            # Count by faction (X < 40 = Eldoin, X >= 40 = Dailor)
            left = sum(1 for x, y in units[unit_type] if x < 40)
            right = count - left
            eldoin_count += left
            dailor_count += right

            print(f"  Type {unit_type:2d} ({english:15s}): {count:3d} units "
                  f"(Eldoin: {left:3d}, Dailor: {right:3d})")

    print(f"\nTotal: {total_units} units (Eldoin: {eldoin_count}, Dailor: {dailor_count})")

    # Create map with units
    print(f"\nRendering map with units...")
    img_with_units = img.copy()

    # Render units on top of terrain
    for unit_type in range(16):
        char_code = 0x74 + unit_type  # Unit tiles are $74-$83
        for x, y in units[unit_type]:
            if 0 <= x < MAP_WIDTH and 0 <= y < MAP_HEIGHT:
                render_tile(img_with_units, tiles, char_code, x, y)

    # Save map with units
    img_with_units.save(MAP_WITH_UNITS_OUTPUT)
    print(f"Map with units saved to: {MAP_WITH_UNITS_OUTPUT}")

    return 0


if __name__ == "__main__":
    exit(main())
