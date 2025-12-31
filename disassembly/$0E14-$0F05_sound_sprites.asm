; =============================================================================
; Sound Initialization and Sprite Handling
; Address range: $0E14 - $0F05
; =============================================================================
;
; This module handles:
; 1. SID chip initialization for background ambient sound
; 2. IRQ setup for raster-based effects
; 3. Fire button action dispatch based on game phase
;
; SID REGISTER REFERENCE (addresses $D400-$D418):
;   $D400-$D406: Voice 1 (Freq Lo/Hi, Pulse Lo/Hi, Control, AD, SR)
;   $D407-$D40D: Voice 2
;   $D40E-$D414: Voice 3
;   $D415-$D416: Filter Cutoff (Lo/Hi)
;   $D417: Resonance + Filter Enable
;   $D418: Volume + Filter Mode
;
; =============================================================================

; -----------------------------------------------------------------------------
; sub_0E14 - Initialize SID for Ambient Background Sound
; -----------------------------------------------------------------------------
; Called during game initialization to set up continuous ambient audio.
; Creates a low rumbling/wind sound using filtered noise.
;
; Configuration:
;   Volume: $4F (max volume + low-pass filter mode)
;   Filter: Resonance=$F (max), voices 1+2 through filter
;   Voices 1&2: Noise waveform ($81), slow attack ($8F), quick release ($F1)
;   Voice 3: Triangle wave, different ADSR for variation
;   Filter cutoff: $C8 (moderately high)
; -----------------------------------------------------------------------------
sub_0E14:
        LDA #$4F                ; Volume=$F (max), Filter mode=$4 (bandpass)
        STA SID_VOLUME
        LDA #$F3                ; Resonance=$F (max), Filter voices 1+2
        STA SID_RESFLT
        LDX #$01
        STX $0343               ; Initialize ambient sound state flag
        DEX
        STX $0344               ; Clear secondary state flag
        LDA #$8F                ; Attack=$8 (100ms), Decay=$F (2.4s)
        JSR sub_20E7            ; Set AD for all voices
        LDA #$04                ; Voice 3: Attack=$0 (2ms), Decay=$4 (114ms)
        STA SID_V3AD
        LDA #$F1                ; Sustain=$F (max), Release=$1 (24ms)
        JSR sub_20F1            ; Set SR for all voices
        LDA #$F7                ; Voice 3: Sustain=$F, Release=$7 (300ms)
        STA SID_V3SR
        LDA #$81                ; Waveform: Noise ($80) + Gate on ($01)
        STA SID_V1CTRL          ; Voice 1: noise generator
        STA SID_V2CTRL          ; Voice 2: noise generator
        STA SID_V1FREQH         ; Voice 1 freq hi = $81 (low pitch)
        LDA #$01
        STA SID_V2FREQL         ; Voice 2 freq lo = $01 (very low pitch)
        LDA #$64                ; Voice 3 freq hi = $64 (medium pitch)
        STA SID_V3FREQH
        LDA #$C8                ; Filter cutoff = $C8 (mid-high)
        STA SID_FCUTH
        RTS

; -----------------------------------------------------------------------------
; sub_0E56 - Setup Raster IRQ for Visual Effects
; -----------------------------------------------------------------------------
; Configures a raster interrupt for screen split effects.
; The IRQ handler (at $0E7A) manages border color cycling and
; game state updates synchronized to the display.
; -----------------------------------------------------------------------------
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

; -----------------------------------------------------------------------------
; IRQ Handler at $0E7A (raw bytes - disassembly provided in comments)
; -----------------------------------------------------------------------------
; This is the raster IRQ handler set up by sub_0E56.
; It manages screen split timing for border color changes.
;
; Disassembly:
; $0E7A: LDA $D019      ; Acknowledge VIC IRQ
;        STA $D019
;        BMI $0EAA      ; Branch if raster IRQ flag set (bit 7)
;        DEC $0348      ; Decrement IRQ counter
;        BNE $0EA6      ; If not zero, skip update
;        CLD            ; Clear decimal mode
;        LDX #$06       ; Loop counter for color table
; $0E86: JSR $1B22      ; Call color update routine
;        LDY $E35F      ; Load from color table index
;        LDA $E358,X    ; Load color value from table
;        ASL A          ; Shift for color lookup
;        ADC #$00       ; Add carry
;        STA $E359,X    ; Store back to color table
;        DEX            ; Next color
;        BPL $0E86      ; Loop while X >= 0
;        JSR $1B28      ; Finalize color update
;        TYA            ; Transfer Y to A
;        ASL A          ; Shift
;        ADC #$00       ; Add carry
;        STA $E358      ; Store master color
;        LDA #$07       ; Reset IRQ counter
;        STA $0348
;        JMP $EA7E      ; Return from IRQ (KERNAL)
; $0EA6: LDA $D012      ; Check raster position
;        CMP #$DC       ; Compare to threshold (220)
;        BCS $0EB7      ; If >= 220, branch to bottom handler
;        LDA #$05       ; Set border color (green)
;        STA $D021      ; Store to border color register
;        LDA #$DC       ; Next raster compare value
;        STA $D012      ; Set raster compare
;        JMP $FEBC      ; Return from IRQ (KERNAL)
; $0EB7: LDA #$06       ; Set border color (blue)
;        STA $D021
;        LDA #$00       ; Next raster at top of screen
;        STA $D012
;        JMP $FEBC      ; Return from IRQ
; -----------------------------------------------------------------------------
        .byte $AD, $19, $D0, $8D, $19, $D0, $30, $2C, $CE, $48, $03, $D0, $24, $D8, $A2, $06
        .byte $20, $22, $1B, $AC, $5F, $E3, $BD, $58, $E3, $0A, $69, $00, $9D, $59, $E3, $CA
        .byte $10, $F4, $20, $28, $1B, $98, $0A, $69, $00, $8D, $58, $E3, $A9, $07, $8D, $48
        .byte $03, $4C, $7E, $EA, $AD, $12, $D0, $C9, $DC, $B0, $0D, $A9, $05, $8D, $21, $D0
        .byte $A9, $DC, $8D, $12, $D0, $4C, $BC, $FE, $A9, $06, $8D, $21, $D0, $A9, $00, $8D
        .byte $12, $D0, $4C, $BC, $FE

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
        CMP #$04                ; Index 4 = Ende (End Marker, char $6D)?
        BNE L0ED9               ; No, continue to phase dispatch
        JMP loc_1EA8            ; Yes, end turn/phase

; -----------------------------------------------------------------------------
; L0ED9 - Phase 2 (Torphase) Territory Validation
; -----------------------------------------------------------------------------
; Validates player is in their own territory before allowing fortification.
; Territory boundary: X = $3C (60)
;   - Eldoin (Player 0): Can build on X < 60 (western half)
;   - Dailor (Player 1): Can build on X >= 60 (eastern half)
; If valid, jumps to L0F06 (see $0F06-$0FAB_torphase.asm for build logic).
; -----------------------------------------------------------------------------
L0ED9:
        LDA $034A               ; GAME_STATE (game phase)
        CMP #$02                ; Is it Phase 2 (Torphase)?
        BNE L0EF6               ; No, check other phases
        LDX $034B               ; CURSOR_MAP_X (cursor X on map)
        LDA $0347               ; CURRENT_PLAYER (active player)
        BEQ L0EEE               ; Branch if Eldoin (Player 0)
        ; Dailor (Player 1): Can only build on X >= 60
        CPX #$3C                ; Compare X with territory boundary
        BMI L0EF6               ; X < 60: wrong territory, deny
        BPL L0F06               ; X >= 60: own territory, jump to torphase

L0EEE:
        ; Eldoin (Player 0): Can only build on X < 60
        CPX #$3C                ; Compare X with territory boundary
        BMI L0F06               ; X < 60: own territory, jump to torphase
        RTS                     ; X >= 60: wrong territory, deny
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
