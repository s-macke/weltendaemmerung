# Weltendaemmerung

A Commodore 64 fantasy strategy game for two players.
"Weltendämmerung" (Twilight of the Worlds) is a turn-based fantasy strategy game for two commanders ("Feldherren").

## Files

- `disassembly/archive/weltendaemmerung.bin` - Original C64 binary
- `disassembly/archive/weltendaemmerung.asm` - Original disassembled 6502 assembly (archived)
- `tools/c64_disasm.py` - Disassembler with flow analysis to distinguish code from data

## Module Structure

The disassembly is split into functional modules in `disassembly/`:

| File                               | Address Range | Description                           |
|------------------------------------|---------------|---------------------------------------|
| `$0801-$080C_basic_header.asm`     | $0801-$080C | BASIC SYS autostart header            |
| `$080D-$0884_initialization.asm`   | $080D-$0884 | Hardware init, memory setup           |
| `$0885-$0A6F_main_loop_input.asm`  | $0885-$0A6F | Main game loop, joystick input        |
| `$0A70-$0BF2_movement_combat.asm`  | $0A70-$0BF2 | Movement validation, combat           |
| `$0BF3-$0E13_menu_text.asm`        | $0BF3-$0E13 | Menu system, text output, interrupts  |
| `$0E14-$0FAB_sound_sprites.asm`    | $0E14-$0FAB | SID init, IRQ, sprite handling        |
| `$0FAC-$12B0_game_logic.asm`       | $0FAC-$12B0 | Core game state, data tables          |
| `$12B1-$15CC_combat_turn.asm`      | $12B1-$15CC | Combat system, turn management        |
| `$15CD-$1A3E_graphics_data.asm`    | $15CD-$1A3E | Character sprites, graphics patterns  |
| `$1A3F-$1E8A_utilities_render.asm` | $1A3F-$1E8A | Utilities, rendering, music           |
| `$1E8B-$2306_sound_effects.asm`    | $1E8B-$2306 | Sound effects, damage calc            |
| `$2307-$23D7_file_io.asm`          | $2307-$23D7 | Save/load game, disk I/O              |

### Functional Categories

**Core Engine:**
- Initialization ($080D), Main Loop ($0885), Game Logic ($0FAC)

**Graphics:**
- Sprites ($0E14), Character Graphics ($15CD), Rendering ($1A3F)

**Audio:**
- Sound Init ($0E14), Victory/Defeat Music ($1C88/$1CBC), Sound Effects ($1E8B)

**UI:**
- Menu/Text ($0BF3)

**Game Systems:**
- Movement/Combat ($0A70), Combat/Turn Management ($12B1)

**I/O:**
- File I/O ($2307) - Save/Load with KERNAL routines
