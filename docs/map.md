# Weltendaemmerung Map System

This document describes the terrain types, tile mappings, and movement mechanics used in the game.

## Map Structure

- **Map Size**: 80 x 40 tiles (stored at $5000-$5FA0)
- **Tile Size**: 8x8 pixels
- **Character Set**: Custom tiles loaded at $E2F0 (character codes $5E-$83)

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

The terrain display index is calculated in `sub_1F1C` (`$1E8B-$2306_sound_effects.asm:127-131`):

```
terrain_index = char_code - $69
```

This maps each character code to a terrain type name via the lookup table at `$1D39`:

| Char Code | Tile | Index | German    | English   | Tile File       |
|-----------|------|-------|-----------|-----------|-----------------|
| $69       | 11   | 0     | Wiese     | Meadow    | `tile_11.png`   |
| $6A       | 12   | 1     | Fluss     | River     | `tile_12.png`   |
| $6B       | 13   | 2     | Wald      | Forest    | `tile_13.png`   |
| $6C       | 14   | 3     | Ende      | Edge      | `tile_14.png`   |
| $6D       | 15   | 4     | Sumpf     | Swamp     | `tile_15.png`   |
| $6E       | 16   | 5     | Tor       | Gate      | `tile_16.png`   |
| $6F       | 17   | 6     | Gebirge   | Mountains | `tile_17.png`   |
| $70       | 18   | 7     | Pflaster  | Pavement  | `tile_18.png`   |
| $71       | 19   | 8     | Mauer     | Wall      | `tile_19.png`   |
| $72       | 20   | 9     | -         | (terrain) | `tile_20.png`   |
| $73       | 21   | 10    | -         | (terrain) | `tile_21.png`   |
| < $69     | 0-10 | 9     | Mauer     | Wall      | (default)       |

**Note**: Units on the map are stored as `unit_type + $74` (character codes $74-$83), which is why tiles 22-37 contain unit type icons rather than terrain.

## Tile Index to Character Code Mapping

Tiles are stored at $E2F0, making tile 0 = character code $5E (94 decimal).

| Tile Index | Char Code | Color      | Terrain/Purpose                    |
|------------|-----------|------------|------------------------------------|
| 0-10       | $5E-$68   | Dark Gray  | UI borders, frame elements         |
| 11         | $69       | Black      | Wiese (Meadow)                     |
| 12         | $6A       | Black      | Fluss (River)                      |
| 13         | $6B       | Blue       | Wald (Forest)                      |
| 14         | $6C       | Red        | Ende (Edge)                        |
| 15         | $6D       | White      | Sumpf (Swamp)                      |
| 16         | $6E       | Blue       | Tor (Gate)                         |
| 17         | $6F       | Dark Gray  | Gebirge (Mountains)                |
| 18         | $70       | Dark Gray  | Pflaster (Pavement)                |
| 19         | $71       | Dark Gray  | Mauer (Wall)                       |
| 20-21      | $72-$73   | Dark Gray  | Additional terrain                 |
| 22-28      | $74-$7A   | Yellow     | Unit type icons                    |
| 29-37      | $7B-$83   | Black      | Additional unit icons              |

## Color Mapping

Colors are determined by the `sub_1C01` function in `$1A3F-$1E8A_utilities_render.asm`:

| Char Code Range | Color Code | C64 Color |
|-----------------|------------|-----------|
| $00-$68        | $0B        | Dark Gray    |
| $69            | $00        | Black        |
| $6A            | $00        | Black        |
| $6B            | $06        | Blue         |
| $6C            | $02        | Red          |
| $6D            | $01        | White        |
| $6E            | $06        | Blue         |
| $6F-$73        | $0B        | Dark Gray    |
| $74-$7A        | $07        | Yellow       |
| $7B+           | $00        | Black        |

