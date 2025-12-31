; =============================================================================
; Torphase (Fortification Phase) - Build Actions
; Address range: $0F06 - $0FAB
; =============================================================================
; Phase 2 allows players to build fortifications on their own territory.
; Territory boundary: X = $3C (60)
;   - Eldoin (Player 0): Can build on X < 60 (western half)
;   - Dailor (Player 1): Can build on X >= 60 (eastern half)
; =============================================================================

; -----------------------------------------------------------------------------
; L0F06 - Build Fortification (Torphase Action)
; -----------------------------------------------------------------------------
; Places terrain on map during Torphase:
;   - Default: Mountains ($6F / Gebirge)
;   - On Gate: Eldoin places Wall ($71), Dailor places Meadow ($69)
;   - If unit on tile: Updates terrain stored in unit[5]
; -----------------------------------------------------------------------------
L0F06:
        LDA #$00
        STA $034E               ; UNIT_TYPE_IDX (clear unit type)
        JSR sub_0F8C            ; Check if cursor is on valid build location
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
        LDA #$6F                ; Default: Mountains (Gebirge)

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
; When building on a Gate (Tor):
;   - Eldoin (Player 0): Converts gate to Wall ($71 / Mauer)
;   - Dailor (Player 1): Converts gate to Meadow ($69 / Wiese)
; -----------------------------------------------------------------------------
L0F4E:
        LDA $0347               ; CURRENT_PLAYER
        BEQ L0F58               ; Branch if Eldoin
        ; Dailor: destroy gate (convert to meadow)
        LDA #$69                ; Meadow (Wiese)
        JMP loc_0F2D

L0F58:
        ; Eldoin: fortify gate (convert to wall)
        LDA #$71                ; Wall (Mauer)
        JMP loc_0F2D

; -----------------------------------------------------------------------------
; Build location coordinate data (13 locations)
; $0F5D: X coordinates, $0F6A: Y coordinates
; -----------------------------------------------------------------------------
        .byte $05, $11, $1D, $0E, $2A, $2F, $34, $19, $05, $0B, $46, $45, $4B, $06, $05, $0A  ; ....*/4...fek...
        .byte $15, $15, $15, $15, $19, $23, $22, $07, $11, $22  ; .....#".."

; -----------------------------------------------------------------------------
; L0F77 - Update terrain stored in unit record
; -----------------------------------------------------------------------------
L0F77:
        JSR sub_1FF6
        LDY #$05
        PLA
        STA ($F9),Y             ; TEMP_PTR2 (general ptr lo)
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
; sub_0F8C - Check if cursor is on valid build location
; -----------------------------------------------------------------------------
; Checks cursor against 13 allowed build locations.
; If NOT on a valid location, aborts by popping return address.
; Also checks $4FF2,X STATE_GATE_FLAGS - negative flag prevents building.
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
