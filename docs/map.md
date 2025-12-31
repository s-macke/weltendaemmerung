# Weltendaemmerung Map System

This document describes the terrain types, tile mappings, and movement mechanics used in the game.

## Map Structure

- **Map Size**: 80 x 40 tiles (3200 tiles total)
- **Runtime Location**: Decompressed to $5000-$5FA0
- **Compressed Data**: Stored at $1788 in the binary (RLE encoded)
- **Tile Size**: 8x8 pixels
- **Character Set**: Custom tiles loaded at $E2F0 (character codes $5E-$83)
- **Background Color**: Green ($05) - set via raster interrupt during map display
- **Border Color**: Blue ($06)

## Map Compression

The map data is stored in a custom RLE (Run-Length Encoding) format, decompressed by `sub_1721` in `$15CD-$1A3E_graphics_data.asm`.

### Compression Algorithm

For each byte in the compressed stream:
- `$FF`: End of data
- `$00-$03`: Output character code `(byte + $72)` once
- `$04-$FE`: RLE encoded
  - High nibble = repeat count
  - Low nibble = terrain code:
    - If < 8: terrain = `nibble + $6A`
    - If >= 8: terrain = `(nibble - $11) + $6A` (with 8-bit wraparound)

### Extracted Map

The full map can be extracted using `tools/extract_map.py`, which outputs to `assets/map.png` (640x320 pixels).

![Game Map](../assets/map.png)

## Terrain Types

The game uses German terrain names found in the text data at `$1A3F-$1E8A_utilities_render.asm`:

| German Name | English       | Description                    |
|-------------|---------------|--------------------------------|
| Wiese       | Meadow        | Open grassland, easy traversal |
| Fluss       | River         | Water, blocks most ground units|
| Wald        | Forest        | Wooded area, slows movement    |
| Sumpf       | Swamp         | Marshy terrain, difficult      |
| Gebirge     | Mountains     | Highland, blocks some units    |
| Pflaster    | Pavement      | Road/path, fast movement       |
| Mauer       | Wall          | Defensive structure            |
| Tor         | Gate          | Passable structure             |
| Ende        | Edge          | Map boundary                   |

## Terrain-Tile Correlation

The terrain display index is calculated in `sub_1F1C` (`$1E8B-$2012_display_terrain.asm:108-131`):

```
terrain_index = char_code - $69
```

This maps each character code to a terrain type name via the lookup table at `$1D39`:

| Char Code | Tile | Index | German    | English   | Tile File       |
|-----------|------|-------|-----------|-----------|-----------------|
| $69       | 11   | 0     | Wiese     | Meadow    | `tile_11.png`   |
| $6A       | 12   | 1     | Wiese     | Meadow    | `tile_12.png`   |
| $6B       | 13   | 2     | Fluss     | River     | `tile_13.png`   |
| $6C       | 14   | 3     | Wald      | Forest    | `tile_14.png`   |
| $6D       | 15   | 4     | Ende      | Edge      | `tile_15.png`   |
| $6E       | 16   | 5     | Sumpf     | Swamp     | `tile_16.png`   |
| $6F       | 17   | 6     | Tor       | Gate      | `tile_17.png`   |
| $70       | 18   | 7     | Gebirge   | Mountains | `tile_18.png`   |
| $71       | 19   | 8     | Pflaster  | Pavement  | `tile_19.png`   |
| $72       | 20   | 9     | Mauer     | Wall      | `tile_20.png`   |
| $73       | 21   | 10    | Mauer     | Wall      | `tile_21.png`   |
| < $69     | 0-10 | 9     | Mauer     | Wall      | (default)       |

**Note**: Char codes $69 and $6A both display as "Wiese" (Meadow) - they are visual variants created by `sub_1766` during map decompression. Units on the map are stored as `unit_type + $74` (character codes $74-$83), which is why tiles 22-37 contain unit type icons rather than terrain.

## Tile Index to Character Code Mapping

Tiles are stored at $E2F0, making tile 0 = character code $5E (94 decimal).

| Tile Index | Char Code | Color      | Terrain/Purpose                    |
|------------|-----------|------------|------------------------------------|
| 0-10       | $5E-$68   | Dark Gray  | UI borders, frame elements         |
| 11         | $69       | Black      | Wiese (Meadow) - variant 1         |
| 12         | $6A       | Black      | Wiese (Meadow) - variant 2         |
| 13         | $6B       | Blue       | Fluss (River)                      |
| 14         | $6C       | Red        | Wald (Forest)                      |
| 15         | $6D       | White      | Ende (Edge)                        |
| 16         | $6E       | Blue       | Sumpf (Swamp)                      |
| 17         | $6F       | Dark Gray  | Tor (Gate)                         |
| 18         | $70       | Dark Gray  | Gebirge (Mountains)                |
| 19         | $71       | Dark Gray  | Pflaster (Pavement)                |
| 20-21      | $72-$73   | Dark Gray  | Mauer (Wall)                       |
| 22-28      | $74-$7A   | Yellow     | Unit type icons                    |
| 29-37      | $7B-$83   | Black      | Additional unit icons              |

## Color Mapping

Colors are determined by the `sub_1C01` function in `$1A3F-$1E8A_utilities_render.asm`.

The foreground colors are rendered against the **Green ($05) background**:

| Char Code Range | Color Code | C64 Color  | Visual Result                   |
|-----------------|------------|------------|---------------------------------|
| $00-$68         | $0B        | Dark Gray  | Gray on green (UI elements)     |
| $69             | $00        | Black      | Black pattern on green (Meadow) |
| $6A             | $00        | Black      | Black pattern on green (Meadow) |
| $6B             | $06        | Blue       | Blue waves on green (River)     |
| $6C             | $02        | Red        | Red trees on green (Forest)     |
| $6D             | $01        | White      | White markers (Edge)            |
| $6E             | $06        | Blue       | Blue pattern (Swamp)            |
| $6F-$73         | $0B        | Dark Gray  | Gray terrain (Tor/Gebirge/etc)  |
| $74-$7A         | $07        | Yellow     | Yellow unit icons               |
| $7B+            | $00        | Black      | Black unit icons                |


