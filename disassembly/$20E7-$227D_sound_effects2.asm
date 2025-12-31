; =============================================================================
; Sound Effects - Part 2
; Address range: $20E7 - $227D
; =============================================================================
;
; SOUND EFFECT USAGE IN GAME:
;   sub_20E7: Helper - Set Attack/Decay for all voices
;   sub_20F1: Helper - Set Sustain/Release for all voices
;   sub_20FB: Combat hit impact sound (damage taken)
;   sub_2129: Varied pitch - uses ROM reading for pseudo-random pitch
;   loc_2178: Low tone notification
;   sub_2197: High pitch beep - unit destroyed notification
;   sub_2263: Noise burst
;
; =============================================================================

; -----------------------------------------------------------------------------
; sub_20E7 - Set Attack/Decay for All Voices
; -----------------------------------------------------------------------------
; Convenience routine to set ADSR Attack/Decay on all three SID voices.
;
; Input: A = Attack/Decay value
;   High nibble (bits 7-4) = Attack time (0=2ms, F=8s)
;   Low nibble (bits 3-0)  = Decay time (0=6ms, F=2.4s)
;
; Example values:
;   $8F = 100ms attack, 2.4s decay (slow swell)
;   $0F = 2ms attack, 2.4s decay (sharp hit with long fade)
;   $55 = 16ms attack, 188ms decay (medium)
; -----------------------------------------------------------------------------
sub_20E7:
        STA SID_V1AD            ; Voice 1 Attack/Decay
        STA SID_V2AD            ; Voice 2 Attack/Decay
        STA SID_V3AD            ; Voice 3 Attack/Decay
        RTS

; -----------------------------------------------------------------------------
; sub_20F1 - Set Sustain/Release for All Voices
; -----------------------------------------------------------------------------
; Convenience routine to set ADSR Sustain/Release on all three SID voices.
;
; Input: A = Sustain/Release value
;   High nibble (bits 7-4) = Sustain level (0=off, F=max volume)
;   Low nibble (bits 3-0)  = Release time (0=6ms, F=2.4s)
;
; Example values:
;   $F7 = Max sustain, 300ms release (full sound, quick fade)
;   $FC = Max sustain, 1s release (sustained with slow fade)
;   $00 = No sustain, instant release (very short pluck)
; -----------------------------------------------------------------------------
sub_20F1:
        STA SID_V1SR            ; Voice 1 Sustain/Release
        STA SID_V2SR            ; Voice 2 Sustain/Release
        STA SID_V3SR            ; Voice 3 Sustain/Release
        RTS

; -----------------------------------------------------------------------------
; sub_20FB - Combat Hit Sound (Damage Impact)
; -----------------------------------------------------------------------------
; Creates a descending filter sweep for impact effect.
; Called when a unit takes damage in combat.
;
; Technique: Sweeps filter cutoff from $A0 down to $10 in 10 steps,
; creating a "thump" that fades from bright to muffled.
;
; SID Configuration:
;   Volume: $2F (max + bandpass)
;   ADSR: Attack=$C (1s), Decay=$F (2.4s), Sustain=$F, Release=$C (1s)
;   Filter: Sweeps downward through 10 steps (X*16 = $A0 to $10)
; -----------------------------------------------------------------------------
sub_20FB:
        JSR sub_209C            ; Initialize SID (click sound)
        LDA #$2F                ; Volume=$F, filter mode=$2 (bandpass)
        STA SID_VOLUME
        LDA #$CF                ; Attack=$C (1s), Decay=$F (2.4s)
        JSR sub_20E7
        LDA #$FC                ; Sustain=$F, Release=$C (1s)
        JSR sub_20F1
        LDA #$23                ; Initial delay
        JSR sub_1CE4
        LDX #$0A                ; 10 filter sweep steps

L2114:
        LDY #$6E                ; Delay between steps
        JSR sub_1CF3
        TXA                     ; X = 10, 9, 8, ... 1
        ASL A                   ; X * 2
        ASL A                   ; X * 4
        ASL A                   ; X * 8
        ASL A                   ; X * 16 (= $A0, $90, $80, ... $10)
        STA SID_FCUTH           ; Descending filter cutoff
        DEX
        BNE L2114               ; Loop until X = 0
        LDA #$21                ; Final delay
        JMP sub_1CE4

; -----------------------------------------------------------------------------
; sub_2129 - Varied Pitch Sound Effect (Self-Modifying Code)
; -----------------------------------------------------------------------------
; Creates varied sound effects by reading from BASIC ROM ($A000+).
; Uses self-modifying code to cycle through ROM addresses, producing
; a deterministic but varied sequence of pitch values.
; Input: None
; Output: Plays sound with frequency based on ROM byte
; -----------------------------------------------------------------------------
sub_2129:
        JSR sub_2075            ; Initialize SID
        LDA #$05
        JSR sub_20E7            ; Set Attack/Decay
        LDA #$69
        JSR sub_20F1            ; Set Sustain/Release
        LDA #$15
        JSR sub_1CE4            ; Short delay
        LDA #$2F
        STA SID_VOLUME          ; Set volume
        LDA $A000               ; Read byte from BASIC ROM (address modified below)
        AND #$3F                ; Mask to 0-63 for frequency range
        INC $2141               ; Self-modify: increment address low byte ($A000→$A001→...)
        STA SID_V1FREQH         ; Set voice 1 frequency high byte
        LDA #$C8
        STA SID_V2FREQH         ; Set voice 2 frequency
        LDA #$B4
        STA SID_V3FREQH         ; Set voice 3 frequency
        LDA #$14
        JSR sub_1CE4            ; Delay for sound duration
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
; Plays a high-pitched beep using voice 3.
; Shares tail code (loc_20AE) with sub_20A4 to save bytes.
; Flow: sub_209C -> set high freq -> loc_20AE (sustain/release + trigger)
; -----------------------------------------------------------------------------
sub_2197:
        JSR sub_209C            ; Initialize SID voices + short click delay
        LDA #$A0                ; High frequency value (160 decimal)
        STA SID_V3FREQH         ; Set voice 3 frequency high byte -> high pitch
        LDA #$FA                ; Sustain/Release: $F=max sustain, $A=fast release
        JMP loc_20AE            ; -> sub_20F1 (set S/R) -> sub_1CEE (trigger) -> sub_1CE2 (cleanup)

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
