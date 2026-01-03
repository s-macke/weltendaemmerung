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
    DESTROYED -->|Yes| CHECKWIN[Check Victory]
    DESTROYED -->|No| GAMELOOP

    CHECKWIN --> VICTORY{Victory<br/>Condition Met?}
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
- `$0347` - CURRENT_PLAYER (0 = Eldoin, 1 = Dailor)

Combined state = `(GAME_STATE * 2) + CURRENT_PLAYER + 1`

### The Three Phases (German names from game text)

1. **Bewegungsphase** (Movement Phase) - Phase 0
   - Full movement points available
   - Units can move and reposition

2. **Angriffsphase** (Attack Phase) - Phase 1
   - Movement restricted to 1 point per unit
   - Combat actions enabled

3. **Torphase** (Gate Phase) - Phase 2
   - Players can toggle gates at 13 fixed positions on the map
   - Eldoin (X < 60): Closes gates → Wall ($71)
   - Dailor (X >= 60): Opens gates → Meadow ($69)
   - 10 gate positions in Eldoin's territory, 3 in Dailor's

```mermaid
stateDiagram-v2
    [*] --> P1_Move: Game Start

    P1_Move: Bewegungsphase - Eldoin
    P1_Move: Full movement points

    P2_Move: Bewegungsphase - Dailor
    P2_Move: Full movement points

    P1_Attack: Angriffsphase - Eldoin
    P1_Attack: Movement = 1, Combat enabled

    P2_Attack: Angriffsphase - Dailor
    P2_Attack: Movement = 1, Combat enabled

    P1_Gate: Torphase - Eldoin
    P1_Gate: Close gates (X < 60)

    P2_Gate: Torphase - Dailor
    P2_Gate: Open gates (X >= 60)

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

| Combined State | Phase | Player     | German Name    | Action                                  |
|----------------|-------|------------|----------------|-----------------------------------------|
| 1              | 0     | 0 (Eldoin) | Bewegungsphase | Movement phase, full points             |
| 2              | 0     | 1 (Dailor) | Bewegungsphase | Movement phase, set movement=1 for next |
| 3              | 1     | 0 (Eldoin) | Angriffsphase  | Attack phase, movement=1                |
| 4              | 1     | 1 (Dailor) | Angriffsphase  | Attack phase                            |
| 5              | 2     | 0 (Eldoin) | Torphase       | Fortification phase                     |
| 6              | 2     | 1 (Dailor) | Torphase       | End round, reset, increment turn        |

### Movement Point Reset

At the end of each round (state 6 → 1), the game:
1. Calls `sub_20C0` - Resets all units' movement points (B current = B max)
2. Calls `sub_227E` - Increments turn counter and checks for game end

### Attack Phase Restrictions

When entering states 2 or 3, `sub_20D3` sets all units' movement points to 1, limiting movement during attack phases.

### Gate Phase (Torphase) Details

Players can toggle gates at 13 fixed positions. Code at `L0F06` in `$0F06-$0FAB_torphase.asm`.

```mermaid
flowchart TD
    START[Fire Button in Phase 2] --> CHECKSIDE{Check Territory}

    CHECKSIDE -->|Eldoin & X < 60| CHECKPOS1[Check Position]
    CHECKSIDE -->|Dailor & X >= 60| CHECKPOS2[Check Position]
    CHECKSIDE -->|Wrong Territory| DENIED[Action Denied]

    CHECKPOS1 --> VALIDPOS{Fixed Gate Position?}
    CHECKPOS2 --> VALIDPOS

    VALIDPOS -->|No| DENIED
    VALIDPOS -->|Yes| CHECKGATE{Current Terrain}

    CHECKGATE -->|Gate| TOGGLE[Toggle Gate]
    CHECKGATE -->|Other| MOUNTAIN[Place Mountain $6F]

    TOGGLE --> PLAYER{Player}
    PLAYER -->|Eldoin| WALL[Close: Wall $71]
    PLAYER -->|Dailor| MEADOW[Open: Meadow $69]

    WALL --> DONE[Update Display]
    MEADOW --> DONE
    MOUNTAIN --> DONE
```

**Fixed Gate Positions:** 13 predefined locations (coordinates at $0F5D/$0F6A)
- 10 gates in Eldoin's territory (X < 60)
- 3 gates in Dailor's territory (X >= 60)

**Gate Actions:**
- Eldoin closes gates: Gate ($6F) → Wall ($71)
- Dailor opens gates: Gate ($6F) → Meadow ($69)

## Victory Conditions

*See [victory_conditions.md](victory_conditions.md) for detailed victory condition mechanics, code locations, and game balance analysis.*

| Condition           | Winner | Trigger                            |
|---------------------|--------|------------------------------------|
| Turn Limit          | Eldoin | Turn counter reaches 15            |
| Commander Destroyed | Dailor | Eldoin's Feldherr unit eliminated  |
| Army Annihilation   | Eldoin | All Dailor units destroyed         |
