; =============================================================================
; Sound Effects and Utility Functions
; Address range: $1E8B - $2306
; =============================================================================

sub_1E8B:
        LDA $1D54,X
        CMP #$5C
        BEQ L1E99
        JSR CHROUT
        INX
        JMP sub_1E8B

L1E99:
        RTS

sub_1E9A:
        LDA $1DBE,X
        CMP #$5C
        BEQ L1E99
        JSR CHROUT
        INX
        JMP sub_1E9A

loc_1EA8:
        LDA $034A
        ASL A
        CLC
        ADC $0347
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
        STA $0347
        TXA
        LSR A
        STA $034A
        JSR sub_1F69
        JSR sub_1C35
        JMP sub_1D0E

sub_1EE2:
        JSR sub_1F1C
        PHA
        CMP #$0B
        BCS L1F14
        PHA
        LDX #$18
        JSR $E9FF
        PLA

loc_1EF1:
        TAX
        LDA $1D39,X
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

sub_1F1C:
        LDA VIC_SP0Y
        SEC
        SBC #$30
        LSR A
        LSR A
        LSR A
        STA $A7
        LDA VIC_SP0X
        STA $A8
        LDA VIC_SPXMSB
        AND #$01
        STA $A9
        LDA $A8
        SEC
        SBC #$16
        STA $A8
        LDA $A9
        SBC #$00
        STA $A9
        LSR $A9
        ROR $A8
        LSR $A8
        LSR $A8
        LDA $A7
        CLC
        ADC $0341
        STA $034C
        LDA $A8
        ADC $0340
        STA $034B
        JSR sub_1F77
        LDA ($D1),Y
        SEC
        SBC #$69
        BCS L1F65
        LDA #$09

L1F65:
        STA $034F
        RTS

sub_1F69:
        JSR sub_209C
        LDA #$14
        JSR sub_1CE4
        LDA #$14
        JSR sub_1CE4
        RTS

sub_1F77:
        LDX $A7
        JSR $E9F0
        JSR $EA24
        LDY $A8
        RTS

sub_1F82:
        JSR sub_2263
        JMP loc_2178

sub_1F88:
        JSR CHROUT
        LDA #$3D
        JMP CHROUT

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

sub_1FAB:
        JSR sub_1F1C
        SEC
        SBC #$0B
        STA $0346
        LDX #$18
        JSR $E9FF
        LDY #$0A
        JSR $E50C
        LDA #$52
        JSR sub_1F88
        LDX $0346
        LDA $1027,X
        JSR sub_1F90
        LDA #$42
        JSR sub_1F88
        JSR sub_1FF6
        LDY #$02
        LDA ($F9),Y
        PHA
        INY
        LDA ($F9),Y
        JSR sub_1F90
        LDA #$41
        JSR sub_1F88
        LDX $0346
        LDA $1047,X
        JSR sub_1F90
        LDA #$56
        JSR sub_1F88
        PLA
        JMP sub_1F90

sub_1FF6:
        JSR sub_15C2

loc_1FF9:
        LDA ($F9),Y
        TAX
        INX
        CPX $034B
        BNE L200C
        INY
        LDA ($F9),Y
        TAX
        INX
        CPX $034C
        BEQ L2012

L200C:
        JSR sub_20B7
        JMP loc_1FF9

L2012:
        RTS

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

sub_209C:
        JSR sub_2075
        LDA #$21
        JMP sub_1CE4

sub_20A4:
        JSR sub_2075
        LDA #$0F
        JSR sub_20E7
        LDA #$52

loc_20AE:
        JSR sub_20F1
        JSR sub_1CEE
        JMP sub_1CE2

sub_20B7:
        LDY #$06

L20B9:
        JSR sub_177A
        DEY
        BNE L20B9
        RTS

sub_20C0:
        JSR sub_15C2

loc_20C3:
        LDY #$04
        LDA ($F9),Y
        BEQ L20D2
        DEY
        STA ($F9),Y
        JSR sub_20B7
        JMP loc_20C3

L20D2:
        RTS

sub_20D3:
        JSR sub_15C2

loc_20D6:
        LDY #$04
        LDA ($F9),Y
        BEQ L20D2
        LDA #$01
        DEY
        STA ($F9),Y
        JSR sub_20B7
        JMP loc_20D6

sub_20E7:
        STA SID_V1AD
        STA SID_V2AD
        STA SID_V3AD
        RTS

sub_20F1:
        STA SID_V1SR
        STA SID_V2SR
        STA SID_V3SR
        RTS

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
        LDA $A000
        AND #$3F
        INC $2141
        STA SID_V1FREQH
        LDA #$C8
        STA SID_V2FREQH
        LDA #$B4
        STA SID_V3FREQH
        LDA #$14
        JSR sub_1CE4
        RTS
        .byte $20, $75, $20, $A9, $7C, $20, $E7, $20, $8D, $01, $D4, $A9, $55, $20, $F1, $20  ;  u .| . ..T.u .
        .byte $20, $EE, $1C, $A2, $04, $20, $81, $15, $A9, $82, $4C, $E4, $1C  ;  .... ....l..

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

sub_2197:
        JSR sub_209C
        LDA #$A0
        STA SID_V3FREQH
        LDA #$FA
        JMP loc_20AE
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

sub_227E:
        LDA $4FFF
        SED
        CLC
        ADC #$01
        STA $4FFF
        CLD
        PHA
        LDX #$16

L228C:
        JSR $E9FF
        INX
        CPX #$19
        BNE L228C
        LDX #$16
        LDY #$10
        JSR $E50C
        LDA $4FFF
        JSR sub_1F90
        LDX #$63
        JSR sub_1E8B
        PLA
        CMP #$15
        BNE L22B1
        STA $034F
        JMP loc_1456

L22B1:
        LDX #$17
        LDY #$10
        JSR $E50C
        LDX #$36
        JSR sub_1E8B
        LDX #$18
        LDY #$0E
        JSR $E50C
        LDX #$3D
        JSR sub_1E8B

L22C9:
        LDA #$3E
        STA $C3A4
        LDA #$01
        STA $DBA4
        LDA #$20
        STA $C3CC

loc_22D8:
        LDA CIA1_PRB
        TAX
        AND #$01
        BEQ L22C9
        TXA
        AND #$02
        BEQ L22ED
        TXA
        AND #$10
        BEQ L22FF
        JMP loc_22D8

L22ED:
        LDA #$3E
        STA $C3CC
        LDA #$01
        STA $DBCC
        LDA #$20
        STA $C3A4
        JMP loc_22D8

L22FF:
        LDA $C3A4
        CMP #$3E
        BNE loc_2307
        RTS
