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

**IMPORTANT: Asymmetric Design** - Each player controls different unit types:
- **Eldoin** (Player 1): Unit types 0-6 (ACTION_UNIT $0B-$11)
- **Dailor** (Player 2): Unit types 7-15 (ACTION_UNIT $12-$1A)

The ACTION_UNIT index is calculated as: `tile_code - $69`

### Unit Statistics

Statistics are stored in tables (values are BCD encoded):
- $1017 = V (Verteidigung/Defense) - stored in unit record, can change
- $1027 = R (Reichweite/Range) - constant, read from table
- $1037 = B (Bewegung/Movement) - stored in unit record, decreases on move
- $1047 = A (Angriff/Attack) - constant, read from table

### Eldoin's Units (Types 0-6)

| Idx | German         | English       | R  | B  | A  | V  | Tile | Action |
|-----|----------------|---------------|----|----|----|----|------|--------|
| 0   | Schwertträger  | Sword Bearers | 1  | 10 | 4  | 16 | $74  | $0B    |
| 1   | Bogenschützen  | Archers       | 8  | 10 | 5  | 12 | $75  | $0C    |
| 2   | Adler          | Eagle         | 2  | 12 | 7  | 11 | $76  | $0D    |
| 3   | Lanzenträger   | Spear Bearers | 2  | 10 | 5  | 14 | $77  | $0E    |
| 4   | Kriegsschiff   | Warship       | 8  | 8  | 20 | 18 | $78  | $0F    |
| 5   | Reiterei       | Cavalry       | 5  | 15 | 6  | 10 | $79  | $10    |
| 6   | Feldherr       | Commander     | 1  | 10 | 6  | 16 | $7A  | $11*   |

\* **Victory Condition**: Destroying Eldoin's Feldherr (ACTION_UNIT $11) wins the game for Dailor.

### Dailor's Units (Types 7-15)

| Idx | German        | English        | R  | B  | A  | V  | Tile | Action |
|-----|---------------|----------------|----|----|----|----|------|--------|
| 7   | Bogenschützen | Archers        | 8  | 10 | 5  | 12 | $7B  | $12    |
| 8   | Katapult      | Catapult       | 12 | 9  | 1  | 5  | $7C  | $13    |
| 9   | Blutsauger    | Bloodsucker    | 1  | 12 | 8  | 10 | $7D  | $14    |
| 10  | Axtmänner     | Axe Men        | 1  | 10 | 4  | 16 | $7E  | $15    |
| 11  | Feldherr      | Commander      | 1  | 10 | 6  | 16 | $7F  | $16    |
| 12  | Lindwurm      | Dragon/Wyrm    | 2  | 10 | 30 | 30 | $80  | $17    |
| 13  | Rammbock      | Battering Ram  | 1  | 10 | 1  | 5  | $81  | $18    |
| 14  | Wagenfahrer   | Wagon Drivers  | 7  | 14 | 10 | 16 | $82  | $19    |
| 15  | Wolfsreiter   | Wolf Riders    | 3  | 12 | 8  | 18 | $83  | $1A    |

**Note on Shared Names**: Some unit names are shared between factions:
- "Bogenschützen" (Archers): Types 1 (Eldoin) and 7 (Dailor) - identical stats
- "Feldherr" (Commander): Types 6 (Eldoin) and 11 (Dailor) - identical stats

However, **only Eldoin's Feldherr (TYPE 6, ACTION_UNIT $11)** triggers the victory condition when destroyed.

### Unit Name Resolution

The game displays unit names via a non-sequential offset table at `$1D39`. The lookup works as:
1. Calculate index: `ACTION_UNIT = tile_code - $69`
2. Look up string offset: `offset = $1D39[ACTION_UNIT]`
3. Print string from: `$1DBE + offset`

**String Offset Table ($1D39):**
```
Index $0B (type 0): offset $37 → SCHWERTTRAEGER
Index $0C (type 1): offset $45 → BOGENSCHUETZEN
Index $0D (type 2): offset $53 → ADLER
Index $0E (type 3): offset $59 → LANZENTRAEGER
Index $0F (type 4): offset $66 → KRIEGSSCHIFF
Index $10 (type 5): offset $73 → REITEREI
Index $11 (type 6): offset $9A → FELDHERR
Index $12 (type 7): offset $45 → BOGENSCHUETZEN (same as type 1)
Index $13 (type 8): offset $7C → KATAPULT
Index $14 (type 9): offset $85 → BLUTSAUGER
Index $15 (type 10): offset $90 → AXTMAENNER
Index $16 (type 11): offset $9A → FELDHERR (same as type 6)
Index $17 (type 12): offset $A3 → LINDWURM
Index $18 (type 13): offset $AC → RAMMBOCK
Index $19 (type 14): offset $B5 → WAGENFAHRER
Index $1A (type 15): offset $C1 → WOLFSREITER
```

**Note**: The disassembly stat table comments at `$1017` have incorrect unit name order.
The names above are verified from the actual string offset table and string data.

### Ownership Check (sub_12D4)

```assembly
; Eldoin (player 0): owns ACTION_UNIT $0B-$11
        CPX #$0B        ; If X < $0B, not valid
        BCC not_owned
        CPX #$12        ; If X < $12, is Eldoin's
        BCC is_owned

; Dailor (player 1): owns ACTION_UNIT >= $12
        CPX #$12        ; If X < $12, not Dailor's
        BCC not_owned
        BCS is_owned    ; If X >= $12, is Dailor's
```

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
