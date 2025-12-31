# Weltendaemmerung Game Variables

## Zero Page Variables

| Address     | Name           | Description                                      |
|-------------|----------------|--------------------------------------------------|
| $01         | CPU_PORT       | Memory configuration ($31=ROMs off, $37=ROMs on) |
| $61         | FAC_MANTISSA   | BASIC FAC mantissa (math calculations)           |
| $65         | ARG_MANTISSA   | BASIC ARG mantissa (math calculations)           |
| $A7         | TEMP_SPRITE_Y  | Temporary sprite Y position calculation          |
| $A8         | TEMP_SPRITE_X  | Temporary sprite X position calculation          |
| $A9         | TEMP_SPRITE_MSB| Temporary sprite X MSB calculation               |
| $B4-$B5     | MAP_PTR        | Map data pointer                                 |
| $D1-$D2     | SCREEN_PTR     | Current screen line pointer (KERNAL)             |
| $D3         | CURSOR_COL     | Cursor column position (KERNAL)                  |
| $D6         | CURSOR_ROW     | Cursor row position (KERNAL)                     |
| $F3-$F4     | COLOR_PTR      | Current color RAM pointer (KERNAL)               |
| $F7-$F8     | TEMP_PTR1      | General purpose pointer                          |
| $F9-$FA     | TEMP_PTR2      | General purpose pointer / unit record pointer    |

## Game State Variables ($0340-$035D)

| Address     | Name           | Description                                      |
|-------------|----------------|--------------------------------------------------|
| $0286       | CHARCOLOR      | Current character color                          |
| $0288       | HIBASE         | Screen memory page ($C0 = screen at $C000)       |
| $0314-$0315 | IRQ_VECTOR     | Hardware IRQ vector (LO/HI)                      |
| $0340       | SCROLL_X       | Map scroll X position (0-42)                     |
| $0341       | SCROLL_Y       | Map scroll Y position (0-21)                     |
| $0342-$0343 | TEMP_CALC      | Temporary calculation storage (LO/HI)            |
| $0344-$0345 | TEMP_STORE     | Additional temp storage (LO/HI)                  |
| $0346       | COUNTER        | General counter / temporary                      |
| $0347       | CURRENT_PLAYER | Active player (0=Eldoin, 1=Dailor)               |
| $0348       | IRQ_COUNT      | IRQ countdown timer                              |
| $034A       | GAME_STATE     | Current game phase (0=Bewegung, 1=Angriff, 2=Tor)|
| $034B       | CURSOR_MAP_X   | Cursor X position on map (0-79)                  |
| $034C       | CURSOR_MAP_Y   | Cursor Y position on map (0-39)                  |
| $034D       | PREV_JOY       | Previous joystick state                          |
| $034E       | UNIT_TYPE_IDX  | Current unit type index during initialization    |
| $034F       | ACTION_UNIT    | Unit/terrain type at cursor (index from $69)     |
| $0350-$0351 | STORED_PTR     | Stored F9/FA pointer backup (LO/HI)              |
| $0352       | STORED_CHAR    | Stored screen character                          |
| $0353       | MOVE_FLAG      | Movement validation flag                         |
| $0354       | JOY_STATE      | Current joystick state                           |
| $0355       | ATTACK_SRC_X   | Attack source X coordinate                       |
| $0356       | ATTACK_SRC_Y   | Attack source Y coordinate                       |
| $0357       | ATTACKER_TYPE  | Attacking unit type (0-15)                       |
| $0358-$0359 | ATTACKER_PTR   | Pointer to attacker unit record (LO/HI)          |
| $035C       | TEMP_COMBAT    | Temporary combat calculation / save letter       |
| $035D       | MENU_SELECT    | Menu selection state                             |

## Game Data Memory

| Address       | Name           | Description                                    |
|---------------|----------------|------------------------------------------------|
| $4FF0         | ELDOIN_UNITS   | Unit counter for Eldoin player                 |
| $4FF2-$4FFE   | GATE_FLAGS     | Gate/build location flags (13 locations)       |
| $4FFF         | TURN_COUNTER   | Current turn number (BCD, game ends at $15)    |
| $5000-$5F9F   | MAP_DATA       | Game map data (80x40 tiles = 3200 bytes)       |
| $5FA0+        | UNIT_DATA      | Unit records (6 bytes each, see below)         |

## Unit Stat Tables (BCD encoded)

| Address       | Name           | Description                                    |
|---------------|----------------|------------------------------------------------|
| $1017 (16b)   | V_TABLE        | Verteidigung (Defense) - initial values        |
| $1027 (16b)   | R_TABLE        | Reichweite (Range) - constant per unit type    |
| $1037 (16b)   | B_TABLE        | Bewegung (Movement) - initial values           |
| $1047 (16b)   | A_TABLE        | Angriff (Attack) - constant per unit type      |

## Unit Record Structure (6 bytes at $5FA0+)

| Offset | Name      | Description                                      |
|--------|-----------|--------------------------------------------------|
| 0      | X         | X coordinate on map (0-79)                       |
| 1      | Y         | Y coordinate on map (0-39)                       |
| 2      | V         | Current defense (decreases in combat, BCD)       |
| 3      | B_current | Current movement points (decreases on move, BCD) |
| 4      | B_max     | Maximum movement points (reset value, BCD)       |
| 5      | terrain   | Original terrain under unit (char code)          |

Note: Unit[4] = 0 marks end of unit list. Unit[1] = $FF marks destroyed unit.

## Sprite Pointers

| Address       | Name           | Description                                    |
|---------------|----------------|------------------------------------------------|
| $C3F8-$C3FF   | SPRITE_PTRS    | Sprite block pointers (bank at $C000)          |

## VIC-II Registers Used

| Address | Name        | Description                                      |
|---------|-------------|--------------------------------------------------|
| $D000   | VIC_SP0X    | Sprite 0 X position (low byte)                   |
| $D001   | VIC_SP0Y    | Sprite 0 Y position                              |
| $D010   | VIC_SPXMSB  | Sprite X position MSB                            |
| $D015   | VIC_SPENA   | Sprite enable register                           |
| $D020   | VIC_EXTCOL  | Border color ($06 = Blue)                        |
| $D021   | VIC_BGCOL0  | Background color ($00 Black/$05 Green in map)    |
| $D027   | VIC_SP0COL  | Sprite 0 color                                   |
