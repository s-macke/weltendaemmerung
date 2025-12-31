#!/usr/bin/env python3
"""
Extract map and unit placement data from Weltendaemmerung C64 binary
and output TypeScript data files for the web port.
"""

from pathlib import Path
import json

# Binary file location
BINARY_PATH = Path(__file__).parent.parent / "disassembly" / "archive" / "weltendaemmerung.bin"

# Output directory for TypeScript files
OUTPUT_DIR = Path(__file__).parent.parent / "web" / "src" / "data"

# Map dimensions
MAP_WIDTH = 80
MAP_HEIGHT = 40

# File offsets (accounting for 2-byte PRG load address header)
# Binary starts at $0801, so offset = address - $0801 + 2
MAP_DATA_OFFSET = 0x0F89    # $1788 - $0801 + 2
UNIT_DATA_OFFSET = 0x0858   # $1057 - $0801 + 2

# Terrain character codes
TERRAIN_CODES = {
    0x69: 'Meadow1',
    0x6A: 'Meadow2',
    0x6B: 'River',
    0x6C: 'Forest',
    0x6D: 'End',
    0x6E: 'Swamp',
    0x6F: 'Gate',
    0x70: 'Mountains',
    0x71: 'Pavement',
    0x72: 'Wall1',
    0x73: 'Wall2',
}

# Unit type info: (German name, English name, owner: 0=Eldoin, 1=Dailor)
UNIT_INFO = [
    ('Schwertträger', 'Sword Bearers', 0),      # 0
    ('Bogenschützen', 'Archers', 0),            # 1
    ('Adler', 'Eagle', 0),                      # 2
    ('Lanzenträger', 'Spear Bearers', 0),       # 3
    ('Kriegsschiff', 'Warship', 0),             # 4
    ('Reiterei', 'Cavalry', 0),                 # 5
    ('Feldherr', 'Commander', 0),               # 6 - ELDOIN'S COMMANDER (victory condition)
    ('Bogenschützen', 'Archers', 1),            # 7
    ('Katapult', 'Catapult', 1),                # 8
    ('Blutsauger', 'Bloodsucker', 1),           # 9
    ('Axtmänner', 'Axe Men', 1),                # 10
    ('Feldherr', 'Commander', 1),               # 11
    ('Lindwurm', 'Dragon', 1),                  # 12
    ('Rammbock', 'Battering Ram', 1),           # 13
    ('Wagenfahrer', 'Wagon Drivers', 1),        # 14
    ('Wolfsreiter', 'Wolf Riders', 1),          # 15
]


def decompress_map(binary_data: bytes) -> list[int]:
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


def parse_unit_placement(binary_data: bytes) -> list[dict]:
    """
    Parse the unit placement data from the binary.

    Format:
    - $8X: Unit type marker (X = 0-15)
    - X, Y pairs: Coordinates for each unit
    - $FF: End of data

    Returns list of unit dictionaries with x, y, type, owner
    """
    units = []
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

                if current_type < len(UNIT_INFO):
                    _, _, owner = UNIT_INFO[current_type]
                    units.append({
                        'x': x,
                        'y': y,
                        'type': current_type,
                        'owner': owner,
                    })
                offset += 2
            else:
                offset += 1

    return units


def convert_terrain_to_enum(char_code: int) -> str:
    """Convert character code to terrain enum value."""
    terrain_map = {
        0x69: 'TerrainType.Meadow',
        0x6A: 'TerrainType.Meadow',  # Variant 2, same as meadow
        0x6B: 'TerrainType.River',
        0x6C: 'TerrainType.Forest',
        0x6D: 'TerrainType.End',
        0x6E: 'TerrainType.Swamp',
        0x6F: 'TerrainType.Gate',
        0x70: 'TerrainType.Mountains',
        0x71: 'TerrainType.Pavement',
        0x72: 'TerrainType.Wall',
        0x73: 'TerrainType.Wall',  # Variant 2, same as wall
    }
    return terrain_map.get(char_code, 'TerrainType.Meadow')


def generate_map_ts(map_data: list[int]) -> str:
    """Generate TypeScript file with map data."""
    lines = [
        "// Auto-generated map data from Weltendaemmerung C64 binary",
        "// DO NOT EDIT - regenerate with tools/extract_map_data.py",
        "",
        "import { TerrainType } from '../types';",
        "",
        "export const MAP_WIDTH = 80;",
        "export const MAP_HEIGHT = 40;",
        "",
        "// Raw character codes from C64 binary (for tile rendering)",
        "// $69-$6A = Meadow, $6B = River, $6C = Forest, $6D = End,",
        "// $6E = Swamp, $6F = Gate, $70 = Mountains, $71 = Pavement, $72-$73 = Wall",
        "export const MAP_CHAR_CODES: number[] = [",
    ]

    # Output map data as rows
    for y in range(MAP_HEIGHT):
        row_start = y * MAP_WIDTH
        row_end = row_start + MAP_WIDTH
        row_data = map_data[row_start:row_end]
        hex_values = ', '.join(f'0x{v:02X}' for v in row_data)
        lines.append(f"  {hex_values},  // Row {y}")

    lines.append("];")
    lines.append("")

    # Generate terrain type array
    lines.append("// Terrain types for game logic (derived from char codes)")
    lines.append("export const MAP_TERRAIN: TerrainType[] = [")

    for y in range(MAP_HEIGHT):
        row_start = y * MAP_WIDTH
        row_end = row_start + MAP_WIDTH
        row_data = map_data[row_start:row_end]
        terrain_values = ', '.join(convert_terrain_to_enum(v) for v in row_data)
        lines.append(f"  {terrain_values},")

    lines.append("];")
    lines.append("")

    # Helper function
    lines.append("// Get terrain at map coordinates")
    lines.append("export function getTerrainAt(x: number, y: number): TerrainType {")
    lines.append("  if (x < 0 || x >= MAP_WIDTH || y < 0 || y >= MAP_HEIGHT) {")
    lines.append("    return TerrainType.End;")
    lines.append("  }")
    lines.append("  return MAP_TERRAIN[y * MAP_WIDTH + x]!;")
    lines.append("}")
    lines.append("")

    lines.append("// Get raw char code at map coordinates (for rendering)")
    lines.append("export function getCharCodeAt(x: number, y: number): number {")
    lines.append("  if (x < 0 || x >= MAP_WIDTH || y < 0 || y >= MAP_HEIGHT) {")
    lines.append("    return 0x6D; // End marker")
    lines.append("  }")
    lines.append("  return MAP_CHAR_CODES[y * MAP_WIDTH + x]!;")
    lines.append("}")
    lines.append("")

    return '\n'.join(lines)


def generate_initial_units_ts(units: list[dict]) -> str:
    """Generate TypeScript file with initial unit placement."""
    lines = [
        "// Auto-generated unit placement data from Weltendaemmerung C64 binary",
        "// DO NOT EDIT - regenerate with tools/extract_map_data.py",
        "",
        "import { Player } from '../types';",
        "",
        "export interface InitialUnitData {",
        "  x: number;",
        "  y: number;",
        "  type: number;",
        "  owner: Player;",
        "}",
        "",
        f"// Total units: {len(units)}",
    ]

    # Count by owner
    eldoin_count = sum(1 for u in units if u['owner'] == 0)
    dailor_count = sum(1 for u in units if u['owner'] == 1)
    lines.append(f"// Eldoin: {eldoin_count} units, Dailor: {dailor_count} units")
    lines.append("")

    lines.append("export const INITIAL_UNITS: InitialUnitData[] = [")

    for unit in units:
        owner_str = "Player.Eldoin" if unit['owner'] == 0 else "Player.Dailor"
        lines.append(f"  {{ x: {unit['x']}, y: {unit['y']}, type: {unit['type']}, owner: {owner_str} }},")

    lines.append("];")
    lines.append("")

    return '\n'.join(lines)


def main():
    print(f"Loading binary: {BINARY_PATH}")

    if not BINARY_PATH.exists():
        print(f"Error: Binary file not found at {BINARY_PATH}")
        return 1

    with open(BINARY_PATH, "rb") as f:
        binary_data = f.read()

    print(f"Binary size: {len(binary_data)} bytes")

    # Decompress map
    print("Decompressing map...")
    map_data = decompress_map(binary_data)
    print(f"Decompressed {len(map_data)} tiles (expected {MAP_WIDTH * MAP_HEIGHT})")

    # Parse unit placement
    print("Parsing unit placement...")
    units = parse_unit_placement(binary_data)
    print(f"Found {len(units)} units")

    # Count by type and owner
    eldoin_count = sum(1 for u in units if u['owner'] == 0)
    dailor_count = sum(1 for u in units if u['owner'] == 1)
    print(f"  Eldoin: {eldoin_count} units")
    print(f"  Dailor: {dailor_count} units")

    # Create output directory
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Generate and write map.ts
    print(f"\nGenerating {OUTPUT_DIR / 'map.ts'}...")
    map_ts = generate_map_ts(map_data)
    with open(OUTPUT_DIR / "map.ts", "w") as f:
        f.write(map_ts)

    # Generate and write initialUnits.ts
    print(f"Generating {OUTPUT_DIR / 'initialUnits.ts'}...")
    units_ts = generate_initial_units_ts(units)
    with open(OUTPUT_DIR / "initialUnits.ts", "w") as f:
        f.write(units_ts)

    print("\nDone! TypeScript data files generated.")
    return 0


if __name__ == "__main__":
    exit(main())
