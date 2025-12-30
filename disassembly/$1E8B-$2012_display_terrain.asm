; =============================================================================
; Display Utilities and Terrain/Unit Info
; Address range: $1E8B - $2012
; =============================================================================
; This module handles:

; - String output routines
; - Game state/turn management
; - Terrain and unit information display at cursor position
; - Cursor position to map coordinate conversion
; =============================================================================

; -----------------------------------------------------------------------------
; sub_1E8B - Print String from $1D54 Table
; -----------------------------------------------------------------------------
; Prints characters starting at $1D54+X until $5C terminator is reached
; -----------------------------------------------------------------------------
sub_1E8B:
        LDA $1D54,X
        CMP #$5C
        BEQ L1E99
        JSR CHROUT
        INX
        JMP sub_1E8B

L1E99:
        RTS

; -----------------------------------------------------------------------------
; sub_1E9A - Print String from $1DBE Table
; -----------------------------------------------------------------------------
; Prints characters starting at $1DBE+X until $5C terminator is reached
; -----------------------------------------------------------------------------
sub_1E9A:
        LDA $1DBE,X
        CMP #$5C
        BEQ L1E99
        JSR CHROUT
        INX
        JMP sub_1E9A

; -----------------------------------------------------------------------------
; loc_1EA8 - Game State/Turn Management
; -----------------------------------------------------------------------------
; Handles game phase transitions and player turns
; -----------------------------------------------------------------------------
loc_1EA8:
        LDA $034A               ; GAME_STATE (game phase)
        ASL A
        CLC
        ADC $0347               ; CURRENT_PLAYER (active player)
        ADC #$01
        CMP #$06
        BNE L1EC1
        JSR sub_20C0
        JSR sub_227E
        LDA #$00
        JMP loc_1ECE

L1EC1:
        CMP #$02
        BEQ L1EC9
        CMP #$03
        BNE loc_1ECE

L1EC9:
        PHA
        JSR sub_20D3
        PLA

loc_1ECE:
        TAX
        AND #$01
        STA $0347               ; CURRENT_PLAYER (active player)
        TXA
        LSR A
        STA $034A               ; GAME_STATE (game phase)
        JSR sub_1F69
        JSR sub_1C35
        JMP sub_1D0E

; -----------------------------------------------------------------------------
; sub_1EE2 - Display Terrain/Unit Info at Cursor Position
; -----------------------------------------------------------------------------
; Reads the tile at cursor position and displays its name.
; If terrain_index < 11 ($0B): displays terrain name (Wiese, Fluss, etc.)
; If terrain_index >= 11: displays unit type name
; Uses lookup table at $1D39 for string offsets
; -----------------------------------------------------------------------------
sub_1EE2:
        JSR sub_1F1C            ; Get terrain/unit index from cursor
        PHA
        CMP #$0B                ; Is it a terrain type (< 11)?
        BCS L1F14               ; No, it's a unit - handle separately
        PHA
        LDX #$18
        JSR $E9FF               ; KERNAL: set cursor position
        PLA

loc_1EF1:
        TAX
        LDA $1D39,X             ; Load string offset for terrain index X
        PHA
        LDX #$17
        JSR $E9FF
        LDY #$0F
        JSR $E50C
        PLA
        TAX
        JSR sub_1E9A
        PLA
        CMP #$06
        BEQ L1E99
        JSR sub_0F8C
        BMI L1E99
        LDX #$2F
        JMP sub_1E8B

L1F14:
        PHA
        JSR sub_1FAB
        PLA
        JMP loc_1EF1

; -----------------------------------------------------------------------------
; sub_1F1C - Get Terrain/Unit Index from Cursor Position
; -----------------------------------------------------------------------------
; Converts sprite cursor position to map coordinates, reads the tile,
; and calculates the terrain index using: terrain_index = char_code - $69
;
; TERRAIN INDEX MAPPING:
;   Char $69 -> Index 0 -> Wiese (Meadow)
;   Char $6A -> Index 1 -> Fluss (River)
;   Char $6B -> Index 2 -> Wald (Forest)
;   Char $6C -> Index 3 -> Ende (Edge)
;   Char $6D -> Index 4 -> Sumpf (Swamp)
;   Char $6E -> Index 5 -> Tor (Gate)
;   Char $6F -> Index 6 -> Gebirge (Mountains)
;   Char $70 -> Index 7 -> Pflaster (Pavement)
;   Char $71 -> Index 8 -> Mauer (Wall)
;   Char $72 -> Index 9 -> (additional terrain)
;   Char $73 -> Index 10 -> (additional terrain)
;   Char < $69 -> Index 9 (default: Mauer/Wall)
;   Char >= $74 -> Unit types (unit_type = char - $74)
;
; Output: A = terrain/unit index, stored in $034F
; -----------------------------------------------------------------------------
sub_1F1C:
        LDA VIC_SP0Y            ; Get sprite Y position
        SEC
        SBC #$30                ; Subtract screen offset
        LSR A
        LSR A
        LSR A                   ; Divide by 8 for tile row
        STA $A7
        LDA VIC_SP0X            ; Get sprite X position (low byte)
        STA $A8
        LDA VIC_SPXMSB          ; Get sprite X MSB
        AND #$01
        STA $A9
        LDA $A8
        SEC
        SBC #$16                ; Subtract screen offset
        STA $A8
        LDA $A9
        SBC #$00
        STA $A9
        LSR $A9
        ROR $A8
        LSR $A8
        LSR $A8                 ; Divide by 8 for tile column
        LDA $A7
        CLC
        ADC $0341               ; SCROLL_Y (map scroll Y)
        STA $034C               ; CURSOR_MAP_X (cursor X on map)
        LDA $A8
        ADC $0340               ; SCROLL_X (map scroll X)
        STA $034B               ; CURSOR_MAP_Y (cursor Y on map)
        JSR sub_1F77
        LDA ($D1),Y             ; SCREEN_PTR (screen line ptr lo) - read char code
        SEC
        SBC #$69                ; Calculate terrain index = char - $69
        BCS L1F65               ; If char >= $69, use calculated index
        LDA #$09                ; If char < $69, default to index 9 (Mauer)

L1F65:
        STA $034F               ; ACTION_UNIT (unit in action) - terrain/unit index
        RTS

; -----------------------------------------------------------------------------
; sub_1F69 - Sound and Display Update
; -----------------------------------------------------------------------------
sub_1F69:
        JSR sub_209C
        LDA #$14
        JSR sub_1CE4
        LDA #$14
        JSR sub_1CE4
        RTS

; -----------------------------------------------------------------------------
; sub_1F77 - Get Screen Position from Map Coordinates
; -----------------------------------------------------------------------------
sub_1F77:
        LDX $A7
        JSR $E9F0
        JSR $EA24
        LDY $A8
        RTS

; -----------------------------------------------------------------------------
; sub_1F82 - Combined Sound and Display
; -----------------------------------------------------------------------------
sub_1F82:
        JSR sub_2263
        JMP loc_2178

; -----------------------------------------------------------------------------
; sub_1F88 - Print Character with Equals Sign
; -----------------------------------------------------------------------------
sub_1F88:
        JSR CHROUT
        LDA #$3D
        JMP CHROUT

; -----------------------------------------------------------------------------
; sub_1F90 - Print BCD Number
; -----------------------------------------------------------------------------
; Prints a BCD number with space padding
; -----------------------------------------------------------------------------
sub_1F90:
        TAY
        LSR A
        LSR A
        LSR A
        LSR A
        BEQ L1F9D
        CLC
        ADC #$30
        JSR CHROUT

L1F9D:
        TYA
        AND #$0F
        CLC
        ADC #$30
        JSR CHROUT
        LDA #$20
        JMP CHROUT

; -----------------------------------------------------------------------------
; sub_1FAB - Display Unit Information
; -----------------------------------------------------------------------------
; Shows unit stats: R (rank), B (movement), A (attack), V (defense)
; -----------------------------------------------------------------------------
sub_1FAB:
        JSR sub_1F1C
        SEC
        SBC #$0B
        STA $0346               ; COUNTER (general counter)
        LDX #$18
        JSR $E9FF
        LDY #$0A
        JSR $E50C
        LDA #$52
        JSR sub_1F88
        LDX $0346               ; COUNTER (general counter)
        LDA $1027,X
        JSR sub_1F90
        LDA #$42
        JSR sub_1F88
        JSR sub_1FF6
        LDY #$02
        LDA ($F9),Y             ; TEMP_PTR2 (general ptr lo)
        PHA
        INY
        LDA ($F9),Y             ; TEMP_PTR2 (general ptr lo)
        JSR sub_1F90
        LDA #$41
        JSR sub_1F88
        LDX $0346               ; COUNTER (general counter)
        LDA $1047,X
        JSR sub_1F90
        LDA #$56
        JSR sub_1F88
        PLA
        JMP sub_1F90

; -----------------------------------------------------------------------------
; sub_1FF6 - Find Unit at Cursor Position
; -----------------------------------------------------------------------------
sub_1FF6:
        JSR sub_15C2

loc_1FF9:
        LDA ($F9),Y             ; TEMP_PTR2 (general ptr lo)
        TAX
        INX
        CPX $034B               ; CURSOR_MAP_Y (cursor Y on map)
        BNE L200C
        INY
        LDA ($F9),Y             ; TEMP_PTR2 (general ptr lo)
        TAX
        INX
        CPX $034C               ; CURSOR_MAP_X (cursor X on map)
        BEQ L2012

L200C:
        JSR sub_20B7
        JMP loc_1FF9

L2012:
        RTS
