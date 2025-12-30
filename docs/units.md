# Weltendaemmerung Unit System

This document describes the unit types, statistics, and initial placement in the game.

## Unit Data Structure

Each unit occupies 6 bytes in memory at $5FA0:

| Offset  | Description                           |
|---------|---------------------------------------|
| 0       | X coordinate (0-79)                   |
| 1       | Y coordinate (0-39)                   |
| 2       | Defense value                         |
| 3       | Current movement points               |
| 4       | Max movement points (0 = end of list) |
| 5       | Original terrain under unit           |

## Unit Types

The game features 16 unit types, displayed on the map using character codes $74-$83.

### Unit Statistics

Statistics are stored in tables at $1017 (movement), $1027 (rank), $1037 (attack), $1047 (defense).

| Idx  | German        | English       | Move  | Rank  | Attack  | Defense  | Tile  |
|------|---------------|---------------|-------|-------|---------|----------|-------|
| 0    | Schwertträger | Swordsmen     | 22    | 1     | 16      | 4        | $74   |
| 1    | Bogenschützen | Archers       | 18    | 8     | 16      | 5        | $75   |
| 2    | Adler         | Eagles        | 17    | 2     | 18      | 7        | $76   |
| 3    | Lanzenträger  | Lancers       | 20    | 2     | 16      | 5        | $77   |
| 4    | Kriegsschiff  | Warship       | 24    | 8     | 8       | 32       | $78   |
| 5    | Reiterei      | Cavalry       | 16    | 5     | 21      | 6        | $79   |
| 6    | Katapult      | Catapult      | 22    | 1     | 16      | 6        | $7A   |
| 7    | Blutsauger    | Bloodsucker   | 18    | 8     | 16      | 5        | $7B   |
| 8    | Axtmänner     | Axemen        | 5     | 18    | 9       | 1        | $7C   |
| 9    | Feldherr      | Commander     | 16    | 1     | 18      | 8        | $7D   |
| 10   | Lindwurm      | Dragon/Wyrm   | 22    | 1     | 16      | 4        | $7E   |
| 11   | Rammbock      | Battering Ram | 22    | 1     | 16      | 6        | $7F   |
| 12   | Wagenfahrer   | Wagon Driver  | 48    | 2     | 16      | 48       | $80   |
| 13   | Wolfsreiter   | Wolf Riders   | 5     | 1     | 16      | 1        | $81   |
| 14   | (Unit 14)     | (Unit 14)     | 22    | 7     | 20      | 16       | $82   |
| 15   | (Unit 15)     | (Unit 15)     | 24    | 3     | 18      | 8        | $83   |

### Unit Characteristics

- **Schwertträger (Swordsmen)**: Basic infantry, balanced stats
- **Bogenschützen (Archers)**: Ranged units, good rank (8)
- **Adler (Eagles)**: Flying units, highest defense among light units
- **Lanzenträger (Lancers)**: Spear infantry, similar to swordsmen
- **Kriegsschiff (Warship)**: Naval unit, highest defense (32), water movement
- **Reiterei (Cavalry)**: Mounted units, highest attack (21)
- **Katapult (Catapult)**: Siege weapon, good defense
- **Blutsauger (Bloodsucker)**: Undead/vampire unit, high rank
- **Axtmänner (Axemen)**: Slow (5 move) but high rank (18)
- **Feldherr (Commander)**: Leader unit, high attack and defense
- **Lindwurm (Dragon/Wyrm)**: Large creature, standard stats
- **Rammbock (Battering Ram)**: Siege unit for walls
- **Wagenfahrer (Wagon Driver)**: Fast (48 move), high defense (48)
- **Wolfsreiter (Wolf Riders)**: Slow mounted unit

## Initial Unit Placement

Unit placement data is stored at $1057 in `disassembly/$0FAC-$12B0_game_logic.asm`.

### Placement Table Format ($1057)

```
$8X       - Unit type marker (X = 0-15)
X, Y      - Coordinate pairs (repeat for each unit)
$FF       - End of data
```

### Initialization Routine

The placement routine at `sub_0FAC` ($0FAC-$1012):
1. Reads unit type markers ($80-$8F)
2. For each coordinate pair:
   - Stores X,Y in unit data array
   - Copies movement and attack values from stats tables
   - Places unit character ($74+type) on map
   - Stores original terrain in unit record
