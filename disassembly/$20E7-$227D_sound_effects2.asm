; =============================================================================
; Sound Effects - Part 2
; Address range: $20E7 - $227D
; =============================================================================
; SID voice helpers and additional sound effects:
; - ADSR envelope helpers
; - Combat sounds
; - Notification sounds
; =============================================================================

; -----------------------------------------------------------------------------
; sub_20E7 - Set Attack/Decay for All Voices
; -----------------------------------------------------------------------------
; Sets the same Attack/Decay value for all three SID voices.
; Input: A = Attack/Decay value (high nibble=attack, low nibble=decay)
; -----------------------------------------------------------------------------
sub_20E7:
        STA SID_V1AD
        STA SID_V2AD
        STA SID_V3AD
        RTS

; -----------------------------------------------------------------------------
; sub_20F1 - Set Sustain/Release for All Voices
; -----------------------------------------------------------------------------
; Sets the same Sustain/Release value for all three SID voices.
; Input: A = Sustain/Release value (high nibble=sustain, low nibble=release)
; -----------------------------------------------------------------------------
sub_20F1:
        STA SID_V1SR
        STA SID_V2SR
        STA SID_V3SR
        RTS

; -----------------------------------------------------------------------------
; sub_20FB - Combat Hit Sound
; -----------------------------------------------------------------------------
; Creates a descending filter sweep for impact effect.
; Used when units take damage in combat.
; -----------------------------------------------------------------------------
sub_20FB:
        JSR sub_209C
        LDA #$2F
        STA SID_VOLUME
        LDA #$CF
        JSR sub_20E7
        LDA #$FC
        JSR sub_20F1
        LDA #$23
        JSR sub_1CE4
        LDX #$0A

L2114:
        LDY #$6E
        JSR sub_1CF3
        TXA
        ASL A
        ASL A
        ASL A
        ASL A
        STA SID_FCUTH
        DEX
        BNE L2114
        LDA #$21
        JMP sub_1CE4

; -----------------------------------------------------------------------------
; sub_2129 - Random Noise Sound
; -----------------------------------------------------------------------------
; Uses ROM value at $A000 for randomized pitch.
; Creates varied sound effects.
; -----------------------------------------------------------------------------
sub_2129:
        JSR sub_2075
        LDA #$05
        JSR sub_20E7
        LDA #$69
        JSR sub_20F1
        LDA #$15
        JSR sub_1CE4
        LDA #$2F
        STA SID_VOLUME
        LDA $A000               ; Read ROM for pseudo-random value
        AND #$3F
        INC $2141               ; Self-modifying: increment instruction operand
        STA SID_V1FREQH
        LDA #$C8
        STA SID_V2FREQH
        LDA #$B4
        STA SID_V3FREQH
        LDA #$14
        JSR sub_1CE4
        RTS

; -----------------------------------------------------------------------------
; Unreferenced Code/Data
; -----------------------------------------------------------------------------
; This appears to be dead code or data - possibly unused sound routines
; -----------------------------------------------------------------------------
        .byte $20, $75, $20, $A9, $7C, $20, $E7, $20, $8D, $01, $D4, $A9, $55, $20, $F1, $20  ;  u .| . ..T.u .
        .byte $20, $EE, $1C, $A2, $04, $20, $81, $15, $A9, $82, $4C, $E4, $1C  ;  .... ....l..

; -----------------------------------------------------------------------------
; loc_2178 - Low Tone Sound Effect
; -----------------------------------------------------------------------------
loc_2178:
        JSR sub_1CEE
        JSR sub_2075
        LDA #$0A
        JSR sub_20E7
        LDA #$57
        JSR sub_20F1
        LDA #$32
        STA SID_FCUTH
        LDY #$50
        JSR sub_1CF3
        LDA #$14
        JMP sub_1CE4

; -----------------------------------------------------------------------------
; sub_2197 - High Pitch Sound
; -----------------------------------------------------------------------------
sub_2197:
        JSR sub_209C
        LDA #$A0
        STA SID_V3FREQH
        LDA #$FA
        JMP loc_20AE

; -----------------------------------------------------------------------------
; More Unreferenced Sound Data/Routines
; -----------------------------------------------------------------------------
        .byte $20, $75, $20, $A9, $1F, $8D, $18, $D4, $A9, $F7, $8D, $17, $D4, $A9, $C8, $8D  ;  u ....T....T.H.
        .byte $01, $D4, $8D, $08, $D4, $8D, $0F, $D4, $A9, $77, $20, $E7, $20, $A9, $79, $20  ; .T..T..T.w . .y
        .byte $F1, $20, $20, $EE, $1C, $A0, $00, $20, $F3, $1C, $4C, $E2, $1C, $20, $75, $20  ; .  .... ..l.. u
        .byte $A9, $77, $20, $F1, $20, $A9, $2F, $8D, $18, $D4, $20, $EE, $1C, $A2, $FF, $8A  ; .w . ./..T .....
        .byte $4A, $6A, $6A, $8D, $01, $D4, $8D, $08, $D4, $8D, $0F, $D4, $A0, $01, $20, $F3  ; jjj..T..T..T.. .
        .byte $1C, $CA, $E0, $64, $D0, $E9, $4C, $E2, $1C, $20, $75, $20, $A2, $0F, $20, $A4  ; .J.dP.l.. u .. .
        .byte $20, $8A, $4A, $6A, $6A, $6A, $6A, $A8, $20, $F3, $1C, $CA, $D0, $F0, $4C, $E2  ;  .jjjjj. ..JP.l.
        .byte $1C, $20, $75, $20, $20, $EE, $1C, $A2, $00, $8E, $01, $D4, $8E, $08, $D4, $8E  ; . u  ......T..T.
        .byte $0F, $D4, $A0, $01, $20, $F3, $1C, $E8, $D0, $EF, $4C, $E2, $1C, $20, $75, $20  ; .T.. ...P.l.. u
        .byte $A9, $00, $20, $E4, $1C, $A0, $21, $8C, $12, $D4, $A9, $F9, $20, $F1, $20, $A2  ; .. ...!..T.. . .
        .byte $02, $8E, $0F, $D4, $8E, $0E, $D4, $A0, $01, $20, $F3, $1C, $E8, $D0, $F5, $8E  ; ...T..T.. ...P..
        .byte $0E, $D4, $A0, $01, $20, $F3, $1C, $CA, $D0, $F5, $A9, $20, $4C, $E4, $1C  ; .T.. ..JP.. l..

; -----------------------------------------------------------------------------
; sub_2263 - Noise Burst Sound
; -----------------------------------------------------------------------------
sub_2263:
        JSR sub_2075
        LDA #$1F
        STA SID_FCUTH
        STA SID_VOLUME
        LDA #$FF
        JSR sub_20F1
        JSR sub_1CEE
        LDY #$00
        JSR sub_1CF3
        JMP sub_1CE2
