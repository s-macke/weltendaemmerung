; =============================================================================
; Torphase (Gate Phase) - Modify Terrain at Fixed Positions
; Address range: $0F06 - $0FAB
; =============================================================================
; Phase 2 allows players to modify terrain at 13 fixed positions on the map.
; Territory boundary: X = $3C (60)
;   - Eldoin (Player 0): Converts Gate → Wall ($71) in X < 60 (western half)
;   - Dailor (Player 1): Converts Gate → Meadow ($69) in X >= 60 (eastern half)
; Both players place Gate ($6F) on non-gate terrain (overwrites existing).
; Gate positions are predefined at $0F5D (X) and $0F6A (Y).
; =============================================================================

; -----------------------------------------------------------------------------
; L0F06 - Torphase Action Handler
; -----------------------------------------------------------------------------
; Modifies terrain at fixed positions during Torphase:
;   - On Gate ($6F): Eldoin → Wall ($71), Dailor → Meadow ($69)
;   - On other terrain: Places Gate ($6F), overwriting existing terrain
;   - If unit on tile: Updates terrain stored in unit[5]
; Only works at 13 predefined gate positions (checked by sub_0F8C).
; -----------------------------------------------------------------------------
L0F06:
        LDA #$00
        STA $034E               ; UNIT_TYPE_IDX (clear unit type)
        JSR sub_0F8C            ; Check if cursor is on valid gate position
        JSR sub_1F1C            ; Get terrain/unit at cursor

loc_0F11:
        CMP #$06                ; Is it a Gate (Tor)?
        BEQ L0F4E               ; Yes, handle gate specially
        CMP #$0B                ; Is it a unit (index >= 11)?
        BCC L0F2B               ; No, place terrain directly
        ; Unit on tile: get terrain underneath
        STA $034E               ; Store unit type
        JSR sub_1FF6            ; Find unit record
        LDY #$05
        LDA ($F9),Y             ; Load unit[5] = terrain under unit
        TAX
        TXA
        SEC
        SBC #$69                ; Convert to terrain index
        JMP loc_0F11            ; Re-check terrain type

L0F2B:
        LDA #$6F                ; Default: Gate (Tor) - place new gate on non-gate terrain

loc_0F2D:
        PHA
        LDX $034E               ; Check if unit on tile
        BNE L0F77               ; Yes, update unit's stored terrain
        ; No unit: place terrain directly on map
        JSR sub_1F77            ; Get screen position
        PLA
        PHA
        STA ($D1),Y             ; Write to screen RAM
        JSR sub_1C01            ; Get color for terrain
        STA ($F3),Y             ; Write to color RAM
        LDX $034C               ; CURSOR_MAP_Y
        JSR sub_0F82            ; Get map position
        PLA
        STA ($B4),Y             ; Write to map data
        JSR sub_1F82            ; Play sound, update display
        JMP sub_1EE2            ; Update terrain info display

; -----------------------------------------------------------------------------
; L0F4E - Handle Gate Conversion
; -----------------------------------------------------------------------------
; When acting on a Gate (Tor), each player replaces it with different terrain:
;   - Eldoin (Player 0): Gate → Wall ($71 / Mauer) - creates barrier
;   - Dailor (Player 1): Gate → Meadow ($69 / Wiese) - creates open terrain
; -----------------------------------------------------------------------------
L0F4E:
        LDA $0347               ; CURRENT_PLAYER
        BEQ L0F58               ; Branch if Eldoin
        ; Dailor: convert gate to meadow (open terrain)
        LDA #$69                ; Meadow (Wiese)
        JMP loc_0F2D

L0F58:
        ; Eldoin: convert gate to wall (barrier)
        LDA #$71                ; Wall (Mauer)
        JMP loc_0F2D

; -----------------------------------------------------------------------------
; Gate Position Coordinate Data (13 Fixed Locations)
; -----------------------------------------------------------------------------
; $0F5D: X coordinates (13 bytes)
; $0F6A: Y coordinates (13 bytes)
;
; POSITION TABLE (index, X, Y, territory):
;   0: ( 5,  6) - Eldoin (far west, upper)
;   1: (17,  5) - Eldoin (west, upper)
;   2: (29, 10) - Eldoin (west-central, upper)
;   3: (14, 21) - Eldoin (west, middle)
;   4: (42, 21) - Eldoin (central, middle)
;   5: (47, 21) - Eldoin (central, middle)
;   6: (52, 21) - Eldoin (central, middle)
;   7: (25, 25) - Eldoin (west-central, lower-middle)
;   8: ( 5, 35) - Eldoin (far west, lower)
;   9: (11, 34) - Eldoin (west, lower)
;  10: (70,  7) - DAILOR (east, upper)
;  11: (69, 17) - DAILOR (east, middle)
;  12: (75, 34) - DAILOR (east, lower)
;
; Territory boundary at X=60 ($3C):
;   Positions 0-9:  Eldoin territory (X < 60)
;   Positions 10-12: Dailor territory (X >= 60)
;
; GATE DESTRUCTION:
; When a gate is destroyed in combat (e.g., by Rammbock attack), the gate
; counter at $4FF2,X is decremented. When it goes from $00 to $FF, bit 7
; becomes set. The BMI at L0FA5 then blocks all torphase actions at that
; position permanently - the gate cannot be rebuilt.
; -----------------------------------------------------------------------------
        .byte $05, $11, $1D, $0E, $2A, $2F, $34, $19, $05, $0B, $46, $45, $4B, $06, $05, $0A
        .byte $15, $15, $15, $15, $19, $23, $22, $07, $11, $22

; -----------------------------------------------------------------------------
; L0F77 - Update terrain stored in unit record
; -----------------------------------------------------------------------------
; BUG: Only updates unit[5], but movement code uses STORED_CHAR ($0352) to
; restore terrain when unit moves away. STORED_CHAR is NOT updated here!
; Result: Torphase changes on occupied gates are LOST when the unit moves.
; The terrain reverts to the original gate instead of the new wall/meadow.
; -----------------------------------------------------------------------------
L0F77:
        JSR sub_1FF6
        LDY #$05
        PLA
        STA ($F9),Y             ; Store new terrain in unit[5]
        JMP sub_1F82

; -----------------------------------------------------------------------------
; sub_0F82 - Calculate map position from X coordinate
; -----------------------------------------------------------------------------
sub_0F82:
        DEX
        TXA
        JSR sub_1AD3
        LDY $034B               ; CURSOR_MAP_X (cursor X on map)
        DEY
        RTS

; -----------------------------------------------------------------------------
; sub_0F8C - Check if cursor is on valid gate position
; -----------------------------------------------------------------------------
; Checks cursor against 13 allowed gate positions.
; If NOT on a valid position, aborts by popping return address.
; Also checks $4FF2,X STATE_GATE_FLAGS - negative flag prevents action.
; Gate flags start at $00; when destroyed in combat (DEC), they become $FF.
; $FF has bit 7 set, so BMI blocks torphase at destroyed gate positions.
; -----------------------------------------------------------------------------
sub_0F8C:
        LDX #$0C

L0F8E:
        LDA $034B               ; CURSOR_MAP_X (cursor X on map)
        CMP $0F5D,X
        BNE L0F9E
        LDA $034C               ; CURSOR_MAP_Y (cursor Y on map)
        CMP $0F6A,X
        BEQ L0FA1

L0F9E:
        DEX
        BPL L0F8E

L0FA1:
        BMI L0FA9
        LDA $4FF2,X             ; STATE_GATE_FLAGS (gate/build location flags)
        BMI L0FA9
        RTS

L0FA9:
        PLA
        PLA
        RTS
