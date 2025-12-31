; =============================================================================
; Sound Initialization and Sprite Handling
; Address range: $0E14 - $0F05
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
;   - Phase 2 (Torphase): Territory check, then L0F06 (see $0F06-$0FAB_torphase.asm)
; -----------------------------------------------------------------------------
sub_0ECF:
        JSR sub_1F1C            ; Get terrain/unit index at cursor
        CMP #$04                ; Index 4 = Sumpf (char $6D)?
        BNE L0ED9               ; No, continue to phase dispatch
        JMP loc_1EA8            ; Yes, end turn/phase (skip mechanism?)

; -----------------------------------------------------------------------------
; L0ED9 - Phase 2 (Torphase) Territory Validation
; -----------------------------------------------------------------------------
; Validates player is in their own territory before allowing fortification.
; Territory boundary: Y = $3C (60)
;   - Eldoin (Player 0): Can build on Y < 60 (northern half)
;   - Dailor (Player 1): Can build on Y >= 60 (southern half)
; If valid, jumps to L0F06 (see $0F06-$0FAB_torphase.asm for build logic).
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
        BPL L0F06               ; Y >= 60: own territory, jump to torphase

L0EEE:
        ; Eldoin (Player 0): Can only build on Y < 60
        CPX #$3C                ; Compare Y with territory boundary
        BMI L0F06               ; Y < 60: own territory, jump to torphase
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
