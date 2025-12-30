; =============================================================================
; Sound Effects - Part 1
; Address range: $2013 - $20B6
; =============================================================================
; Basic sound initialization and common sound effects:
; - Voice initialization
; - UI feedback sounds
; - Combat/movement sounds
; =============================================================================

; -----------------------------------------------------------------------------
; sub_2013 - Swoosh/Wind Sound Effect
; -----------------------------------------------------------------------------
; Creates a sweeping filter effect across all three SID voices
; -----------------------------------------------------------------------------
sub_2013:
        LDA #$2F
        STA SID_VOLUME
        LDA #$07
        STA SID_RESFLT
        LDA #$8C
        STA SID_FCUTH
        LDA #$65
        JSR sub_20E7
        LDA #$57
        JSR sub_20F1
        LDA #$C8
        STA SID_V1FREQH
        LSR A
        STA SID_V2FREQH
        LSR A
        STA SID_V3FREQH
        JSR sub_1CEE
        LDY #$00

L203E:
        JSR $EEB3
        STY SID_FCUTH
        INY
        CPY #$C8
        BNE L203E
        JMP sub_1CE2

; -----------------------------------------------------------------------------
; sub_204C - Deep Rumble Sound Effect
; -----------------------------------------------------------------------------
sub_204C:
        LDA #$CF
        JSR sub_20E7
        LDA #$FB
        JSR sub_20F1
        LDA #$96
        STA SID_V1FREQH
        LSR A
        STA SID_V2FREQH
        LSR A
        STA SID_V3FREQH
        LDA #$64
        STA SID_FCUTH
        LDA #$2F
        STA SID_VOLUME
        LDA #$F7
        STA SID_RESFLT
        JMP sub_1CEE

; -----------------------------------------------------------------------------
; sub_2075 - Initialize Sound Voices
; -----------------------------------------------------------------------------
; Sets up all three SID voices with common parameters
; -----------------------------------------------------------------------------
sub_2075:
        LDA #$1F
        STA SID_VOLUME
        LDY #$04
        STY SID_V1FREQH
        INY
        STY SID_V2FREQH
        INY
        STY SID_V3FREQH
        LDA #$5A
        JSR sub_20E7
        LDA #$FC
        JSR sub_20F1
        LDA #$82
        STA SID_FCUTH
        LDA #$F7
        STA SID_RESFLT
        RTS

; -----------------------------------------------------------------------------
; sub_209C - UI Click/Beep Sound
; -----------------------------------------------------------------------------
sub_209C:
        JSR sub_2075
        LDA #$21
        JMP sub_1CE4

; -----------------------------------------------------------------------------
; sub_20A4 - Short Confirmation Sound
; -----------------------------------------------------------------------------
sub_20A4:
        JSR sub_2075
        LDA #$0F
        JSR sub_20E7
        LDA #$52

loc_20AE:
        JSR sub_20F1
        JSR sub_1CEE
        JMP sub_1CE2
