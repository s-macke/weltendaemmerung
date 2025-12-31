# Weltendaemmerung Save Game Format

This document describes the save/load file format for the C64 game "Weltendaemmerung".

## Overview

The game saves the complete game state to disk using the KERNAL SAVE/LOAD routines. The save file contains a contiguous memory block that captures all dynamic game data.

## Save File Structure

| Memory Range  | Size (bytes) | Description                     |
|---------------|-------------:|---------------------------------|
| $4FF0-$4FFF   |           16 | Game State Variables            |
| $5000-$5F9F   |        3,200 | Map Data (80×40 tiles)          |
| $5FA0-$6678   |        1,753 | Unit Records (~292 units)       |
| **Total**     |    **5,769** | Complete save file size         |

## Detailed Memory Layout

### Game State Variables ($4FF0-$4FFF)

| Address | Size | Name               | Description                              |
|---------|-----:|--------------------|------------------------------------------|
| $4FF0   |    1 | STATE_DAILOR_UNITS | Dailor unit counter (decremented on kill)|
| $4FF1   |    1 | (reserved)         | Padding/unused                           |
| $4FF2   |   13 | STATE_GATE_FLAGS   | Gate/fortification flags for 13 locations|
| $4FFF   |    1 | STATE_TURN_COUNTER | Current turn number (BCD, max $15)       |

### Map Data ($5000-$5F9F)

The map is stored as an 80×40 grid of tiles (3,200 bytes).

- **Width:** 80 tiles (X: 0-79)
- **Height:** 40 tiles (Y: 0-39)
- **Byte Order:** Row-major (each row is 80 consecutive bytes)
- **Address Formula:** `tile_address = $5000 + (Y × 80) + X`

Each byte represents a terrain or unit tile:
- Terrain tiles: Various character codes (grass, water, forest, etc.)
- Unit tiles: $74-$83 (unit type + $74)

### Unit Records ($5FA0-$6678)

Units are stored as 6-byte records in a contiguous array.

#### Unit Record Structure (6 bytes)

| Offset | Name       | Description                                    |
|-------:|------------|------------------------------------------------|
|      0 | X          | X coordinate on map (0-79)                     |
|      1 | Y          | Y coordinate on map (0-39), $FF = destroyed    |
|      2 | V          | Current defense points (BCD, decreases in combat) |
|      3 | B_current  | Current movement points (BCD, decreases on move) |
|      4 | B_max      | Maximum movement points (BCD, reset each turn) |
|      5 | terrain    | Original terrain tile under the unit           |

#### End Marker

The unit list terminates when `unit[4]` (B_max) equals $00.

#### Unit Count

- Total units: ~292 (Eldoin: 128, Dailor: 164)
- Maximum capacity: 292 units × 6 bytes = 1,752 bytes + terminator

#### Unit Types (stored implicitly by position in list)

| Index | Player | Unit Type (German)    | Unit Type (English)  |
|------:|--------|----------------------|----------------------|
|     0 | Eldoin | Schwertträger        | Swordsman            |
|     1 | Eldoin | Bogenschützen        | Archers              |
|     2 | Eldoin | Adler                | Eagle                |
|     3 | Eldoin | Lanzenträger         | Spearman             |
|     4 | Eldoin | Kriegsschiff         | Warship              |
|     5 | Eldoin | Reiterei             | Cavalry              |
|     6 | Eldoin | Feldherr             | Commander            |
|     7 | Dailor | Bogenschützen        | Archers              |
|     8 | Dailor | Katapult             | Catapult             |
|     9 | Dailor | Blutsauger           | Bloodsucker          |
|    10 | Dailor | Axtmänner            | Axemen               |
|    11 | Dailor | Feldherr             | Commander            |
|    12 | Dailor | Lindwurm             | Dragon               |
|    13 | Dailor | Rammbock             | Battering Ram        |
|    14 | Dailor | Wagenfahrer          | Chariot              |
|    15 | Dailor | Wolfsreiter          | Wolf Rider           |


### Filename Format

- Single letter filename: `@0:X,S,W` where X is A-Z
- User enters one letter via keyboard (validated A-Z only)
- Stored at $035C (SAVE_LETTER / TEMP_COMBAT variable)

