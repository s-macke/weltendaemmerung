; =============================================================================
; Sound Effects - Part 1
; Address range: $2013 - $20B6
; =============================================================================
;
; SOUND EFFECT USAGE IN GAME:
;   sub_2013: Water/Sea movement - swooshing wave sound
;   sub_204C: Deep rumble - used for heavy impacts
;   sub_2075: Common init routine for other effects
;   sub_209C: UI click - called before other sounds as setup
;   sub_20A4: Short confirmation beep
;
; SID ADSR ENVELOPE TIMING (approximate):
;   Attack:  0=2ms, 8=100ms, F=8s
;   Decay:   0=6ms, 4=114ms, F=2.4s
;   Sustain: 0=off, F=max volume
;   Release: 0=6ms, 7=300ms, F=2.4s
;
; =============================================================================

; -----------------------------------------------------------------------------
; sub_2013 - Swoosh/Wind Sound Effect (Water Movement)
; -----------------------------------------------------------------------------
; Creates a sweeping filter effect simulating waves or wind.
; Called when unit enters water terrain without moving (see $0885-$0A6F).
;
; Technique: Ramps filter cutoff from $00 to $C8 over time while
; all three voices play at different octaves (cascade effect).
;
; SID Configuration:
;   Volume: $2F (max + low-pass filter)
;   Filter: Resonance=$0 (none), All voices filtered ($07)
;   ADSR: Attack=$6 (32ms), Decay=$5 (188ms), Sustain=$5, Release=$7 (300ms)
;   Frequencies: V1=$C8, V2=$64, V3=$32 (octave cascade)
; -----------------------------------------------------------------------------
sub_2013:
        LDA #$2F                ; Volume=$F (max), filter mode=$2 (bandpass)
        STA SID_VOLUME
        LDA #$07                ; Resonance=$0, filter all 3 voices
        STA SID_RESFLT
        LDA #$8C                ; Initial filter cutoff (high)
        STA SID_FCUTH
        LDA #$65                ; Attack=$6 (32ms), Decay=$5 (188ms)
        JSR sub_20E7            ; Set AD for all voices
        LDA #$57                ; Sustain=$5, Release=$7 (300ms)
        JSR sub_20F1            ; Set SR for all voices
        LDA #$C8                ; Voice 1 freq hi = $C8 (highest)
        STA SID_V1FREQH
        LSR A                   ; $C8 -> $64
        STA SID_V2FREQH         ; Voice 2 = one octave lower
        LSR A                   ; $64 -> $32
        STA SID_V3FREQH         ; Voice 3 = two octaves lower
        JSR sub_1CEE            ; Gate on all voices
        LDY #$00                ; Start filter sweep at 0

L203E:
        JSR $EEB3               ; KERNAL delay (scan keyboard)
        STY SID_FCUTH           ; Sweep filter cutoff upward
        INY
        CPY #$C8                ; Sweep until $C8
        BNE L203E
        JMP sub_1CE2            ; Gate off, cleanup

; -----------------------------------------------------------------------------
; sub_204C - Deep Rumble Sound Effect
; -----------------------------------------------------------------------------
; Creates a low-frequency rumble for heavy impacts or earthquakes.
;
; SID Configuration:
;   ADSR: Attack=$C (1s), Decay=$F (2.4s), Sustain=$F, Release=$B (1.5s)
;   Frequencies: V1=$96, V2=$4B, V3=$25 (low octave cascade)
;   Filter: High resonance ($F7), cutoff=$64 (low)
;   Volume: $2F (max + bandpass)
; -----------------------------------------------------------------------------
sub_204C:
        LDA #$CF                ; Attack=$C (1s), Decay=$F (2.4s)
        JSR sub_20E7
        LDA #$FB                ; Sustain=$F (max), Release=$B (1.5s)
        JSR sub_20F1
        LDA #$96                ; Voice 1 freq = $96 (low)
        STA SID_V1FREQH
        LSR A                   ; $96 -> $4B
        STA SID_V2FREQH         ; Voice 2 = one octave lower
        LSR A                   ; $4B -> $25
        STA SID_V3FREQH         ; Voice 3 = two octaves lower
        LDA #$64                ; Filter cutoff = $64 (low, muffled)
        STA SID_FCUTH
        LDA #$2F                ; Volume=$F, filter mode=$2 (bandpass)
        STA SID_VOLUME
        LDA #$F7                ; Resonance=$F (max), filter voices 1+2+3
        STA SID_RESFLT
        JMP sub_1CEE            ; Gate on all voices

; -----------------------------------------------------------------------------
; sub_2075 - Initialize Sound Voices (Common Setup)
; -----------------------------------------------------------------------------
; Standard initialization for most sound effects.
; Called by sub_209C, sub_20A4, sub_2129, sub_2197, etc.
;
; SID Configuration:
;   Volume: $1F (max + low-pass filter)
;   Frequencies: V1=$04, V2=$05, V3=$06 (low, close together for chorus)
;   ADSR: Attack=$5 (16ms), Decay=$A (750ms), Sustain=$F, Release=$C (1s)
;   Filter: Cutoff=$82 (mid), Resonance=$F (max)
; -----------------------------------------------------------------------------
sub_2075:
        LDA #$1F                ; Volume=$F (max), filter mode=$1 (low-pass)
        STA SID_VOLUME
        LDY #$04
        STY SID_V1FREQH         ; Voice 1 freq hi = $04
        INY
        STY SID_V2FREQH         ; Voice 2 freq hi = $05
        INY
        STY SID_V3FREQH         ; Voice 3 freq hi = $06
        LDA #$5A                ; Attack=$5 (16ms), Decay=$A (750ms)
        JSR sub_20E7
        LDA #$FC                ; Sustain=$F (max), Release=$C (1s)
        JSR sub_20F1
        LDA #$82                ; Filter cutoff = $82 (mid)
        STA SID_FCUTH
        LDA #$F7                ; Resonance=$F, filter all 3 voices
        STA SID_RESFLT
        RTS

; -----------------------------------------------------------------------------
; sub_209C - UI Click/Beep Sound
; -----------------------------------------------------------------------------
; Initializes SID chip and plays a short click sound.
; Used for UI feedback and as setup for other sound effects (e.g., sub_2197).
; -----------------------------------------------------------------------------
sub_209C:
        JSR sub_2075            ; Initialize all 3 SID voices (vol=$1F, freq=$04/$05/$06, ADSR=$5A/$FC, filter=$82/$F7)
        LDA #$21                ; Delay parameter ($21 = 33 cycles)
        JMP sub_1CE4            ; Execute short delay and return

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
