# Victory Conditions

This document describes how the game determines the winner in Weltendaemmerung.

## Overview

The game has three distinct victory conditions:

| Condition            | Winner  | Trigger                                        |
|----------------------|---------|------------------------------------------------|
| Turn Limit           | Eldoin | Turn counter reaches 15                        |
| Feldherr Destroyed   | Dailor  | Eldoin's Feldherr (ACTION_UNIT $11) destroyed |
| Army Annihilation    | Eldoin | All Dailor units are destroyed                 |

## Detailed Victory Conditions

### 1. Turn Limit Victory (Eldoin Wins)

**Trigger:** The turn counter reaches 15 (BCD format at `$4FFF`).

**Code Location:** `$227E-$2306_turn_victory.asm` (`sub_227E`)

```assembly
sub_227E:
        LDA $4FFF               ; Load current turn counter
        SED                     ; Enable decimal mode (BCD arithmetic)
        CLC
        ADC #$01                ; Increment turn
        STA $4FFF               ; Store new turn
        CLD                     ; Disable decimal mode
        ...
        CMP #$15                ; Is it turn 15?
        BNE L22B1               ; No, continue game
        STA $034F               ; Store $15 for victory display
        JMP loc_1456            ; Jump to victory routine
```

**Explanation:**
- Turn counter is stored at `$4FFF` in BCD format
- Each complete round (after Dailor's Torphase) increments the counter
- When the counter reaches `$15` (15 in BCD), the game ends
- Since `$15 != $11`, the victory message displays "ELDOIN" as winner
- This creates a defensive advantage for Eldoin - survive 15 turns to win

### 2. Feldherr Destruction Victory (Dailor Wins)

**Trigger:** Eldoin's Feldherr/Commander (ACTION_UNIT `$11`) is destroyed in combat.

**Code Location:** `$12B1-$15CC_combat_turn.asm` (lines 219-221)

```assembly
        LDA $034F               ; ACTION_UNIT (destroyed unit index)
        CMP #$11                ; Is it the Feldherr?
        BEQ loc_1456            ; Yes, game ends immediately
```

**Explanation:**
- `$034F` (ACTION_UNIT) stores the index of the unit at the cursor position
- Unit indices are calculated as: `screen_char - $69`
- Eldoin's units have indices `$0B-$11` (types 0-6)
- Index `$11` corresponds to Eldoin's unit type 6 (Feldherr/Commander)
- When this specific unit is destroyed, Dailor wins immediately
- The victory display shows "DAILOR" as winner (since `$034F == $11`)
- There is only ONE Feldherr unit for Eldoin, placed at position (19, 12)

**Important Note on Asymmetric Design:**
- The game uses **different unit types per player** (see `docs/units.md`)
- Eldoin controls unit types 0-6, with type 6 being the Feldherr (Commander)
- Dailor controls unit types 7-15
- The stat table comments in the disassembly have incorrect unit name mappings
- Eldoin's Feldherr has stats: R=1, B=10, A=6, V=16

### 3. Army Annihilation Victory (Eldoin Wins)

**Trigger:** The enemy unit counter (`$4FF0`) reaches zero.

**Code Location:** `$12B1-$15CC_combat_turn.asm` (lines 222-228)

```assembly
        LDA $0347               ; CURRENT_PLAYER (attacker)
        BNE L1442               ; If Dailor attacking, skip
        DEC $4FF0               ; Eldoin attack: decrement enemy count
        BNE L1442               ; If not zero, continue
        LDA #$01                ; All enemies destroyed
        STA $034F               ; Set action unit for victory display
        JMP loc_1456            ; Game ends, Eldoin wins
```

**Explanation:**
- `$4FF0` is initialized to `$9F` (159 decimal) at game start
- Despite being labeled "ELDOIN_UNITS", this counter tracks Dailor's remaining units
- Only decremented when Eldoin destroys a Dailor unit
- When it reaches zero, all Dailor units are eliminated
- `$034F` is set to `$01`, which `!= $11`, so "ELDOIN" wins

**Asymmetry Note:** The code only tracks Dailor's unit losses. Eldoin cannot win by destroying all enemy units through normal combat tracking - instead, Dailor wins by destroying the special `$11` unit.

## Victory Display Routine

The victory screen is displayed at `loc_1456` in `$12B1-$15CC_combat_turn.asm`.

**Winner Determination:**
```assembly
        LDA $034F               ; Check ACTION_UNIT value
        CMP #$11                ; Compare to special unit index
        BNE L14F3               ; If not $11, Eldoin wins
        LDX #$09                ; String offset for "DAILOR"
        JSR sub_1E8B            ; Print winner name
        JMP loc_14F8
L14F3:
        LDX #$00                ; String offset for "ELDOIN"
        JSR sub_1E8B            ; Print winner name
```

**Victory Text:**
The screen displays: `"SIEG   HERREN VON THAINFAL SIND NUN DIE [WINNER]"`

Translation: "VICTORY   THE LORDS OF THAINFAL ARE NOW THE [WINNER]"

## Unit Ownership and Indexing

Understanding victory conditions requires understanding the unit index system:

### Index to Unit Type Mapping

| Index | Owner | Unit Type | Tile Code |
|-------|-------|-----------|-----------|
| $0B (11) | Eldoin | Schwerttraeger (0) | $74 |
| $0C (12) | Eldoin | Bogenschuetzen (1) | $75 |
| $0D (13) | Eldoin | Adler (2) | $76 |
| $0E (14) | Eldoin | Lanzentraeger (3) | $77 |
| $0F (15) | Eldoin | Kriegsschiff (4) | $78 |
| $10 (16) | Eldoin | Reiterei (5) | $79 |
| $11 (17) | Eldoin | Feldherr (6) | $7A |
| $12+ | Dailor | Types 7-15 | $7B-$83 |

### Ownership Check (sub_12D4)

```assembly
sub_12D4:
        LDX $034F               ; ACTION_UNIT index
        LDA $0347               ; CURRENT_PLAYER
        BEQ L12E2               ; Branch if Eldoin
        ; Dailor: owns units >= $12
        CPX #$12
        BCC L12EA               ; Not Dailor's unit
        BCS L12EC               ; Is Dailor's unit
L12E2:  ; Eldoin: owns units $0B-$11
        CPX #$0B
        BCC L12EA               ; Not valid (terrain)
        CPX #$12
        BCC L12EC               ; Is Eldoin's unit
```

## Key Memory Addresses

| Address | Name | Description |
|---------|------|-------------|
| `$0347` | CURRENT_PLAYER | Active player (0=Eldoin, 1=Dailor) |
| `$034F` | ACTION_UNIT | Unit/terrain index at cursor |
| `$4FF0` | Enemy Counter | Initialized to $9F, decremented on kills |
| `$4FFF` | Turn Counter | BCD format, game ends at $15 |

## Game Balance Analysis

The victory conditions create an asymmetric game:

**Eldoin's Advantages:**
- Wins on turn limit (defensive play rewarded)
- Wins by destroying all Dailor units

**Dailor's Advantages:**
- Can win immediately by destroying one specific unit ($11)
- Larger starting army (164 vs 128 units per docs/units.md)

**Strategic Implications:**
- Eldoin should protect the Feldherr (Commander at position 19,12) at all costs
- Dailor should prioritize finding and destroying Eldoin's Feldherr
- Eldoin can play defensively if ahead on units near turn 15
- Dailor needs an aggressive strategy to win before turn limit

## File References

- **Turn counter/victory check:** `disassembly/$227E-$2306_turn_victory.asm`
- **Combat victory logic:** `disassembly/$12B1-$15CC_combat_turn.asm` (loc_1456)
- **Unit counter init:** `disassembly/$080D-$0884_initialization.asm` (line 8)
- **Victory display strings:** `disassembly/$1A3F-$1E8A_utilities_render.asm` (lines 505-533)
