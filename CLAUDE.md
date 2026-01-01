# Weltendaemmerung

A Commodore 64 fantasy strategy game for two players.
"Weltendämmerung" (Twilight of the Worlds) is a turn-based fantasy strategy game for two commanders ("Feldherren").

## Files

- `tools/extract_tiles.py` - Extract character tiles to PNG with C64 color support
- `tools/extract_map.py` - Extract map and render with terrain/units
- `assets/tiles/` - Extracted 8x8 PNG tiles (38 tiles with authentic colors)
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
- `docs/screen_display.md` - Screen layout, phase-specific display, status area, colors

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
| 1     | 0     | Eldoin  | Movement                            |
| 2     | 0     | Dailor  | Movement                            |
| 3     | 1     | Eldoin  | Attack (movement=1)                 |
| 4     | 1     | Dailor  | Attack (movement=1)                 |
| 5     | 2     | Eldoin  | Fortification (Y < 60)              |
| 6     | 2     | Dailor  | Fortification (Y >= 60), end round  |

