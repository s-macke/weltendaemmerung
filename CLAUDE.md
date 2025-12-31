# Weltendaemmerung

A Commodore 64 fantasy strategy game for two players.
"Weltendämmerung" (Twilight of the Worlds) is a turn-based fantasy strategy game for two commanders ("Feldherren").

## Files

- `disassembly/archive/weltendaemmerung.bin` - Original C64 binary
- `disassembly/archive/weltendaemmerung.asm` - Original disassembled 6502 assembly (archived)
- `tools/c64_disasm.py` - Disassembler with flow analysis to distinguish code from data
- `tools/extract_tiles.py` - Extract character tiles to PNG with C64 color support
- `tools/extract_map.py` - Extract map and render with terrain/units
- `assets/tiles/` - Extracted 8x8 PNG tiles (38 tiles with authentic colors)
- `assets/map.png` - Rendered terrain map (640x320)
- `assets/map_with_units.png` - Rendered map with initial unit placement
- `docs/memory_layout.md` - Memory Map
- `docs/variables.md` - Game State Variables
- `docs/map.md` - Terrain types, tile mappings, color system
- `docs/movement.md` - Movement system, terrain costs, unit-specific movement tables
- `docs/attack.md` - Attack phase, combat formulas, damage calculation, range system
- `docs/torphase.md` - Torphase (gate phase), fortification mechanics, 13 gate positions
- `docs/units.md` - Unit types, statistics, initial placement (292 units total)
- `docs/victory_conditions.md` - Victory conditions, win states, game balance
- `docs/program_flow.md` - Program flow, turn structure, state machine diagrams
- `docs/save_format.md` - Save game file format, memory layout for disk I/O
- `docs/title_screen.md` - Title screen, startup sequence, menu system, animation

## Module Structure

The disassembly is split into functional modules in `disassembly/`:

| File                               | Address Range | Description                           |
|------------------------------------|---------------|---------------------------------------|
| `$0801-$080C_basic_header.asm`     | $0801-$080C | BASIC SYS autostart header            |
| `$080D-$0884_initialization.asm`   | $080D-$0884 | Hardware init, memory setup           |
| `$0885-$0A6F_main_loop_input.asm`  | $0885-$0A6F | Main game loop, joystick input        |
| `$0A70-$0BF2_movement.asm`         | $0A70-$0BF2 | Movement validation                   |
| `$0BF3-$0E13_menu_text.asm`        | $0BF3-$0E13 | Menu system, text output, interrupts  |
| `$0E14-$0F05_sound_sprites.asm`    | $0E14-$0F05 | SID init, IRQ, fire button handler    |
| `$0F06-$0FAB_torphase.asm`         | $0F06-$0FAB | Torphase fortification building       |
| `$0FAC-$12B0_game_logic.asm`       | $0FAC-$12B0 | Core game state, data tables          |
| `$12B1-$15CC_attack_turn.asm`      | $12B1-$15CC | Attack system, turn management        |
| `$15CD-$1A3E_graphics_data.asm`    | $15CD-$1A3E | Character sprites, graphics patterns  |
| `$1A3F-$1E8A_utilities_render.asm` | $1A3F-$1E8A | Utilities, rendering, music           |
| `$1E8B-$2012_display_terrain.asm`  | $1E8B-$2012 | Display, terrain info, phase transitions |
| `$2013-$20B6_sound_effects.asm`    | $2013-$20B6 | Sound effects (part 1)                |
| `$20B7-$20E6_unit_management.asm`  | $20B7-$20E6 | Unit pointer, movement points         |
| `$20E7-$227D_sound_effects2.asm`   | $20E7-$227D | Sound effects (part 2)                |
| `$227E-$2306_turn_victory.asm`     | $227E-$2306 | Turn counter, victory check           |
| `$2307-$23D7_file_io.asm`          | $2307-$23D7 | Save/load game, disk I/O              |

### Functional Categories

**Core Engine:**
- Initialization ($080D), Main Loop ($0885), Game Logic ($0FAC)

**Graphics:**
- Sprites ($0E14), Character Graphics ($15CD), Rendering ($1A3F)

**Audio:**
- Sound Init ($0E14), Victory/Defeat Music ($1C88/$1CBC), Sound Effects ($2013)

**UI:**
- Menu/Text ($0BF3), Display/Terrain Info ($1E8B)

**Game Systems:**
- Movement ($0A70), Torphase ($0F06), Attack/Turn Management ($12B1), Unit Management ($20B7), Turn/Victory ($227E)

**I/O:**
- File I/O ($2307) - Save/Load with KERNAL routines

## Turn Structure

The game uses a 6-state turn system with 3 phases per round, alternating between players:

| Phase | German Name      | Description                                    |
|-------|------------------|------------------------------------------------|
| 0     | Bewegungsphase   | Movement phase - full movement points          |
| 1     | Angriffsphase    | Attack phase - movement restricted to 1        |
| 2     | Torphase         | Gate/Fortification phase - build on own territory |

**State Machine:** Combined state = `(GAME_STATE * 2) + CURRENT_PLAYER + 1`

| State | Phase | Player  | Action                              |
|-------|-------|---------|-------------------------------------|
| 1     | 0     | Eldoin | Movement                            |
| 2     | 0     | Dailor  | Movement                            |
| 3     | 1     | Eldoin | Attack (movement=1)                 |
| 4     | 1     | Dailor  | Attack (movement=1)                 |
| 5     | 2     | Eldoin | Fortification (Y < 60)              |
| 6     | 2     | Dailor  | Fortification (Y >= 60), end round  |

**Key Variables:**
- `$034A` - GAME_STATE (phase: 0, 1, 2)
- `$0347` - CURRENT_PLAYER (0=Eldoin, 1=Dailor)
- `$4FFF` - Turn counter (BCD, game ends at turn 15)

