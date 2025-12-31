# Weltendaemmerung Game Variables

| Address     | Name           | Description                                      |
|-------------|----------------|--------------------------------------------------|
| $01         | CPU_PORT       | Memory configuration ($31=ROMs off, $37=ROMs on) |
| $61         | FAC_MANTISSA   | BASIC FAC mantissa (math calculations)           |
| $65         | ARG_MANTISSA   | BASIC ARG mantissa (math calculations)           |
| $B4-$B5     | MAP_PTR        | Map data pointer                                 |
| $D1-$D2     | SCREEN_PTR     | Current screen line pointer (KERNAL)             |
| $D3         | CURSOR_COL     | Cursor column position (KERNAL)                  |
| $D6         | CURSOR_ROW     | Cursor row position (KERNAL)                     |
| $F3-$F4     | COLOR_PTR      | Current color RAM pointer (KERNAL)               |
| $F7-$F8     | TEMP_PTR1      | General purpose pointer                          |
| $F9-$FA     | TEMP_PTR2      | General purpose pointer                          |
| $0286       | CHARCOLOR      | Current character color                          |
| $0314-$0315 | IRQ_VECTOR     | Hardware IRQ vector (LO/HI)                      |
| $0340       | SCROLL_X       | Map scroll X position (0-42)                     |
| $0341       | SCROLL_Y       | Map scroll Y position (0-21)                     |
| $0342-$0343 | TEMP_CALC      | Temporary calculation storage                    |
| $0344-$0345 | TEMP_STORE     | Additional temp storage                          |
| $0346       | COUNTER        | General counter / temporary                      |
| $0347       | CURRENT_PLAYER | Active player (0=Eldoin, 1=Dailor)              |
| $0348       | IRQ_COUNT      | IRQ countdown timer                              |
| $034A       | GAME_STATE     | Current game phase/mode                          |
| $034B       | CURSOR_MAP_Y   | Cursor Y position on map                         |
| $034C       | CURSOR_MAP_X   | Cursor X position on map                         |
| $034D       | PREV_JOY       | Previous joystick state                          |
| $034E       | UNIT_TYPE_IDX  | Selected unit type index                         |
| $034F       | ACTION_UNIT    | Unit type in current action                      |
| $0350-$0351 | STORED_PTR     | Stored F9/FA pointer backup                      |
| $0352       | STORED_CHAR    | Stored screen character                          |
| $0353       | MOVE_FLAG      | Movement validation flag                         |
| $0354       | JOY_STATE      | Current joystick state                           |
| $0355       | ATTACK_SRC_Y   | Attack source Y coordinate                       |
| $0356       | ATTACK_SRC_X   | Attack source X coordinate                       |
| $0357       | ATTACKER_TYPE  | Attacking unit type                              |
| $0358-$0359 | ATTACKER_PTR   | Pointer to attacker data                         |
| $035C       | SAVE_LETTER    | Save game filename letter (A-Z)                  |
| $035D       | MENU_SELECT    | Menu selection state                             |
| $4FF0       | ELDOIN_UNITS   | Unit counter for Eldoin player                  |
| $4FF2-$4FFE | TOWN_FLAGS     | Town capture flags (13 towns)                    |
| $5000-$5FA0 | MAP_DATA       | Game map data (80x40 tiles)                      |
| $C3F8-$C3FF | SPRITE_PTRS    | Sprite block pointers                            |
