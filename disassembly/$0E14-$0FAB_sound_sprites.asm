; =============================================================================
; Sound Initialization and Sprite Handling
; Address range: $0E14 - $0FAB
; =============================================================================

sub_0E14:
        LDA #$4F
        STA SID_VOLUME
        LDA #$F3
        STA SID_RESFLT
        LDX #$01
        STX $0343               ; TEMP_CALC (temp calc hi)
        DEX
        STX $0344               ; TEMP_STORE (temp storage lo)
        LDA #$8F
        JSR sub_20E7
        LDA #$04
        STA SID_V3AD
        LDA #$F1
        JSR sub_20F1
        LDA #$F7
        STA SID_V3SR
        LDA #$81
        STA SID_V1CTRL
        STA SID_V2CTRL
        STA SID_V1FREQH
        LDA #$01
        STA SID_V2FREQL
        LDA #$64
        STA SID_V3FREQH
        LDA #$C8
        STA SID_FCUTH
        RTS

sub_0E56:
        SEI
        LDA #$7A
        STA IRQ_VECTOR_LO
        LDA #$0E
        STA IRQ_VECTOR_HI
        LDX #$07
        STX $0348               ; IRQ_COUNT (IRQ timer)
        LDA #$00
        STA VIC_RASTER
        LDA VIC_SCROLY
        AND #$7F
        STA VIC_SCROLY
        LDA #$81
        STA VIC_IRQMSK
        CLI
        RTS
        .byte $AD, $19, $D0, $8D, $19, $D0, $30, $2C, $CE, $48, $03, $D0, $24, $D8, $A2, $06  ; ..P..P0,Nh.P$X..
        .byte $20, $22, $1B, $AC, $5F, $E3, $BD, $58, $E3, $0A, $69, $00, $9D, $59, $E3, $CA  ;  ".._..x..i..y.J
        .byte $10, $F4, $20, $28, $1B, $98, $0A, $69, $00, $8D, $58, $E3, $A9, $07, $8D, $48  ; .. (...i..x....h
        .byte $03, $4C, $7E, $EA, $AD, $12, $D0, $C9, $DC, $B0, $0D, $A9, $05, $8D, $21, $D0  ; .l~...PI......!P
        .byte $A9, $DC, $8D, $12, $D0, $4C, $BC, $FE, $A9, $06, $8D, $21, $D0, $A9, $00, $8D  ; ....Pl.....!P...
        .byte $12, $D0, $4C, $BC, $FE  ; .Pl..

; -----------------------------------------------------------------------------
; sub_0ECF - Fire Button (No Direction) Action Handler
; -----------------------------------------------------------------------------
; Called when fire button pressed without direction (joystick = $10).
;
; First checks terrain index 4 (Sumpf/Swamp, char $6D):
;   - If cursor on $6D: immediately end turn/phase (purpose unclear -
;     possibly "skip turn" mechanism or UI element in status area?)
;
; Otherwise dispatches based on current game phase:
;   - Phase 0 (Bewegungsphase): Unit selection/movement (sub_12B1)
;   - Phase 1 (Angriffsphase): Combat initiation (sub_12EE)
;   - Phase 2 (Torphase): Terrain fortification (L0F06) if on own territory
; -----------------------------------------------------------------------------
sub_0ECF:
        JSR sub_1F1C            ; Get terrain/unit index at cursor
        CMP #$04                ; Index 4 = Sumpf (char $6D)?
        BNE L0ED9               ; No, continue to phase dispatch
        JMP loc_1EA8            ; Yes, end turn/phase (skip mechanism?)

; -----------------------------------------------------------------------------
; L0ED9 - Torphase (Fortification Phase) Handler
; -----------------------------------------------------------------------------
; Phase 2 allows players to build fortifications on their own territory.
; Territory boundary: Y = $3C (60)
;   - Eldoin (Player 0): Can build on Y < 60 (northern half)
;   - Dailor (Player 1): Can build on Y >= 60 (southern half)
; -----------------------------------------------------------------------------
L0ED9:
        LDA $034A               ; GAME_STATE (game phase)
        CMP #$02                ; Is it Phase 2 (Torphase)?
        BNE L0EF6               ; No, check other phases
        LDX $034B               ; CURSOR_MAP_Y (cursor Y on map)
        LDA $0347               ; CURRENT_PLAYER (active player)
        BEQ L0EEE               ; Branch if Eldoin (Player 0)
        ; Dailor (Player 1): Can only build on Y >= 60
        CPX #$3C                ; Compare Y with territory boundary
        BMI L0EF6               ; Y < 60: wrong territory, deny
        BPL L0F06               ; Y >= 60: own territory, allow build

L0EEE:
        ; Eldoin (Player 0): Can only build on Y < 60
        CPX #$3C                ; Compare Y with territory boundary
        BMI L0F06               ; Y < 60: own territory, allow build
        RTS                     ; Y >= 60: wrong territory, deny
        .byte $4C, $06, $0F     ; (dead code: JMP L0F06)

; -----------------------------------------------------------------------------
; L0EF6 - Phase 0/1 Action Dispatcher
; -----------------------------------------------------------------------------
; Phase 0 (Bewegungsphase): Call sub_12B1 for unit selection/movement
; Phase 1 (Angriffsphase): Call sub_12EE for combat initiation
; -----------------------------------------------------------------------------
L0EF6:
        LDA $034A               ; GAME_STATE (game phase)
        BNE L0EFE               ; Skip if not Phase 0
        JSR sub_12B1            ; Phase 0: Unit selection/movement

L0EFE:
        CMP #$01                ; Is it Phase 1 (Angriffsphase)?
        BNE L0F05
        JSR sub_12EE            ; Phase 1: Combat initiation

L0F05:
        RTS

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
        JSR sub_0F8C            ; Check if cursor is on a town
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
        LDX $034C               ; CURSOR_MAP_X
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
        .byte $05, $11, $1D, $0E, $2A, $2F, $34, $19, $05, $0B, $46, $45, $4B, $06, $05, $0A  ; ....*/4...fek...
        .byte $15, $15, $15, $15, $19, $23, $22, $07, $11, $22  ; .....#".."

L0F77:
        JSR sub_1FF6
        LDY #$05
        PLA
        STA ($F9),Y             ; TEMP_PTR2 (general ptr lo)
        JMP sub_1F82

sub_0F82:
        DEX
        TXA
        JSR sub_1AD3
        LDY $034B               ; CURSOR_MAP_Y (cursor Y on map)
        DEY
        RTS

sub_0F8C:
        LDX #$0C

L0F8E:
        LDA $034B               ; CURSOR_MAP_Y (cursor Y on map)
        CMP $0F5D,X
        BNE L0F9E
        LDA $034C               ; CURSOR_MAP_X (cursor X on map)
        CMP $0F6A,X
        BEQ L0FA1

L0F9E:
        DEX
        BPL L0F8E

L0FA1:
        BMI L0FA9
        LDA $4FF2,X             ; TOWN_FLAGS (town capture flags)
        BMI L0FA9
        RTS

L0FA9:
        PLA
        PLA
        RTS
