# Weltendämmerung Web Port

A comprehensive guide for porting the C64 game "Weltendämmerung" (Twilight of the Worlds) to a modern web application.

## Overview

**Original:** Commodore 64 turn-based fantasy strategy game (1987, Markt und Technik)
**Target:** Modern web application using Vite, TypeScript, and Tailwind CSS
**Visual Style:** Retro-modern (C64 aesthetics with crisp rendering and smooth animations)

### Game Summary

Weltendämmerung is a two-player strategy game where:
- **Eldoin** (Player 1, western faction) defends against invasion
- **Dailor** (Player 2, eastern faction) attacks to conquer

The game features 292 units across 16 types on an 80x40 tile map, with three distinct victory conditions creating asymmetric gameplay.

---

## Technology Stack

| Component | Technology |
|-----------|------------|
| Build Tool | Vite |
| Language | TypeScript (strict mode) |
| Styling | Tailwind CSS |
| Rendering | HTML5 Canvas (map/units) + DOM (UI) |
| State | TypeScript classes |

### Excluded Features (per requirements)
- Sound/music (no SID emulation)
- Save/load game functionality
- BCD arithmetic (use regular numbers)

---

## Source Documentation Reference

| Topic | Documentation |
|-------|---------------|
| Movement rules, terrain costs | [docs/movement.md](docs/movement.md) |
| Combat formulas, range, damage | [docs/attack.md](docs/attack.md) |
| Torphase fortification mechanics | [docs/torphase.md](docs/torphase.md) |
| Unit types, statistics, placement | [docs/units.md](docs/units.md) |
| Victory conditions, win states | [docs/victory_conditions.md](docs/victory_conditions.md) |
| Turn structure, state machine | [docs/program_flow.md](docs/program_flow.md) |
| Screen layout, phase display | [docs/screen_display.md](docs/screen_display.md) |
| Map structure, terrain types | [docs/map.md](docs/map.md) |
| Memory layout, data structures | [docs/memory_layout.md](docs/memory_layout.md) |
| Title screen, startup sequence | [docs/title_screen.md](docs/title_screen.md) |

---

## Project Structure

```
web/
├── index.html                    # Entry point
├── package.json                  # Dependencies
├── tsconfig.json                 # TypeScript config
├── tailwind.config.js            # Tailwind + C64 colors
├── vite.config.ts                # Build config
├── public/
│   └── tiles/                    # 38 PNG tiles (8x8 each)
│       └── tile_00.png ... tile_37.png
└── src/
    ├── main.ts                   # Application entry
    ├── types/
    │   ├── index.ts              # Type exports
    │   ├── units.ts              # Unit interfaces
    │   ├── terrain.ts            # Terrain types
    │   └── game.ts               # Game state types
    ├── data/
    │   ├── units.ts              # Unit statistics table
    │   ├── terrain.ts            # Terrain costs
    │   ├── map.ts                # 80x40 map data (auto-generated)
    │   ├── initialUnits.ts       # 292 units placement (auto-generated)
    │   └── gates.ts              # 13 gate positions
    ├── game/
    │   ├── index.ts              # Module exports
    │   ├── GameState.ts          # Core state management
    │   ├── TurnManager.ts        # 6-state turn machine
    │   ├── MovementSystem.ts     # Movement validation & costs
    │   ├── CombatSystem.ts       # Attack range, damage
    │   ├── FortificationSystem.ts # Torphase logic
    │   └── VictoryChecker.ts     # Win condition detection
    ├── rendering/
    │   ├── TileRenderer.ts       # Load/render 8x8 tiles
    │   ├── MapRenderer.ts        # Viewport scrolling
    │   ├── CursorRenderer.ts     # Phase-based cursors
    │   └── UIRenderer.ts         # Status bar
    ├── ui/
    │   ├── index.ts              # UI module exports
    │   ├── screens.ts            # Screen state management
    │   ├── TitleScreen.ts        # Title + faction display + start
    │   ├── GameChrome.ts         # Header bar (player/phase/turn/end turn)
    │   ├── VictoryScreen.ts      # Winner display + play again
    │   └── StatusBar.ts          # Terrain/unit info display
    ├── input/
    │   └── [MouseController.ts]  # Click + edge scrolling (TODO)
    └── utils/
        └── colors.ts             # C64 palette
```

---

## Data Extraction

### Map Data
The map is RLE-compressed in the original binary at offset `$1788`. Use the extraction script:

```bash
python3 tools/extract_map_data.py
```

This generates:
- `web/src/data/map.ts` - 80x40 terrain grid as compact strings
- `web/src/data/initialUnits.ts` - 292 unit positions

#### Compact Map Format

The map data uses a compact string representation where each character represents one terrain tile:

| Char | Hex Code | Terrain |
|------|----------|---------|
| M    | 0x69     | Meadow (variant 1) |
| m    | 0x6A     | Meadow (variant 2) |
| R    | 0x6B     | River |
| F    | 0x6C     | Forest |
| E    | 0x6D     | End (map boundary) |
| S    | 0x6E     | Swamp |
| G    | 0x6F     | Gate |
| X    | 0x70     | Mountains |
| P    | 0x71     | Pavement |
| W    | 0x72     | Wall (variant 1) |
| w    | 0x73     | Wall (variant 2) |
| 1-8  | 0x61-68  | UI frame elements (fortress walls) |

The generated file exports helper functions rather than raw arrays:

```typescript
// Get terrain type for game logic (e.g., movement costs)
export function getTerrainAt(x: number, y: number): TerrainType;

// Get C64 character code for rendering (distinguishes visual variants)
export function getCharCodeAt(x: number, y: number): number;
```

### Tile Assets
Copy existing extracted tiles:
```bash
cp assets/tiles/*.png web/public/tiles/
```

Tiles use character codes `$5E-$83`:
- `$5E-$68`: UI borders (11 tiles)
- `$69-$73`: Terrain (11 tiles)
- `$74-$83`: Unit sprites (16 tiles)

---

## Core Type Definitions

### Coordinate Type

```typescript
interface Coord {
  x: number;  // Map X (0-79)
  y: number;  // Map Y (0-39)
}
```

### Player and Phase Enums

```typescript
enum Player {
  Eldoin = 0,  // Western faction
  Dailor = 1   // Eastern faction
}

enum Phase {
  Movement = 0,      // Bewegungsphase - full movement
  Attack = 1,        // Angriffsphase - movement = 1
  Fortification = 2  // Torphase - build gates/walls
}

enum TerrainType {
  Meadow = 0,     // $69-$6A - Easy traversal
  River = 1,      // $6B - Water, varies by unit
  Forest = 2,     // $6C - Slows movement
  End = 3,        // $6D - Map boundary
  Swamp = 4,      // $6E - Difficult terrain
  Gate = 5,       // $6F - Fortification point
  Mountains = 6,  // $70 - Blocking terrain
  Pavement = 7,   // $71 - Fast movement
  Wall = 8        // $72-$73 - Blocking structure
}
```

### Unit Interface

```typescript
interface Unit {
  id: number;          // Unique identifier
  x: number;           // Map X (0-79)
  y: number;           // Map Y (0-39), 255 = destroyed
  type: number;        // Unit type (0-15)
  owner: Player;       // Eldoin (0) or Dailor (1)
  defense: number;     // Current defense (decreases in combat)
  movement: number;    // Remaining movement this phase
  maxMovement: number; // Max movement (reset each round)
}
```

### Gate Position Interface

```typescript
interface GatePosition {
  index: number;       // Gate index (0-12)
  pos: Coord;          // Position on map
  territory: Player;   // Which player's territory
}
```

### Gate State Tracking

Instead of storing a mutable copy of the map terrain, gate modifications are tracked via a `GateState` enum:

```typescript
enum GateState {
  Original = 0,    // Gate as placed on original map
  Wall = 1,        // Converted to wall by Eldoin
  Meadow = 2,      // Converted to meadow by Dailor
  Destroyed = 3,   // Destroyed by combat (becomes Pavement)
}
```

The `GameState` class stores `gateStates: GateState[]` (13 entries) and derives current terrain by checking:
1. Original terrain via `getTerrainAt(x, y)` from map.ts
2. If position is a gate location, apply the `GateState` override

---

## Unit Statistics

All 16 unit types with stats from [docs/units.md](docs/units.md):

### Eldoin Units (Types 0-6)

| Type | Name | Range | Move | Attack | Defense | Special |
|------|------|-------|------|--------|---------|---------|
| 0 | Schwertträger | 1 | 10 | 4 | 16 | - |
| 1 | Bogenschützen | 8 | 10 | 5 | 12 | Long range |
| 2 | Adler | 2 | 12 | 7 | 11 | Flies (terrain cost 1) |
| 3 | Lanzenträger | 2 | 10 | 5 | 14 | - |
| 4 | Kriegsschiff | 8 | 8 | 20 | 18 | Water-only |
| 5 | Reiterei | 5 | 15 | 6 | 10 | Highest movement |
| 6 | Feldherr | 1 | 10 | 6 | 16 | **VICTORY UNIT** |

### Dailor Units (Types 7-15)

| Type | Name | Range | Move | Attack | Defense | Special |
|------|------|-------|------|--------|---------|---------|
| 7 | Bogenschützen | 8 | 10 | 5 | 12 | Long range |
| 8 | Katapult | 12 | 9 | 1 | 5 | Destroys structures |
| 9 | Blutsauger | 1 | 12 | 8 | 10 | Flies (terrain cost 1) |
| 10 | Axtmänner | 1 | 10 | 4 | 16 | - |
| 11 | Feldherr | 1 | 10 | 6 | 16 | - |
| 12 | Lindwurm | 2 | 10 | 30 | 30 | **Strongest**, destroys structures |
| 13 | Rammbock | 1 | 10 | 1 | 5 | Destroys gates only |
| 14 | Wagenfahrer | 7 | 14 | 10 | 16 | Slow in difficult terrain |
| 15 | Wolfsreiter | 3 | 12 | 8 | 18 | - |

---

## Terrain Movement Costs

From [docs/movement.md](docs/movement.md), special terrain costs by unit type:

```typescript
// Default cost for Meadow, Gate, Mountains, Pavement, Wall = 1

// River ($6B) costs per unit type
const RIVER_COSTS = [4, 4, 1, 4, 1, 4, 4, 2, 4, 1, 2, 2, 4, 4, 5, 2];

// Forest ($6C) costs per unit type (0 = impassable)
const FOREST_COSTS = [2, 2, 1, 3, 0, 4, 2, 2, 4, 1, 2, 2, 1, 3, 7, 2];

// Swamp ($6E) costs per unit type (0 = impassable)
const SWAMP_COSTS = [3, 3, 1, 3, 0, 4, 3, 3, 4, 1, 3, 3, 1, 4, 7, 4];
```

**Special units:**
- **Eagle (2) & Bloodsucker (9):** Cost 1 for all special terrain (flying)
- **Warship (4):** Water-only movement, cost 0 (impassable) for forest/swamp

---

## Turn System

The game uses a 6-state turn machine described in [docs/program_flow.md](docs/program_flow.md):

### State Calculation
```
Combined State = (Phase × 2) + Player + 1
```

| State | Phase | Player | German Name | Actions |
|-------|-------|--------|-------------|---------|
| 1 | 0 | Eldoin | Bewegungsphase | Full movement |
| 2 | 0 | Dailor | Bewegungsphase | Full movement |
| 3 | 1 | Eldoin | Angriffsphase | Attack, movement=1 |
| 4 | 1 | Dailor | Angriffsphase | Attack, movement=1 |
| 5 | 2 | Eldoin | Torphase | Build (X<60 only) |
| 6 | 2 | Dailor | Torphase | Build (X≥60), end round |

### Turn Advancement

**Important:** Phase/player changes occur when the player clicks an "End Turn" button. The turn does not advance automatically - each player explicitly ends their turn when ready.

```typescript
// Called when player clicks "End Turn" button
function advanceTurn(state: GameState): void {
  // Toggle player
  state.currentPlayer = state.currentPlayer === Player.Eldoin
    ? Player.Dailor
    : Player.Eldoin;

  // If back to Eldoin, advance phase
  if (state.currentPlayer === Player.Eldoin) {
    state.phase = (state.phase + 1) % 3;

    // If new round (back to Movement), reset movement and increment turn
    if (state.phase === Phase.Movement) {
      state.turnCounter++;
      resetAllMovementPoints(state);
      checkVictory(state);  // Check turn limit
    }
  }

  // At start of attack phase, restrict movement to 1
  if (state.phase === Phase.Attack) {
    setAllMovementToOne(state);
  }
}
```

---

## Combat System

From [docs/attack.md](docs/attack.md):

### Range Check (Euclidean Distance)

```typescript
function isInRange(attacker: Unit, target: Unit): boolean {
  const range = UNIT_STATS[attacker.type].range;
  const dx = target.x - attacker.x;
  const dy = target.y - attacker.y;
  return Math.sqrt(dx * dx + dy * dy) <= range;
}
```

### Damage Calculation

```typescript
function calculateDamage(attackerType: number): number {
  const baseAttack = UNIT_STATS[attackerType].attack;
  // Random modifier: 0-4 with weighted distribution
  // Distribution: 0(12.5%), 1(25%), 2(25%), 3(25%), 4(12.5%)
  const modifierTable = [0, 1, 1, 2, 2, 3, 3, 4];
  const modifier = modifierTable[Math.floor(Math.random() * 8)];
  return baseAttack + modifier;
}

function applyDamage(target: Unit, damage: number): boolean {
  target.defense -= damage;
  if (target.defense <= 0) {
    target.y = 255;  // Mark as destroyed
    return true;     // Unit destroyed
  }
  return false;
}
```

### Structure Attack

Only these units can attack structures (gates/walls):
- **Katapult (8):** Gates and walls
- **Lindwurm (12):** Gates and walls
- **Rammbock (13):** Gates only

When destroyed, structures become Pavement ($71).

---

## Torphase (Fortification)

From [docs/torphase.md](docs/torphase.md):

### 13 Fixed Gate Positions

```typescript
const GATE_POSITIONS: GatePosition[] = [
  // Eldoin territory (X < 60) - 10 gates
  { index: 0,  pos: { x: 5,  y: 6 },  territory: Player.Eldoin },
  { index: 1,  pos: { x: 17, y: 5 },  territory: Player.Eldoin },
  { index: 2,  pos: { x: 29, y: 10 }, territory: Player.Eldoin },
  { index: 3,  pos: { x: 14, y: 21 }, territory: Player.Eldoin },
  { index: 4,  pos: { x: 42, y: 21 }, territory: Player.Eldoin },
  { index: 5,  pos: { x: 47, y: 21 }, territory: Player.Eldoin },
  { index: 6,  pos: { x: 52, y: 21 }, territory: Player.Eldoin },
  { index: 7,  pos: { x: 25, y: 25 }, territory: Player.Eldoin },
  { index: 8,  pos: { x: 5,  y: 35 }, territory: Player.Eldoin },
  { index: 9,  pos: { x: 11, y: 34 }, territory: Player.Eldoin },
  // Dailor territory (X >= 60) - 3 gates
  { index: 10, pos: { x: 70, y: 7 },  territory: Player.Dailor },
  { index: 11, pos: { x: 69, y: 17 }, territory: Player.Dailor },
  { index: 12, pos: { x: 75, y: 34 }, territory: Player.Dailor },
];
```

### Territory Restriction
- **Eldoin** can only build at positions where X < 60
- **Dailor** can only build at positions where X ≥ 60

### Gate Conversion Logic

```typescript
function performTorphase(state: GameState, pos: Coord): boolean {
  // Validate territory
  const inTerritory = state.currentPlayer === Player.Eldoin
    ? pos.x < 60
    : pos.x >= 60;
  if (!inTerritory) return false;

  // Validate gate position
  const gate = GATE_POSITIONS.find(g => g.pos.x === pos.x && g.pos.y === pos.y);
  if (!gate) return false;

  // Check if destroyed
  if (state.gateFlags[gate.index]) return false;

  const terrain = getTerrainAt(state, pos);

  if (terrain === TerrainType.Gate) {
    // Convert gate
    if (state.currentPlayer === Player.Eldoin) {
      setTerrainAt(state, pos, TerrainType.Wall);   // Eldoin: Gate → Wall
    } else {
      setTerrainAt(state, pos, TerrainType.Meadow); // Dailor: Gate → Meadow
    }
  } else {
    // Place new gate
    setTerrainAt(state, pos, TerrainType.Gate);
  }

  return true;
}
```

---

## Victory Conditions

From [docs/victory_conditions.md](docs/victory_conditions.md):

| Condition | Winner | Trigger |
|-----------|--------|---------|
| Turn Limit | Eldoin | Turn counter reaches 15 |
| Commander Destroyed | Dailor | Eldoin's Feldherr (type 6) destroyed |
| Total Annihilation | Eldoin | All Dailor units destroyed |

```typescript
function checkVictory(state: GameState): Player | null {
  // Turn limit - Eldoin wins
  if (state.turnCounter >= 15) {
    return Player.Eldoin;
  }

  // Eldoin's Commander destroyed - Dailor wins
  const eldoinCommander = state.units.find(
    u => u.type === 6 && u.owner === Player.Eldoin && u.y !== 255
  );
  if (!eldoinCommander) {
    return Player.Dailor;
  }

  // All Dailor units destroyed - Eldoin wins
  const dailorUnits = state.units.filter(
    u => u.owner === Player.Dailor && u.y !== 255
  );
  if (dailorUnits.length === 0) {
    return Player.Eldoin;
  }

  return null;  // Game continues
}
```

---

## C64 Color Palette

From [docs/screen_display.md](docs/screen_display.md):

```typescript
const C64_COLORS = {
  black:      '#000000',  // $00 - Dailor units, meadow pattern
  white:      '#FFFFFF',  // $01 - End markers, cursor
  red:        '#683B2B',  // $02 - Forest
  cyan:       '#70A4B2',  // $03
  purple:     '#6F3D86',  // $04 - Title screen menu
  green:      '#588D43',  // $05 - Map background
  blue:       '#352879',  // $06 - Border, river, swamp
  yellow:     '#B8C76F',  // $07 - Eldoin units
  orange:     '#6F4F25',  // $08
  brown:      '#433900',  // $09
  lightRed:   '#9A6759',  // $0A - Attack mode cursor
  darkGray:   '#444444',  // $0B - UI elements, walls, gates
  gray:       '#6C6C6C',  // $0C
  lightGreen: '#9AD284',  // $0D
  lightBlue:  '#6C5EB5',  // $0E - Title screen text
  lightGray:  '#959595',  // $0F
};
```

### Color Mapping for Tiles

```typescript
function getTileColor(charCode: number): string {
  if (charCode < 0x69) return C64_COLORS.darkGray;  // UI elements
  if (charCode === 0x69 || charCode === 0x6A) return C64_COLORS.black;   // Meadow
  if (charCode === 0x6B) return C64_COLORS.blue;    // River
  if (charCode === 0x6C) return C64_COLORS.red;     // Forest
  if (charCode === 0x6D) return C64_COLORS.white;   // End
  if (charCode === 0x6E) return C64_COLORS.blue;    // Swamp
  if (charCode >= 0x6F && charCode <= 0x73) return C64_COLORS.darkGray; // Structures
  if (charCode >= 0x74 && charCode <= 0x7A) return C64_COLORS.yellow;   // Eldoin units
  return C64_COLORS.black;  // Dailor units ($7B+)
}
```

### Retro-Modern Visual Design

The web port uses a "CRT Terminal Fantasy" aesthetic that combines C64 authenticity with modern polish:

**Typography:**
- **Press Start 2P** Google Font for authentic pixel typography
- Responsive font sizes using `clamp()` for mobile to desktop

**CRT Effects (CSS-based):**
```css
/* Scanline overlay */
.scanlines::after {
  background: repeating-linear-gradient(0deg, transparent, transparent 2px,
    rgba(0,0,0,0.15) 2px, rgba(0,0,0,0.15) 4px);
}

/* Phosphor glow */
.crt-glow {
  box-shadow: 0 0 10px rgba(108,94,181,0.5), 0 0 20px rgba(108,94,181,0.3);
}
```

**Animations:**
- `phosphor-pulse` - Subtle brightness pulsing
- `glow-pulse` - Box shadow intensity cycling
- `title-glow` - Text shadow animation for title
- `victory-entrance` - Scale + brightness burst for wins

**Color Usage:**
- Yellow (#B8C76F) - Eldoin faction, highlights, primary actions
- Light Blue (#6C5EB5) - Dailor faction, secondary elements
- Blue (#352879) - Borders, backgrounds, structural elements
- Light Red (#9A6759) - Attack phase indicators

---

## Screen Layout

From [docs/screen_display.md](docs/screen_display.md):

### Viewport
- **Visible area:** 40×19 tiles (320×152 pixels at 1x scale)
- **Full map:** 80×40 tiles (640×320 pixels)
- **Tile size:** 8×8 pixels
- **Background:** Green (#588D43)

### Status Bar
Located below the map canvas, displaying:
1. **Phase header:** `[PLAYER] [PHASE] PHASE`
   - Example: "ELDOIN MOVEMENT PHASE"
2. **Terrain info:** Current terrain name at cursor (English: Meadow, River, Forest, etc.)
3. **Unit stats:** `[Unit Name] - Rng=XX Mov=XX Atk=XX Def=XX` (when cursor on unit)
   - Rng = Range, Mov = Movement, Atk = Attack, Def = Defense
4. **Turn counter:** `Turn X/15`

### Cursor Behavior
- **Movement phase:** Pointer cursor, white highlight
- **Attack phase (selecting):** Crosshair, light green highlight
- **Attack phase (targeting):** Target cursor, red highlight
- **Torphase:** Cell cursor when over valid gate position

---

## Mouse Controls

### End Turn Button
An "End Turn" button must be displayed on screen. Clicking it advances to the next player/phase. The turn does not change automatically - players explicitly end their turn when ready.

### Click Actions

| Phase | Own Unit | Enemy Unit | Empty Tile | Gate Position |
|-------|----------|------------|------------|---------------|
| Movement | Select/Deselect | - | Move (if selected) | - |
| Attack | Select attacker | Attack (if selected) | - | - |
| Torphase | - | - | - | Build/Convert |

### Edge Scrolling
When cursor is within 20px of viewport edge, scroll map in that direction at 60fps.

### Right-Click
Deselect current unit / cancel action.

---

## Implementation Checklist

### Phase 1: Project Setup ✅
**Read:** [docs/screen_display.md](docs/screen_display.md) (C64 colors), [docs/map.md](docs/map.md) (tile info)

- [x] Initialize Vite + TypeScript + Tailwind
- [x] Configure C64 color palette in Tailwind
- [x] Copy tile assets to `public/tiles/`
- [x] Run `extract_map_data.py` to generate data files

### Phase 2: Core Types & Data ✅
**Read:** [docs/units.md](docs/units.md), [docs/movement.md](docs/movement.md), [docs/torphase.md](docs/torphase.md)

- [x] Define enums (Player, Phase, TerrainType)
- [x] Define interfaces (Unit, GameState)
- [x] Create unit statistics table
- [x] Create terrain cost tables
- [x] Create gate positions array

### Phase 3: Game Logic ✅
**Read:** [docs/program_flow.md](docs/program_flow.md) (turn system), [docs/movement.md](docs/movement.md), [docs/attack.md](docs/attack.md), [docs/torphase.md](docs/torphase.md), [docs/victory_conditions.md](docs/victory_conditions.md)

- [x] Implement GameState class
- [x] Implement TurnManager (6-state machine)
- [x] Implement MovementSystem (validation, costs)
- [x] Implement CombatSystem (range, damage)
- [x] Implement FortificationSystem (gates, walls)
- [x] Implement VictoryChecker (3 conditions)

### Phase 4: Rendering ✅
**Read:** [docs/screen_display.md](docs/screen_display.md), [docs/map.md](docs/map.md)

- [x] Implement TileRenderer (load PNG tiles)
- [x] Implement MapRenderer (Canvas, viewport scrolling)
- [x] Implement CursorRenderer (phase-based styling)
- [x] Implement UIRenderer (status bar)

### Phase 5: UI Screens ✅
**Read:** [docs/title_screen.md](docs/title_screen.md), [docs/screen_display.md](docs/screen_display.md)

- [x] Create TitleScreen (with faction display and animations)
- [x] Create GameChrome (header bar with phase indicators)
- [x] Create VictoryScreen (winner display with condition messages)
- [x] Create StatusBar component (terrain/unit info)
- [x] Add "End Turn" button
- [x] Implement screen state management (title → game → victory)
- [x] Add retro-modern CSS styling (CRT glow, scanlines, pixel font)

### Phase 6: Input (Partial)
**Read:** [docs/program_flow.md](docs/program_flow.md) (phase-specific actions), [docs/movement.md](docs/movement.md), [docs/attack.md](docs/attack.md), [docs/torphase.md](docs/torphase.md)

- [x] Add keyboard scrolling (arrow keys)
- [x] Add click handling for unit selection
- [x] Add right-click to deselect
- [ ] Implement full MouseController and TouchController
- [ ] Add click handling for movement/attack/fortification actions
- [ ] Add edge scrolling

### Phase 7: Polish (Partial)
**Read:** [docs/screen_display.md](docs/screen_display.md) (cursor colors, phase transitions)

- [x] Add selected unit pulsing (green glow animation)
- [x] Add phase-based cursor colors
- [x] Add CRT glow and scanline effects
- [x] Add responsive design (mobile to desktop)
- [ ] Add unit movement animations
- [ ] Add attack flash effects
- [ ] Add phase transition effects

---

## Testing Checklist

### Movement
- [ ] Unit can/c move on meadow (cost 1)
- [ ] Eagle/Bloodsucker flies over all terrain
- [ ] Warship only moves on river
- [ ] Movement points deducted correctly
- [ ] Cannot move onto occupied tiles
- [ ] Cannot move with 0 movement points

### Combat
- [ ] Range check works (Euclidean distance)
- [ ] Damage = base attack + modifier (0-4)
- [ ] Defense reduced correctly
- [ ] Unit destroyed when defense ≤ 0
- [ ] Catapult/Dragon/Ram destroy structures

### Torphase
- [ ] Only 13 valid positions
- [ ] Territory restriction enforced
- [ ] Eldoin: Gate → Wall
- [ ] Dailor: Gate → Meadow
- [ ] Either: Non-gate → Gate
- [ ] Destroyed gates cannot be used

### Victory
- [ ] Turn 15 → Eldoin wins
- [ ] Eldoin Commander destroyed → Dailor wins
- [ ] All Dailor units destroyed → Eldoin wins

### Turn System
- [ ] States cycle 1→2→3→4→5→6→1
- [ ] Movement reset at round start
- [ ] Movement = 1 during attack phase

---

## Original Binary Offsets

For reference, key data locations in `weltendaemmerung.bin`:

| Data | Binary Offset | C64 Address |
|------|---------------|-------------|
| Tile graphics | $0DF1 | $15F0 |
| Map data (RLE) | $0F89 | $1788 |
| Unit placement | $0858 | $1057 |
| Unit stat tables | $0818 | $1017 |

---

## Resources

- Original binary: `disassembly/archive/weltendaemmerung.bin`
- Disassembly: `disassembly/*.asm`
- Extracted tiles: `assets/tiles/`
- Full map render: `assets/map.png`
- Map with units: `assets/map_with_units.png`
- Documentation: `docs/*.md`
