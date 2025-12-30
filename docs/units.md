# Weltendaemmerung Unit System

This document describes the unit types, statistics, and initial placement in the game.

## Unit Data Structure

Each unit occupies 6 bytes in memory at $5FA0:

| Offset | Source    | Description                                |
|--------|-----------|-------------------------------------------|
| 0      | placement | X coordinate (0-79)                      |
| 1      | placement | Y coordinate (0-39)                      |
| 2      | $1017,X   | V (Verteidigung) - can change in combat   |
| 3      | $1037,X   | B (Bewegung) - current, decreases on move |
| 4      | $1037,X   | B max - reset value (0 = end of list)     |
| 5      | map       | Original terrain under unit               |

**Note:** R ($1027) and A ($1047) are NOT stored in the unit record - they are
looked up from the tables each time they're displayed. Only V and B can change.

## Unit Types

The game features 16 unit types, displayed on the map using character codes $74-$83.

### Unit Statistics

Statistics are stored in tables (values are BCD encoded):
- $1017 = V (Verteidigung/Defense) - stored in unit record, can change
- $1027 = R (Reichweite/Range) - constant, read from table
- $1037 = B (Bewegung/Movement) - stored in unit record, decreases on move
- $1047 = A (Angriff/Attack) - constant, read from table

| Idx  | German        | English       | R   | B    | A    | V    | Tile  |
|------|---------------|---------------|-----|------|------|------|-------|
| 0    | Schwertträger | Swordsmen     | 1   | 10   | 4    | 16   | $74   |
| 1    | Bogenschützen | Archers       | 8   | 10   | 5    | 12   | $75   |
| 2    | Adler         | Eagles        | 2   | 12   | 7    | 11   | $76   |
| 3    | Lanzenträger  | Lancers       | 2   | 10   | 5    | 14   | $77   |
| 4    | Kriegsschiff  | Warship       | 8   | 8    | 20   | 18   | $78   |
| 5    | Reiterei      | Cavalry       | 5   | 15   | 6    | 10   | $79   |
| 6    | Katapult      | Catapult      | 1   | 10   | 6    | 16   | $7A   |
| 7    | Blutsauger    | Bloodsucker   | 8   | 10   | 5    | 12   | $7B   |
| 8    | Axtmänner     | Axemen        | 12  | 9    | 1    | 5    | $7C   |
| 9    | Feldherr      | Commander     | 1   | 12   | 8    | 10   | $7D   |
| 10   | Lindwurm      | Dragon/Wyrm   | 1   | 10   | 4    | 16   | $7E   |
| 11   | Rammbock      | Battering Ram | 1   | 10   | 6    | 16   | $7F   |
| 12   | Wagenfahrer   | Wagon Driver  | 2   | 10   | 30   | 30   | $80   |
| 13   | Wolfsreiter   | Wolf Riders   | 1   | 10   | 1    | 5    | $81   |
| 14   | (Unit 14)     | (Unit 14)     | 7   | 14   | 10   | 16   | $82   |
| 15   | (Unit 15)     | (Unit 15)     | 3   | 12   | 8    | 18   | $83   |

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
