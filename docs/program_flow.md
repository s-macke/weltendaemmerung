# Program Flow and Turn Structure

This document describes the program flow, turn structure, and state machine of Weltendämmerung.

## High-Level Program Flow

```mermaid
flowchart TD
    START[BASIC SYS 2061] --> INIT[Hardware Initialization<br/>$080D]
    INIT --> MEMCOPY[Copy ROM $D000-$DFFF<br/>to $E000-$EFFF]
    MEMCOPY --> CHARSET[Load Custom Charset<br/>sub_15CD]
    CHARSET --> MENU[Display Main Menu<br/>sub_0BF3]

    MENU --> F1{F1 or F3?}
    F1 -->|F1 - Load Game| LOAD[Load Saved Game<br/>sub_2364]
    F1 -->|F3 - New Game| NEWGAME[Initialize Map<br/>sub_1721]

    LOAD --> SETUP
    NEWGAME --> INITUNITS[Place Units on Map<br/>sub_0FAC]
    INITUNITS --> SETUP[Setup Game Display<br/>Music, Sprites, IRQ]

    SETUP --> GAMELOOP[Main Game Loop<br/>loc_088D]

    GAMELOOP --> INPUT{Joystick Input}
    INPUT -->|No Input| IDLE[Idle Animation<br/>sub_12C0]
    IDLE --> GAMELOOP

    INPUT -->|Fire Button| FIREACTION[Fire Button Handler<br/>sub_0ECF]
    INPUT -->|Direction| MOVECURSOR[Move Cursor Sprite<br/>L08ED/L0911/L092E/L096F]

    FIREACTION --> UNITSELECT{Unit at Cursor?}
    UNITSELECT -->|Yes - Own Unit| SELECT[Select Unit<br/>Store in $0350-0352]
    UNITSELECT -->|Yes - Enemy| COMBAT[Combat Check<br/>sub_12EE]
    UNITSELECT -->|No| DESELECT[Deselect / Place Unit]

    SELECT --> GAMELOOP
    DESELECT --> GAMELOOP
    COMBAT --> RESOLVE[Resolve Combat<br/>$1328-13FD]

    RESOLVE --> DESTROYED{Unit Destroyed?}
    DESTROYED -->|Yes| CHECKWIN[Check Victory<br/>sub_2197]
    DESTROYED -->|No| GAMELOOP

    CHECKWIN --> VICTORY{All Enemy<br/>Units Gone?}
    VICTORY -->|Yes| ENDGAME[Victory Screen<br/>loc_1456]
    VICTORY -->|No| GAMELOOP

    MOVECURSOR --> MOVEVALID[Validate Movement<br/>sub_0A70]
    MOVEVALID --> TERRAIN[Check Terrain<br/>sub_0B10]
    TERRAIN --> DEDUCT[Deduct Movement<br/>L0B01]
    DEDUCT --> GAMELOOP
```

## Turn Structure State Machine

The game uses a 6-state turn system controlled by two variables:
- `$034A` - GAME_STATE (phase: 0, 1, or 2)
- `$0347` - CURRENT_PLAYER (0 = Feldoin, 1 = Dailor)

Combined state = `(GAME_STATE * 2) + CURRENT_PLAYER + 1`

### The Three Phases (German names from game text)

1. **Bewegungsphase** (Movement Phase) - Phase 0
   - Full movement points available
   - Units can move and reposition

2. **Angriffsphase** (Attack Phase) - Phase 1
   - Movement restricted to 1 point per unit
   - Combat actions enabled

3. **Torphase** (Gate/Fortification Phase) - Phase 2
   - Players can build fortifications on their territory
   - Feldoin (Y < 60): Can place walls ($71) or mountains ($6F)
   - Dailor (Y >= 60): Can place walls ($71) or mountains ($6F)
   - Gates ($6E) can be converted: Feldoin→Wall, Dailor→Meadow

```mermaid
stateDiagram-v2
    [*] --> P1_Move: Game Start

    P1_Move: Bewegungsphase - Feldoin
    P1_Move: Full movement points

    P2_Move: Bewegungsphase - Dailor
    P2_Move: Full movement points

    P1_Attack: Angriffsphase - Feldoin
    P1_Attack: Movement = 1, Combat enabled

    P2_Attack: Angriffsphase - Dailor
    P2_Attack: Movement = 1, Combat enabled

    P1_Gate: Torphase - Feldoin
    P1_Gate: Build fortifications (Y < 60)

    P2_Gate: Torphase - Dailor
    P2_Gate: Build fortifications (Y >= 60)

    P1_Move --> P2_Move: End Turn
    P2_Move --> P1_Attack: End Turn
    P1_Attack --> P2_Attack: End Turn
    P2_Attack --> P1_Gate: End Turn
    P1_Gate --> P2_Gate: End Turn
    P2_Gate --> P1_Move: New Round<br/>Reset Movement<br/>Increment Turn

    note right of P2_Gate
        Turn counter incremented
        (BCD at $4FFF)
        Check for Turn 15
    end note
```

## Turn Phase Details

### State Transitions (loc_1EA8)

| Combined State | Phase | Player | German Name | Action |
|----------------|-------|--------|-------------|--------|
| 1 | 0 | 0 (Feldoin) | Bewegungsphase | Movement phase, full points |
| 2 | 0 | 1 (Dailor) | Bewegungsphase | Movement phase, set movement=1 for next |
| 3 | 1 | 0 (Feldoin) | Angriffsphase | Attack phase, movement=1 |
| 4 | 1 | 1 (Dailor) | Angriffsphase | Attack phase |
| 5 | 2 | 0 (Feldoin) | Torphase | Fortification phase |
| 6 | 2 | 1 (Dailor) | Torphase | End round, reset, increment turn |

### Movement Point Reset

At the end of each round (state 6 → 1), the game:
1. Calls `sub_20C0` - Resets all units' movement points (B current = B max)
2. Calls `sub_227E` - Increments turn counter and checks for game end

### Attack Phase Restrictions

When entering states 2 or 3, `sub_20D3` sets all units' movement points to 1, limiting movement during attack phases.

### Fortification Phase (Torphase) Details

The Torphase (`L0ED9` in `$0E14-$0FAB_sound_sprites.asm`) allows terrain modification:

```mermaid
flowchart TD
    START[Fire Button in Phase 2] --> CHECKSIDE{Check Map Position}

    CHECKSIDE -->|Feldoin & Y < 60| ALLOWED1[Allowed - Own Territory]
    CHECKSIDE -->|Dailor & Y >= 60| ALLOWED2[Allowed - Own Territory]
    CHECKSIDE -->|Wrong Side| DENIED[Action Denied]

    ALLOWED1 --> CHECKUNIT{Unit on Tile?}
    ALLOWED2 --> CHECKUNIT

    CHECKUNIT -->|Yes| UPDATETERRAIN[Update Terrain Under Unit<br/>stores in unit record]
    CHECKUNIT -->|No| PLACETERRAIN[Place Terrain on Map]

    PLACETERRAIN --> CHECKGATE{Is it a Gate?}
    CHECKGATE -->|Yes, Feldoin| WALL[Place Wall $71]
    CHECKGATE -->|Yes, Dailor| MEADOW[Place Meadow $69]
    CHECKGATE -->|No| MOUNTAIN[Place Mountain $6F]

    UPDATETERRAIN --> DONE[Update Display]
    WALL --> DONE
    MEADOW --> DONE
    MOUNTAIN --> DONE
```

**Territory Boundary:** Y coordinate $3C (60) divides the map:
- Feldoin territory: Y < 60 (northern half)
- Dailor territory: Y >= 60 (southern half)

**Buildable Terrain:**
- Mountains ($6F / "Gebirge") - Default fortification
- Walls ($71 / "Mauer") - When building on gates (Feldoin only)
- Meadow ($69 / "Wiese") - When Dailor destroys a gate
