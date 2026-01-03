# Screen Display

This document describes how the screen looks during each game phase.

## Screen Layout

The C64 screen uses 40 columns x 25 rows of characters.

| Area    | Rows  | Content                              |
|---------|-------|--------------------------------------|
| Map     | 1-19  | Terrain tiles and unit sprites       |
| Divider | 20    | Empty row                            |
| Status  | 21-24 | Phase info, terrain name, unit stats |

**Memory Layout:**
- Screen: $C000-$C3FF
- Color RAM: $D800-$DBE7
- Border: Blue ($06)
- Background: Green ($05)

## Status Area

**Row 22 - Phase Header:**
Format: `[PLAYER] [PHASE]PHASE`

Examples:
- `ELDOIN BEWEGUNGSPHASE`
- `DAILOR ANGRIFFSPHASE`

**Row 23-24 - Terrain Info:**
Shows the terrain type at cursor position. *See [map.md](map.md#terrain-types) for complete terrain details and tile mappings.*

**Row 24 Column 18 - Unit Stats:**
When cursor is over a unit, displays:
`R= XX B= XX A= XX V= XX`

| Letter  | Meaning                | Source                   |
|---------|------------------------|--------------------------|
| R       | Reichweite (Range)     | Unit type constant       |
| B       | Bewegung (Movement)    | Current points remaining |
| A       | Angriff (Attack)       | Unit type constant       |
| V       | Verteidigung (Defense) | Current defense value    |

## Phase-Specific Display

### Movement Phase (Bewegungsphase)

**Header:** `ELDOIN BEWEGUNGSPHASE` or `DAILOR BEWEGUNGSPHASE`

**Cursor:** White ($01)

**Features:**
- Full movement points displayed in B= value
- Map scrolling enabled via joystick
- Unit selection with fire button
- Movement points decrease as units move

### Attack Phase (Angriffsphase)

**Header:** `ELDOIN ANGRIFFSPHASE` or `DAILOR ANGRIFFSPHASE`

**Cursor color indicates combat state:**

| Color       | Code  | Meaning                          |
|-------------|-------|----------------------------------|
| White       | $01   | Normal - no attack active        |
| Light Green | $0A   | Attacker selected                |
| Red         | $FA   | Target selected, ready to strike |

**Features:**
- Movement restricted to B=01 for all units
- Map scrolling disabled
- Combat flow: Select own unit (green) → Select enemy (red) → Execute
- Selected units flash on screen

### Torphase (Gate Phase)

**Header:** `ELDOIN TORPHASE` or `DAILOR TORPHASE`

**Cursor:** White ($01)

**Features:**
- No unit movement
- Terrain changes immediately when gates placed/destroyed
- Eldoin can only build on western half (X < 60)
- Dailor can only build on eastern half (X >= 60)

## Unit Colors

| Faction | Character Range | Color |
|---------|-----------------|-------|
| Eldoin | $74-$7A | Yellow ($07) |
| Dailor | $7B+ | Black ($00) |

## Phase Transitions

When a phase ends:
1. Sound effect plays (triangle waveform)
2. Cursor sprite updates
3. New phase header displays
4. If entering Attack Phase: All unit movement set to 1

**Code Reference:** Phase display routine at `sub_1D0E` in `$1E8B-$2012_display_terrain.asm`

## Victory Screen

The victory screen appears when the game ends.

### Victory Triggers

| Condition                   | Winner |
|-----------------------------|--------|
| Turn 15 reached             | Eldoin |
| Eldoin's Feldherr destroyed | Dailor |
| All Dailor units destroyed  | Eldoin |

### Visual Sequence

1. **Screen flash** - White ($01) then black ($00)
2. **Screen clear** - All content removed
3. **Victory fanfare** - 7-note ascending melody on all 3 SID voices
4. **Victory message displayed**

### Victory Message

**Row 15:** Winner name centered at column 12
- `ELDOIN` or `DAILOR`

**Row 16:** Victory text at column 9
- `SIEG   HERREN VON THAINFAL SIND NUN DIE`
- Translation: "VICTORY   THE LORDS OF THAINFAL ARE NOW THE"

### Screen State

| Element    | Value                  |
|------------|------------------------|
| Background | Black ($00)            |
| Border     | Black ($00)            |
| Text       | White (default CHROUT) |
| Sprites    | Disabled               |

### User Interaction

- Screen remains until any key is pressed
- After keypress, game restarts from initialization

**Code Reference:** Victory display at `loc_1456` in `$12B1-$15CC_attack_turn.asm`
