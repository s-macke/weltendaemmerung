; =============================================================================
; Disassembly of C64 program
; Load address: $0801
; End address:  $23D7
; =============================================================================

        * = $0801

        .byte $0B, $08, $C6, $07, $9E, $32, $30, $36, $31, $00, $00, $00  ; ..F..2061...

loc_080D:
        LDA #$9F
        STA $4FF0
        LDA #$00
        LDX #$18

L0816:
        STA SID_V1FREQL,X
        STA $0340,X
        STA $0359,X
        STA $4FF2,X
        DEX
        BPL L0816
        JSR sub_1B22
        LDA #$00
        STA $F7
        STA $F9
        TAY
        LDA #$D0
        STA $F8
        LDA #$E0
        STA $FA

L0837:
        LDA ($F7),Y
        STA ($F9),Y
        INY
        BNE L0837
        INC $F8
        INC $FA
        LDA $FA
        BNE L0837
        JSR sub_1B28
        LDA #$ED
        STA $0341
        LDA #$C0
        STA $0288
        LDA #$94
        STA CIA2_PRA
        LDA #$08
        STA VIC_VMCSB
        JSR sub_15CD
        JSR sub_0BF3
        JSR sub_0E56
        LDA $035D
        CMP #$C4
        BEQ L0873
        JSR sub_1721
        JSR sub_0FAC

L0873:
        JSR sub_1C88
        JSR sub_15CD
        JSR sub_1CBC
        JSR sub_1C35
        JSR sub_1CE2
        JSR sub_1D0E

loc_0885:
        LDX #$32

L0887:
        JSR $EEB3
        DEX
        BNE L0887

loc_088D:
        LDA $0347
        EOR #$01
        AND #$01
        TAX
        LDA CIA1_PRA,X
        EOR #$1F
        AND #$1F
        STA $0354
        BNE L08AA
        STA $034D
        JSR sub_12C0
        JMP loc_088D

L08AA:
        CMP #$10
        BNE L08BC
        CMP $034D
        BEQ loc_0885
        STA $034D
        JSR sub_0ECF
        JMP loc_0885

L08BC:
        PHA
        JSR sub_09B4
        PLA
        ROR A
        BCS L08ED

loc_08C4:
        ROR A
        BCS L0911

loc_08C7:
        ROR A
        BCS L092E

loc_08CA:
        ROR A
        BCS L08E5

loc_08CD:
        JSR sub_09F2
        JSR sub_23C3
        JSR sub_1EE2
        LDA $0354
        AND #$10
        BNE L08E8
        LDA #$96

loc_08DF:
        STA $0886
        JMP loc_0885

L08E5:
        JMP loc_096F

L08E8:
        LDA #$14
        JMP loc_08DF

L08ED:
        PHA
        JSR sub_0AD5
        LDA VIC_SP0Y
        CMP #$38
        BEQ L0969
        SEC
        SBC #$08
        STA VIC_SP0Y

loc_08FE:
        JSR sub_0A70
        BEQ L0907

loc_0903:
        PLA
        JMP loc_08CD

L0907:
        PLA
        JMP loc_08C4

L090B:
        JSR sub_1BF0
        JMP loc_0922

L0911:
        PHA
        JSR sub_0AEB
        LDA VIC_SP0Y
        CMP #$C8
        BEQ L090B
        CLC
        ADC #$08
        STA VIC_SP0Y

loc_0922:
        JSR sub_0A70
        BEQ L092A
        JMP loc_0903

L092A:
        PLA
        JMP loc_08C7

L092E:
        PHA
        JSR sub_0AA3
        LDA VIC_SPXMSB
        AND #$01
        BNE L0949
        LDA VIC_SP0X
        CMP #$1E
        BEQ L09A8

L0940:
        SEC
        SBC #$08
        STA VIC_SP0X
        JMP loc_095D

L0949:
        LDA VIC_SP0X
        CMP #$07
        BNE L0940
        LDA VIC_SPXMSB
        AND #$FE
        STA VIC_SPXMSB
        LDA #$FE
        STA VIC_SP0X

loc_095D:
        JSR sub_0A70
        BEQ L0965
        JMP loc_0903

L0965:
        PLA
        JMP loc_08CA

L0969:
        JSR sub_1BDC
        JMP loc_08FE

loc_096F:
        PHA
        JSR sub_0ABB
        LDA VIC_SPXMSB
        BEQ L0991
        LDA VIC_SP0X
        CMP #$47
        BEQ L09AE

L097F:
        CLC
        ADC #$08
        STA VIC_SP0X

loc_0985:
        JSR sub_0A70
        BEQ L098D
        JMP loc_0903

L098D:
        PLA
        JMP loc_08CD

L0991:
        LDA VIC_SP0X
        CMP #$FE
        BNE L097F
        LDA VIC_SPXMSB
        ORA #$01
        STA VIC_SPXMSB
        LDA #$07
        STA VIC_SP0X
        JMP loc_0985

L09A8:
        JSR sub_1BBE
        JMP loc_095D

L09AE:
        JSR sub_1BCC
        JMP loc_0985

sub_09B4:
        JSR sub_0A70
        BEQ L09F1
        JSR sub_1FF6
        LDY #$03
        LDA ($F9),Y
        BNE L09C5
        JMP loc_12B6

L09C5:
        LDY #$05
        LDA ($F9),Y
        PHA
        LDA $F9
        STA $0350
        LDA $FA
        STA $0351
        JSR sub_1F1C
        JSR sub_1F77
        LDA ($D1),Y
        STA $0352
        PLA
        PHA
        STA ($D1),Y
        JSR sub_1C01
        STA ($F3),Y
        LDX $034C
        JSR sub_0F82
        PLA
        STA ($B4),Y

L09F1:
        RTS

sub_09F2:
        JSR sub_0A70
        BEQ L09F1
        JSR sub_1F1C
        JSR sub_1F77
        LDA ($D1),Y
        PHA
        LDA $0352
        STA ($D1),Y
        PHA
        JSR sub_1C01
        STA ($F3),Y
        LDX $034C
        JSR sub_0F82
        PLA
        STA ($B4),Y
        LDA $0350
        STA $F9
        LDA $0351
        STA $FA
        LDY #$00
        LDX $034B
        DEX
        TXA
        STA ($F9),Y
        INY
        LDX $034C
        DEX
        TXA
        STA ($F9),Y
        LDY #$05
        PLA
        STA ($F9),Y
        LDA $0352
        CMP #$76
        BEQ L0A5A
        CMP #$7D
        BEQ L0A5A
        CMP #$78
        BEQ L0A65
        CMP #$79
        BEQ L0A81
        CMP #$83
        BEQ L0A81
        CMP #$7A
        BEQ L0A96
        CMP #$7F
        BEQ L0A96
        CMP #$82
        BEQ L0A81
        JMP sub_1EE2

L0A5A:
        LDA $0353
        BNE L0A62
        JSR sub_2013

L0A62:
        JMP sub_1EE2

L0A65:
        LDA $0353
        BEQ L0A62
        JSR sub_1CE2
        JMP sub_1EE2

sub_0A70:
        LDA $034A
        CMP #$01
        BEQ L0A80
        CMP #$02
        BEQ L0A80
        LDA VIC_SP0COL
        CMP #$F1

L0A80:
        RTS

L0A81:
        LDA $0353
        BNE L0A62
        LDX #$03

L0A88:
        LDY #$5A
        JSR sub_1CF3
        JSR sub_20A4
        DEX
        BNE L0A88
        JMP sub_1EE2

L0A96:
        LDA $0353
        BEQ L0A62
        LDA #$20
        JSR sub_1CE4
        JMP sub_1EE2

sub_0AA3:
        JSR sub_0A70

L0AA6:
        BEQ L0A80
        LDX $034C
        JSR sub_0F82
        DEY
        BMI L0AB6
        JSR sub_0B10
        BCC L0B01

L0AB6:
        PLA
        PLA
        JMP loc_08FE

sub_0ABB:
        JSR sub_0A70
        BEQ L0A80
        LDX $034C
        JSR sub_0F82
        INY
        CPY #$50
        BEQ L0AB6
        JSR sub_0B10
        BCC L0B01
        PLA
        PLA
        JMP loc_0922

sub_0AD5:
        JSR sub_0A70
        BEQ L0A80
        LDX $034C
        DEX
        JSR sub_0F82
        JSR sub_0B10
        BCC L0B01
        PLA
        PLA
        JMP loc_095D

sub_0AEB:
        JSR sub_0A70
        BEQ L0AA6
        LDX $034C
        INX
        JSR sub_0F82
        JSR sub_0B10
        BCC L0B01
        PLA
        PLA
        JMP loc_0985

L0B01:
        JSR sub_1FF6
        LDY #$03
        LDA ($F9),Y
        SED
        JSR sub_0B82
        STA ($F9),Y
        CLD
        RTS

sub_0B10:
        LDA ($B4),Y
        LDX $034F
        CPX #$0D
        BEQ L0B6A
        CPX #$14
        BEQ L0B6A
        CPX #$0F
        BEQ L0B59
        CMP #$69
        BCC L0B52
        CMP #$73
        BEQ L0B52
        CMP #$72
        BEQ L0B52
        CMP #$6F
        BEQ L0B52
        CMP #$70
        BEQ L0B52
        CMP #$74
        BCS L0B52
        CPX #$11
        BEQ L0B78
        CPX #$16
        BEQ L0B78
        CPX #$10
        BEQ L0B71
        CPX #$1A
        BEQ L0B71
        CPX #$19
        BEQ L0B71
        JSR sub_20A4
        CLC
        RTS

L0B52:
        LDA #$01
        STA $0353
        SEC
        RTS

L0B59:
        STA $0353
        CMP #$6B
        BNE L0B52
        LDX #$00
        STX $0353
        JSR sub_204C
        CLC
        RTS

L0B6A:
        STA $0353
        CMP #$74
        BCS L0B52

L0B71:
        LDX #$00
        STX $0353
        CLC
        RTS

L0B78:
        LDX #$00
        STX $0353
        JSR sub_209C
        CLC
        RTS

sub_0B82:
        PHA
        LDY #$05
        LDA ($F9),Y
        TAY
        LDA $034F
        CLD
        SEC
        SBC #$0B
        SED
        TAX
        TYA
        LDY #$03
        CMP #$6B
        BEQ L0BA5
        CMP #$6C
        BEQ L0BAB
        CMP #$6E
        BEQ L0BB1
        PLA
        SEC
        SBC #$01
        RTS

L0BA5:
        LDA $0BC3,X
        JMP loc_0BB4

L0BAB:
        LDA $0BD3,X
        JMP loc_0BB4

L0BB1:
        LDA $0BE3,X

loc_0BB4:
        STA $0342
        PLA
        SEC
        SBC $0342
        CMP #$20
        BCC L0BC2
        LDA #$00

L0BC2:
        RTS
        .byte $04, $04, $01, $04, $01, $04, $04, $02, $04, $01, $02, $02, $04, $04, $05, $02  ; ................
        .byte $02, $02, $01, $03, $00, $04, $02, $02, $04, $01, $02, $02, $01, $03, $07, $02  ; ................
        .byte $03, $03, $01, $03, $00, $04, $03, $03, $04, $01, $03, $03, $01, $04, $07, $04  ; ................

sub_0BF3:
        JSR BASIC_CLRSCR
        LDA #$06
        STA VIC_EXTCOL
        LDA #$00
        STA VIC_BGCOL0
        LDX #$27

L0C02:
        LDA #$66
        STA $C000,X
        LDA #$65
        STA $C320,X
        LDA #$01
        STA COLOR_RAM,X
        STA $DB20,X
        DEX
        BPL L0C02
        LDX #$13

L0C19:
        JSR $E9F0
        JSR $EA24
        LDA #$68
        LDY #$00
        STA ($D1),Y
        LDA #$01
        STA ($F3),Y
        LDY #$27
        LDA #$67
        STA ($D1),Y
        LDA #$01
        STA ($F3),Y
        DEX
        BNE L0C19
        LDX #$61
        STX $C000
        INX
        STX $C027
        INX
        STX $C320
        INX
        STX $C347
        LDX #$13

L0C49:
        JSR $E9F0
        JSR $EA24
        LDY #$26

L0C51:
        LDA $0801
        INC $0C52
        AND #$01
        CLC
        ADC #$69
        STA ($D1),Y
        LDA #$0B
        STA ($F3),Y
        DEY
        BNE L0C51
        DEX
        BNE L0C49
        LDX #$15

L0C6A:
        JSR sub_1CFA
        INX
        CPX #$19
        BNE L0C6A
        JSR sub_0DAB
        JSR sub_0DA3
        JSR sub_209C
        LDA #$81
        JSR sub_20E7
        LDA #$F7
        JSR sub_20F1
        LDA #$81
        JSR sub_1CE4
        LDY #$00
        STY $0344
        LDA $0CD3,Y

L0C92:
        STA $0286
        INY
        LDA $0CD3,Y
        STA $D3
        TYA
        PHA
        JSR $E56C
        PLA
        TAY

loc_0CA2:
        INY
        LDA $0CD3,Y
        CMP #$5C
        BEQ L0CB0
        JSR CHROUT
        JMP loc_0CA2

L0CB0:
        JSR sub_0DA3
        INY
        LDA $0CD3,Y
        CMP #$5C
        BNE L0C92

L0CBB:
        JSR GETIN
        CMP #$86
        BEQ loc_0CCF
        CMP #$85
        BNE L0CBB
        STA $035D
        JSR sub_2364
        JMP loc_0CCF

loc_0CCF:
        STA $035D
        RTS
        .byte $07, $0B, $44, $49, $52, $4B, $97, $A9, $9E, $4D, $45, $49, $45, $52, $97, $A9  ; ..dirk...meier..
        .byte $9E, $53, $43, $48, $52, $49, $45, $42, $3A, $5C, $01, $0D, $57, $45, $4C, $54  ; .schrieb:\..welt
        .byte $45, $4E, $44, $DF, $4D, $4D, $45, $52, $55, $4E, $47, $5C, $05, $08, $28, $43  ; end.mmerung\..(c
        .byte $29, $97, $A9, $1E, $31, $39, $38, $37, $97, $A9, $1E, $4D, $41, $52, $4B, $54  ; )...1987...markt
        .byte $97, $A9, $1E, $55, $4E, $44, $97, $A9, $1E, $54, $45, $43, $48, $4E, $49, $4B  ; ...und...technik
        .byte $97, $5C, $0E, $07, $45, $49, $4E, $97, $A9, $9A, $46, $41, $4E, $54, $41, $53  ; .\..ein...fantas
        .byte $59, $2D, $53, $54, $52, $41, $54, $45, $47, $49, $45, $2D, $53, $50, $49, $45  ; y-strategie-spie
        .byte $4C, $5C, $0E, $0B, $46, $FF, $52, $97, $A9, $9A, $5A, $57, $45, $49, $97, $A9  ; l\..f.r...zwei..
        .byte $9A, $46, $45, $4C, $44, $48, $45, $52, $52, $45, $4E, $5C, $00, $00, $5C, $04  ; .feldherren\..\.
        .byte $09, $3C, $46, $31, $3E, $97, $A9, $9C, $41, $4C, $54, $45, $53, $97, $A9, $9C  ; .<f1>...altes...
        .byte $53, $50, $49, $45, $4C, $97, $A9, $9C, $4C, $41, $44, $45, $4E, $5C, $04, $08  ; spiel...laden\..
        .byte $3C, $46, $33, $3E, $97, $A9, $9C, $4E, $45, $55, $45, $53, $97, $A9, $9C, $53  ; <f3>...neues...s
        .byte $50, $49, $45, $4C, $97, $A9, $9C, $53, $54, $41, $52, $54, $45, $4E, $5C, $5C  ; piel...starten\\

sub_0DA3:
        LDA #$0D
        JSR CHROUT
        JMP CHROUT

sub_0DAB:
        SEI
        LDA #$C2
        STA IRQ_VECTOR_LO
        LDA #$0D
        STA IRQ_VECTOR_HI
        LDA #$02
        STA $0346
        LDA #$02
        STA $0342
        CLI
        RTS
        .byte $CE, $46, $03, $F0, $03, $4C, $31, $EA, $A9, $02, $8D, $46, $03, $AD, $01, $08  ; Nf...l1....f....
        .byte $EE, $D0, $0D, $29, $0F, $AA, $20, $22, $1B, $BD, $48, $E3, $A8, $20, $28, $1B  ; .P.).. "..h.. (.
        .byte $AD, $42, $03, $E9, $01, $D0, $02, $A9, $FF, $9D, $48, $E3, $8C, $42, $03, $EE  ; .b...P....h..b..
        .byte $43, $03, $CE, $44, $03, $AD, $43, $03, $CD, $44, $03, $90, $03, $AD, $44, $03  ; c.Nd..c.Md....d.
        .byte $8D, $16, $D4, $4A, $6A, $6A, $8D, $01, $D4, $8D, $08, $D4, $8D, $0F, $D4, $4C  ; ..Tjjj..T..T..Tl
        .byte $31, $EA  ; 1.

sub_0E14:
        LDA #$4F
        STA SID_VOLUME
        LDA #$F3
        STA SID_RESFLT
        LDX #$01
        STX $0343
        DEX
        STX $0344
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
        STX $0348
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

sub_0ECF:
        JSR sub_1F1C
        CMP #$04
        BNE L0ED9
        JMP loc_1EA8

L0ED9:
        LDA $034A
        CMP #$02
        BNE L0EF6
        LDX $034B
        LDA $0347
        BEQ L0EEE
        CPX #$3C
        BMI L0EF6
        BPL L0F06

L0EEE:
        CPX #$3C
        BMI L0F06
        RTS
        .byte $4C, $06, $0F  ; l..

L0EF6:
        LDA $034A
        BNE L0EFE
        JSR sub_12B1

L0EFE:
        CMP #$01
        BNE L0F05
        JSR sub_12EE

L0F05:
        RTS

L0F06:
        LDA #$00
        STA $034E
        JSR sub_0F8C
        JSR sub_1F1C

loc_0F11:
        CMP #$06
        BEQ L0F4E
        CMP #$0B
        BCC L0F2B
        STA $034E
        JSR sub_1FF6
        LDY #$05
        LDA ($F9),Y
        TAX
        TXA
        SEC
        SBC #$69
        JMP loc_0F11

L0F2B:
        LDA #$6F

loc_0F2D:
        PHA
        LDX $034E
        BNE L0F77
        JSR sub_1F77
        PLA
        PHA
        STA ($D1),Y
        JSR sub_1C01
        STA ($F3),Y
        LDX $034C
        JSR sub_0F82
        PLA
        STA ($B4),Y
        JSR sub_1F82
        JMP sub_1EE2

L0F4E:
        LDA $0347
        BEQ L0F58
        LDA #$69
        JMP loc_0F2D

L0F58:
        LDA #$71
        JMP loc_0F2D
        .byte $05, $11, $1D, $0E, $2A, $2F, $34, $19, $05, $0B, $46, $45, $4B, $06, $05, $0A  ; ....*/4...fek...
        .byte $15, $15, $15, $15, $19, $23, $22, $07, $11, $22  ; .....#".."

L0F77:
        JSR sub_1FF6
        LDY #$05
        PLA
        STA ($F9),Y
        JMP sub_1F82

sub_0F82:
        DEX
        TXA
        JSR sub_1AD3
        LDY $034B
        DEY
        RTS

sub_0F8C:
        LDX #$0C

L0F8E:
        LDA $034B
        CMP $0F5D,X
        BNE L0F9E
        LDA $034C
        CMP $0F6A,X
        BEQ L0FA1

L0F9E:
        DEX
        BPL L0F8E

L0FA1:
        BMI L0FA9
        LDA $4FF2,X
        BMI L0FA9
        RTS

L0FA9:
        PLA
        PLA
        RTS

sub_0FAC:
        LDA #$57
        STA $F7
        LDA #$10
        STA $F8
        JSR sub_15C2

loc_0FB7:
        LDA ($F7),Y
        BMI L1003
        STA ($F9),Y
        PHA
        JSR sub_177A
        JSR sub_1781
        LDA ($F7),Y
        STA ($F9),Y
        PHA
        JSR sub_177A
        JSR sub_1781
        LDX $034E
        LDA $1017,X
        STA ($F9),Y
        JSR sub_177A
        LDA $1037,X
        STA ($F9),Y
        JSR sub_177A
        STA ($F9),Y
        JSR sub_177A
        PLA
        JSR sub_1AD3
        PLA
        TAY
        LDA ($B4),Y
        TAX
        LDA $034E
        CLC
        ADC #$74
        STA ($B4),Y
        LDY #$00
        TXA
        STA ($F9),Y
        JSR sub_177A
        JMP loc_0FB7

L1003:
        CMP #$FF
        BEQ L1012
        AND #$1F
        STA $034E
        JSR sub_1781
        JMP loc_0FB7

L1012:
        LDY #$04
        STA ($F9),Y
        RTS
        .byte $16, $12, $11, $14, $18, $10, $16, $12, $05, $10, $16, $16, $30, $05, $16, $18  ; ............0...
        .byte $01, $08, $02, $02, $08, $05, $01, $08, $12, $01, $01, $01, $02, $01, $07, $03  ; ................
        .byte $10, $10, $12, $10, $08, $15, $10, $10, $09, $12, $10, $10, $10, $10, $14, $12  ; ................
        .byte $04, $05, $07, $05, $20, $06, $06, $05, $01, $08, $04, $06, $30, $01, $10, $08  ; .... .......0...
        .byte $80, $0C, $08, $0D, $08, $0E, $08, $10, $08, $11, $08, $12, $08, $14, $08, $15  ; ................
        .byte $08, $16, $08, $18, $08, $19, $08, $1A, $08, $0C, $0A, $0D, $0A, $0E, $0A, $0F  ; ................
        .byte $0A, $10, $0A, $11, $0A, $12, $0A, $13, $0A, $14, $0A, $15, $0A, $16, $0A, $17  ; ................
        .byte $0A, $18, $0A, $19, $0A, $1A, $0A, $81, $0C, $06, $0D, $06, $0E, $06, $10, $06  ; ................
        .byte $11, $06, $12, $06, $14, $06, $15, $06, $16, $06, $18, $06, $19, $06, $1A, $06  ; ................
        .byte $0C, $21, $0D, $21, $0E, $21, $0F, $21, $10, $21, $11, $21, $12, $21, $13, $21  ; .!.!.!.!.!.!.!.!
        .byte $14, $21, $15, $21, $16, $21, $2D, $12, $2D, $16, $10, $1D, $11, $1D, $12, $1D  ; .!.!.!-.-.......
        .byte $10, $1E, $11, $1E, $12, $1E, $10, $1F, $11, $1F, $12, $1F, $82, $1D, $0D, $1E  ; ................
        .byte $0E, $1F, $0F, $20, $10, $20, $11, $1F, $11, $1E, $11, $1D, $11, $1D, $17, $1E  ; ... . ..........
        .byte $17, $1F, $17, $20, $17, $20, $18, $1F, $19, $1E, $1A, $1D, $1B, $83, $0C, $07  ; ... . ..........
        .byte $0D, $07, $0E, $07, $10, $07, $11, $07, $12, $07, $14, $07, $15, $07, $16, $07  ; ................
        .byte $18, $07, $19, $07, $1A, $07, $34, $14, $0C, $1D, $0D, $1D, $0E, $1D, $0C, $1E  ; ......4.........
        .byte $0D, $1E, $0E, $1E, $0C, $1F, $0D, $1F, $0E, $1F, $14, $1D, $15, $1D, $16, $1D  ; ................
        .byte $14, $1F, $15, $1F, $16, $1F, $14, $1E, $15, $1E, $16, $1E, $84, $26, $13, $27  ; .............&.'
        .byte $13, $2F, $13, $2F, $15, $27, $15, $26, $15, $85, $13, $0F, $14, $0F, $15, $0F  ; ././.'.&........
        .byte $13, $10, $14, $10, $15, $10, $13, $11, $14, $11, $15, $11, $13, $17, $14, $17  ; ................
        .byte $15, $17, $13, $18, $14, $18, $15, $18, $13, $19, $14, $19, $15, $19, $86, $13  ; ................
        .byte $0C, $87, $47, $09, $47, $0A, $47, $0B, $47, $0C, $47, $0D, $47, $0E, $47, $0F  ; ..g.g.g.g.g.g.g.
        .byte $47, $10, $47, $11, $47, $12, $47, $13, $47, $14, $47, $15, $47, $16, $47, $17  ; g.g.g.g.g.g.g.g.
        .byte $47, $18, $47, $19, $47, $1A, $47, $1B, $4C, $04, $4C, $05, $4C, $06, $4C, $07  ; g.g.g.g.l.l.l.l.
        .byte $4C, $09, $4C, $0A, $4C, $0B, $4C, $0C, $4C, $13, $4C, $14, $4C, $15, $4C, $16  ; l.l.l.l.l.l.l.l.
        .byte $4C, $18, $4C, $19, $4C, $1A, $4C, $1B, $88, $4E, $0A, $4E, $0B, $4E, $14, $4E  ; l.l.l.l..n.n.n.n
        .byte $15, $89, $89, $4A, $01, $4B, $01, $4A, $02, $4B, $02, $4C, $02, $4D, $02, $4E  ; ...j.k.j.k.l.m.n
        .byte $02, $4A, $1D, $4B, $1D, $4C, $1D, $4D, $1D, $4E, $1D, $4A, $1E, $4B, $1E, $46  ; .j.k.l.m.n.j.k.f
        .byte $0B, $46, $0C, $46, $0D, $46, $17, $46, $18, $46, $19, $8A, $49, $04, $4A, $04  ; .f.f.f.f.f..i.j.
        .byte $4B, $04, $49, $05, $4A, $05, $4B, $05, $49, $06, $4A, $06, $4B, $06, $49, $07  ; k.i.j.k.i.j.k.i.
        .byte $4A, $07, $4B, $07, $49, $0A, $4A, $0A, $4B, $0A, $49, $0B, $4A, $0B, $4B, $0B  ; j.k.i.j.k.i.j.k.
        .byte $49, $0C, $4A, $0C, $4B, $0C, $49, $09, $4A, $09, $4B, $09, $49, $0E, $4A, $0E  ; i.j.k.i.j.k.i.j.
        .byte $4B, $0E, $49, $0F, $4A, $0F, $4B, $0F, $49, $10, $4A, $10, $4B, $10, $49, $11  ; k.i.j.k.i.j.k.i.
        .byte $4A, $11, $4B, $11, $49, $13, $4A, $13, $4B, $13, $49, $14, $4A, $14, $4B, $14  ; j.k.i.j.k.i.j.k.
        .byte $49, $15, $4A, $15, $4B, $15, $49, $16, $4A, $16, $4B, $16, $49, $18, $4A, $18  ; i.j.k.i.j.k.i.j.
        .byte $4B, $18, $49, $19, $4A, $19, $4B, $19, $49, $1A, $4A, $1A, $4B, $1A, $49, $1B  ; k.i.j.k.i.j.k.i.
        .byte $4A, $1B, $4B, $1B, $46, $0E, $46, $0F, $46, $10, $46, $14, $46, $15, $46, $16  ; j.k.f.f.f.f.f.f.
        .byte $8B, $45, $12, $8C, $4E, $0F, $4E, $10, $8D, $4D, $0A, $4D, $0B, $4D, $14, $4D  ; .e..n.n..m.m.m.m
        .byte $15, $8E, $4D, $09, $4E, $09, $4D, $0C, $4E, $0C, $4D, $13, $4E, $13, $4D, $16  ; ..m.n.m.n.m.n.m.
        .byte $4E, $16, $8F, $4D, $04, $4E, $04, $4D, $05, $4E, $05, $4D, $06, $4E, $06, $4D  ; n..m.n.m.n.m.n.m
        .byte $07, $4E, $07, $4D, $18, $4E, $18, $4D, $19, $4E, $19, $4D, $1A, $4E, $1A, $4D  ; .n.m.n.m.n.m.n.m
        .byte $1B, $4E, $1B, $46, $11, $46, $12, $46, $13, $FF  ; .n.f.f.f..

sub_12B1:
        JSR sub_12D4
        BCC L12D3

loc_12B6:
        LDA VIC_SP0COL
        EOR #$01
        STA VIC_SP0COL
        BEQ L12D3

sub_12C0:
        LDX $034F
        CPX #$11
        BEQ L12CB
        CPX #$16
        BNE L12D0

L12CB:
        LDA #$20
        JMP sub_1CE4

L12D0:
        JSR sub_1CE2

L12D3:
        RTS

sub_12D4:
        LDX $034F
        LDA $0347

sub_12DA:
        BEQ L12E2
        CPX #$12
        BCC L12EA
        BCS L12EC

L12E2:
        CPX #$0B
        BCC L12EA
        CPX #$12
        BCC L12EC

L12EA:
        CLC
        RTS

L12EC:
        SEC
        RTS

sub_12EE:
        LDA VIC_SP0COL
        CMP #$FA
        BEQ L1328
        JSR sub_12D4
        BCC L12EA
        JSR sub_1FF6
        LDY #$03
        LDA ($F9),Y
        BEQ L1327
        LDA #$0A
        STA VIC_SP0COL
        LDA $034B
        STA $0355
        LDA $034C
        STA $0356
        LDA $F9
        STA $0358
        LDA $FA
        STA $0359
        LDA $034F
        SEC
        SBC #$0B
        STA $0357

L1327:
        RTS

L1328:
        JSR sub_13AE
        LDX $034F
        LDA $0357
        CMP #$08
        BEQ L134C
        CMP #$0C
        BEQ L134C
        CMP #$0D
        BEQ L1350

L133D:
        LDA $0347
        EOR #$01
        AND #$01
        JSR sub_12DA
        BCS L1373

L1349:
        JMP loc_13A6

L134C:
        CPX #$09
        BEQ L1361

L1350:
        CPX #$06
        BNE L133D
        LDA $034B
        CMP #$3C
        BCS L1349
        JSR sub_0F8C
        DEC $4FF2,X

L1361:
        LDA $0357
        JSR sub_15AC
        JSR sub_2263
        JSR sub_1445
        LDA #$71
        PHA
        JMP loc_140E

L1373:
        LDA $0357
        JSR sub_15AC
        LDA $034F
        SEC
        SBC #$0B
        JSR sub_15AC
        JSR sub_1445
        LDX $0357
        LDA $1047,X
        JSR sub_1567
        STA $035C
        JSR sub_1FF6
        LDY #$02
        LDA ($F9),Y
        SED
        SEC
        SBC $035C
        CLD
        BEQ L13FD
        CMP #$5A
        BCS L13FD
        STA ($F9),Y

loc_13A6:
        LDA #$01
        STA VIC_SP0COL
        JMP sub_1EE2

sub_13AE:
        LDA $0355
        SEC
        SBC $034B
        JSR $BC3C
        JSR $BC0C
        LDA $61
        JSR $BA2B
        JSR $BBCA
        LDA $0356
        SEC
        SBC $034C
        JSR $BC3C
        JSR $BC0C
        LDA $61
        JSR $BA2B
        LDA #$57
        LDY #$00
        JSR $BA8C
        LDA $61
        JSR $B86A
        JSR $BF71
        JSR $BC9B
        LDX $0357
        LDA $1027,X
        CMP #$12
        BNE L13F3
        LDA #$0C

L13F3:
        CMP $65
        BCS L13FC
        PLA
        PLA
        JMP loc_13A6

L13FC:
        RTS

L13FD:
        JSR sub_20FB
        LDA #$FF
        LDY #$01
        STA ($F9),Y
        LDY #$05
        LDA ($F9),Y
        PHA
        JSR sub_2197

loc_140E:
        JSR sub_1F1C
        JSR sub_1F77
        PLA
        PHA
        STA ($D1),Y
        JSR sub_1C01
        STA ($F3),Y
        LDX $034C
        JSR sub_0F82
        PLA
        STA ($B4),Y
        LDX $0347
        LDA $034F
        CMP #$11
        BEQ loc_1456
        LDA $0347
        BNE L1442
        DEC $4FF0
        BNE L1442
        LDA #$01
        STA $034F
        JMP loc_1456

L1442:
        JMP loc_13A6

sub_1445:
        LDA $0358
        STA $F9
        LDA $0359
        STA $FA
        LDY #$03
        LDA #$00
        STA ($F9),Y
        RTS

loc_1456:
        LDX #$02
        JSR sub_1581
        JSR sub_1CE2
        JSR sub_209C
        LDX #$00

loc_1463:
        LDA $1512,X
        STA SID_V1FREQL
        LDA $1513,X
        STA SID_V1FREQH
        LDA $1514,X
        STA SID_V2FREQL
        LDA $1515,X
        STA SID_V2FREQH
        LDA $1516,X
        STA SID_V3FREQL
        LDA $1517,X
        STA SID_V3FREQH
        TXA
        PHA
        LDX #$0A
        JSR sub_1581
        PLA
        CLC
        ADC #$06
        CMP #$2A
        BEQ L149A
        TAX
        JMP loc_1463

L149A:
        JSR sub_2263
        LDA #$00
        STA VIC_IRQMSK
        STA VIC_VICIRQ
        STA VIC_SPENA
        LDA #$07
        STA SID_RESFLT
        LDX #$01
        STX VIC_EXTCOL
        STX VIC_BGCOL0
        LDY #$00
        JSR sub_1CF3
        DEX
        STX VIC_EXTCOL
        STX VIC_BGCOL0
        JSR BASIC_CLRSCR
        LDX #$06
        JSR sub_1581
        LDX #$09
        LDY #$10
        JSR $E50C
        LDX #$00

L14D2:
        LDA $153C,X
        JSR CHROUT
        INX
        CPX #$2B
        BNE L14D2
        LDX #$0C
        LDY #$0F
        JSR $E50C
        LDA $034F
        CMP #$11
        BNE L14F3
        LDX #$09
        JSR sub_1E8B
        JMP loc_14F8

L14F3:
        LDX #$00
        JSR sub_1E8B

loc_14F8:
        SEI
        LDA #$31
        STA IRQ_VECTOR_LO
        LDA #$EA
        STA IRQ_VECTOR_HI
        CLI

L1504:
        JSR GETIN
        BEQ L1504
        LDX #$F6
        TXS
        JSR sub_23BD
        JMP loc_080D
        .byte $DB, $20, $14, $1A, $67, $11, $45, $1D, $ED, $15, $67, $11, $14, $1A, $89, $13  ; . ..g.e...g.....
        .byte $81, $0F, $ED, $15, $81, $0F, $0A, $0D, $3B, $17, $67, $11, $A2, $0E, $3B, $17  ; ........;.g...;.
        .byte $89, $13, $81, $0F, $3B, $17, $67, $11, $9E, $0B, $9E, $53, $49, $45, $47, $0D  ; ....;.g....sieg.
        .byte $0D, $05, $20, $20, $20, $48, $45, $52, $52, $45, $4E, $20, $56, $4F, $4E, $20  ; ..   herren von 
        .byte $54, $48, $41, $49, $4E, $46, $41, $4C, $20, $53, $49, $4E, $44, $20, $4E, $55  ; thainfal sind nu
        .byte $4E, $20, $44, $49, $45  ; n die

sub_1567:
        PHA
        LDA $E000
        AND #$07
        INC $1569
        TAX
        PLA
        CLC
        SED
        ADC $1579,X
        CLD
        RTS
        .byte $00, $01, $01, $02, $02, $03, $03, $04  ; ........

sub_1581:
        LDY #$00
        JSR sub_1CF3
        DEX
        BNE sub_1581
        RTS
        .byte $29, $21, $D1, $21, $78, $21, $A4, $21, $D1, $21, $29, $21, $29, $21, $D1, $21  ; )!Q!x!.!Q!)!)!Q!
        .byte $15, $22, $78, $21, $29, $21, $29, $21, $5B, $21, $FD, $21, $D1, $21, $31, $22  ; ."x!)!)![!.!Q!1"
        .byte $63, $22  ; c"

sub_15AC:
        ASL A
        TAX
        LDA $158A,X
        STA $15BB
        LDA $158B,X
        STA $15BC
        JSR $0457
        LDX #$04
        JMP sub_1581

sub_15C2:
        LDA #$A0
        STA $F9
        LDA #$5F
        STA $FA
        LDY #$00
        RTS

sub_15CD:
        LDX #$00

loc_15CF:
        LDA $15F0,X
        CMP #$AB
        BEQ L15E5
        STA $E2F0,X
        INX
        BNE loc_15CF
        INC $15D1
        INC $15D8
        JMP loc_15CF

L15E5:
        LDA #$15
        STA $15D1
        LDA #$E2
        STA $15D8
        RTS
        .byte $66, $00, $66, $66, $66, $66, $3C, $00, $DB, $3C, $66, $7E, $66, $66, $66, $00  ; f.ffff<..<f~fff.
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $7F, $FF, $C0, $DF, $DF, $D8, $DB, $DA  ; .............X.Z
        .byte $FE, $FF, $03, $FB, $FB, $1B, $DB, $5B, $DA, $DB, $D8, $DF, $DF, $C0, $FF, $7F  ; .......[Z.X.....
        .byte $5B, $DB, $1B, $FB, $FB, $03, $FF, $FE, $00, $FF, $00, $FF, $FF, $00, $FF, $FF  ; [...............
        .byte $FF, $FF, $00, $FF, $FF, $00, $FF, $00, $5B, $5B, $5B, $5B, $5B, $5B, $5B, $5B  ; ........[[[[[[[[
        .byte $DA, $DA, $DA, $DA, $DA, $DA, $DA, $DA, $02, $40, $08, $01, $04, $20, $81, $10  ; ZZZZZZZZ.@... ..
        .byte $00, $48, $01, $20, $04, $40, $00, $44, $FF, $F8, $77, $8F, $FF, $F8, $77, $8F  ; .h. .@.d..w...w.
        .byte $00, $18, $3C, $2C, $76, $7E, $5A, $18, $00, $5A, $BD, $E7, $E7, $BD, $5A, $3C  ; ..<,v~z..z....z<
        .byte $E0, $00, $3E, $00, $F0, $06, $00, $7C, $00, $7E, $DB, $DB, $DB, $DB, $DB, $FF  ; ..>....|.~......
        .byte $00, $18, $34, $72, $72, $F1, $D9, $8C, $DF, $00, $FB, $FB, $FB, $00, $DF, $DF  ; ..4rr.Y.........
        .byte $00, $7F, $40, $5F, $5F, $58, $5B, $5B, $5B, $5B, $58, $5F, $5F, $40, $7F, $00  ; ..@__x[[[[x__@..
        .byte $E7, $E7, $E7, $E7, $81, $A5, $E7, $FF, $C3, $D1, $D9, $C0, $D9, $D1, $C3, $FF  ; ........CQY.YQC.
        .byte $FF, $F9, $31, $83, $C7, $E7, $FF, $FF, $FF, $F1, $F9, $E5, $CF, $9F, $BF, $FF  ; ..1.G.......O...
        .byte $FF, $DB, $C9, $C9, $C9, $4A, $00, $81, $CF, $C9, $C9, $83, $83, $93, $93, $FF  ; ..IIIj..OII.....
        .byte $FF, $C3, $95, $B1, $8D, $A9, $C3, $FF, $C3, $8B, $9B, $03, $9B, $8B, $C3, $FF  ; .C....C.C.....C.
        .byte $FF, $FB, $F9, $99, $93, $87, $83, $FF, $FF, $E7, $C3, $99, $99, $BD, $FF, $FF  ; ..........C.....
        .byte $97, $83, $93, $B7, $E7, $E7, $E7, $FF, $FF, $C3, $95, $B1, $8D, $A9, $C3, $FF  ; .........C....C.
        .byte $FF, $87, $E3, $93, $F3, $E3, $C3, $C1, $FF, $FF, $9F, $00, $00, $9F, $FF, $FF  ; ......CA........
        .byte $FF, $FF, $F3, $E3, $01, $C9, $E3, $FF, $E7, $E3, $13, $81, $01, $C9, $8C, $FF  ; .....I.......I..
        .byte $AB  ; .

sub_1721:
        LDA #$88
        STA $F7
        LDA #$17
        STA $F8
        LDY #$00
        STY $F9
        LDA #$50
        STA $FA

L1731:
        LDA ($F7),Y
        JSR sub_1781
        CMP #$04
        BCS L1742
        LDX #$01
        CLC
        ADC #$72
        JMP loc_1759

L1742:
        CMP #$FF
        BEQ L1780
        PHA
        LSR A
        LSR A
        LSR A
        LSR A
        TAX
        PLA
        AND #$0F
        CMP #$08
        BCC L1756
        SEC
        SBC #$11

L1756:
        CLC
        ADC #$6A

loc_1759:
        JSR sub_1766
        STA ($F9),Y
        JSR sub_177A
        DEX
        BNE loc_1759
        BEQ L1731

sub_1766:
        CMP #$69
        BEQ L176E
        CMP #$6A
        BNE L1779

L176E:
        LDA $0801
        INC $176F
        AND #$01
        CLC
        ADC #$69

L1779:
        RTS

sub_177A:
        INC $F9
        BNE L1780
        INC $FA

L1780:
        RTS

sub_1781:
        INC $F7
        BNE L1787
        INC $F8

L1787:
        RTS
        .byte $13, $26, $17, $1E, $F7, $27, $1E, $46, $A1, $64, $F2, $C2, $96, $13, $26, $27  ; .&...'.f.d.B..&'
        .byte $1E, $F7, $27, $1E, $36, $22, $C1, $54, $F2, $92, $56, $40, $26, $16, $37, $1E  ; ..'.6"At..v@&.7.
        .byte $F7, $27, $1E, $26, $20, $42, $B1, $44, $F2, $82, $46, $60, $16, $47, $1E, $F7  ; .'.& b.d..f`.g..
        .byte $27, $1E, $60, $52, $91, $34, $F2, $32, $30, $12, $46, $80, $47, $1E, $57, $00  ; '.`r.4.20.f.g.w.
        .byte $5C, $15, $5C, $1B, $70, $62, $81, $44, $B2, $10, $12, $70, $46, $80, $47, $15  ; \.\.pb.d...pf.g.
        .byte $57, $1E, $F0, $60, $42, $24, $61, $34, $22, $14, $52, $20, $22, $A0, $26, $90  ; w..`b$a4".r ".&.
        .byte $47, $1E, $57, $1E, $F0, $60, $52, $14, $71, $54, $42, $F0, $15, $A0, $47, $1E  ; g.w..`r.qtb...g.
        .byte $57, $1E, $F0, $20, $18, $3D, $19, $42, $24, $71, $44, $10, $22, $F0, $36, $90  ; w.. .=.b$qd.".6.
        .byte $47, $1E, $57, $1E, $F0, $20, $1F, $37, $1E, $32, $34, $71, $34, $F0, $40, $46  ; g.w.. .7.24q4.@f
        .byte $80, $47, $1E, $57, $1E, $F0, $20, $15, $37, $1E, $22, $20, $24, $81, $24, $E0  ; .g.w.. .7." $.$.
        .byte $16, $30, $46, $90, $47, $1E, $57, $1E, $F0, $20, $1F, $37, $1E, $50, $24, $71  ; .0f.g.w.. .7.p$q
        .byte $24, $E0, $76, $A0, $47, $1E, $57, $1E, $F0, $20, $1A, $3C, $1B, $40, $34, $61  ; $.v.g.w.. .<.@4a
        .byte $44, $30, $24, $90, $16, $10, $46, $A0, $47, $1E, $57, $1E, $F0, $B0, $34, $61  ; d0$...f.g.w...4a
        .byte $94, $B0, $36, $B0, $47, $1E, $57, $01, $6D, $19, $F0, $40, $24, $91, $64, $D0  ; ..6.g.w.m..@$.dP
        .byte $36, $A0, $47, $1E, $C7, $1E, $60, $1D, $19, $A0, $24, $51, $10, $51, $44, $D0  ; 6.g.G.`...$q.qdP
        .byte $46, $A0, $47, $1E, $C7, $1E, $70, $1E, $A0, $24, $41, $30, $41, $34, $F0, $36  ; f.g.G.p..$a0a4.6
        .byte $A0, $47, $01, $2D, $19, $97, $1E, $70, $1E, $A0, $24, $31, $60, $21, $24, $F0  ; .g.-...p..$1`!$.
        .byte $20, $15, $A0, $16, $77, $1E, $57, $00, $3C, $1B, $70, $1E, $C0, $31, $18, $4D  ;  ...w.w.<.p..1.m
        .byte $19, $31, $F0, $30, $26, $80, $26, $77, $1E, $57, $1E, $B0, $1E, $B0, $41, $1F  ; .1.0&.&w.w....a.
        .byte $47, $1E, $31, $F0, $20, $26, $90, $26, $77, $1E, $57, $1E, $A0, $1C, $1B, $C0  ; g.1. &.&w.w.....
        .byte $31, $1F, $47, $1E, $31, $1D, $19, $E0, $36, $A0, $16, $77, $1E, $57, $15, $F7  ; 1.g.1...6..w.w..
        .byte $C7, $15, $47, $15, $47, $15, $E0, $36, $B0, $77, $1E, $57, $1E, $F0, $80, $41  ; G.g.g..6.w.w...a
        .byte $1F, $47, $1E, $31, $1C, $1B, $F0, $26, $B0, $77, $1E, $57, $1E, $F0, $70, $51  ; .g.1...&.w.w..pq
        .byte $1F, $47, $1E, $31, $F0, $10, $46, $A0, $77, $1E, $57, $01, $3D, $19, $60, $18  ; .g.1..f.w.w.=.`.
        .byte $2D, $19, $70, $14, $51, $1A, $4C, $1B, $41, $F0, $36, $B0, $47, $00, $2C, $1B  ; -.p.q.l.a.6.g.,.
        .byte $97, $1E, $60, $15, $27, $1E, $60, $24, $51, $60, $41, $F0, $10, $36, $A0, $47  ; ..`.'.`$q`a..6.g
        .byte $1E, $C7, $1E, $60, $1F, $27, $1E, $60, $34, $51, $50, $31, $F0, $30, $26, $A0  ; .G.`.'.`4qp1.0&.
        .byte $47, $1E, $C7, $1E, $60, $1A, $2C, $1B, $70, $24, $61, $30, $41, $40, $32, $A0  ; g.G.`.,.p$a0a@2.
        .byte $46, $90, $47, $1E, $57, $00, $6C, $1B, $F0, $20, $44, $41, $20, $41, $14, $50  ; f.g.w.l.. da a.p
        .byte $52, $60, $56, $90, $47, $1E, $57, $1E, $F0, $A0, $34, $51, $10, $51, $24, $30  ; r`v.g.w...4q.q$0
        .byte $42, $50, $86, $80, $47, $1E, $57, $1E, $F0, $40, $18, $4D, $19, $34, $D1, $24  ; bp..g.w..@.m.4Q$
        .byte $62, $30, $26, $10, $66, $80, $47, $1E, $57, $1E, $D0, $1D, $19, $40, $1F, $40  ; b0&.f.g.w.P..@.@
        .byte $1E, $34, $F1, $14, $52, $70, $16, $10, $46, $70, $47, $1E, $57, $1E, $E0, $1E  ; .4..rp..fpg.w...
        .byte $90, $54, $F1, $11, $32, $C0, $26, $40, $36, $47, $1E, $57, $1E, $E0, $1E, $A0  ; .t..2.&@6g.w....
        .byte $14, $1D, $19, $24, $71, $34, $51, $42, $B0, $36, $10, $56, $47, $1E, $57, $15  ; ...$q4qb.6.vg.w.
        .byte $E0, $1E, $70, $1D, $19, $30, $1E, $24, $71, $24, $30, $51, $32, $B0, $26, $15  ; ..p..0.$q$0q2.&.
        .byte $16, $10, $36, $47, $15, $57, $1E, $C0, $12, $1C, $1B, $80, $1E, $30, $1E, $24  ; ..6g.w.......0.$
        .byte $61, $34, $30, $12, $41, $42, $A0, $26, $40, $26, $47, $1E, $57, $1E, $B0, $52  ; a40.ab.&@&g.w..r
        .byte $70, $1E, $20, $1C, $1B, $14, $71, $44, $32, $51, $42, $80, $26, $60, $16, $47  ; p. ...qd2qb.&`.g
        .byte $1E, $57, $01, $BD, $19, $52, $60, $1E, $30, $24, $61, $44, $52, $41, $42, $F0  ; .w...r`.0$adrab.
        .byte $20, $16, $37, $1E, $F7, $27, $1E, $72, $40, $1E, $30, $12, $34, $61, $82, $41  ;  .7..'.r@.0.4a.a
        .byte $52, $E0, $16, $26, $27, $1E, $F7, $27, $1E, $A2, $1C, $1B, $12, $10, $32, $24  ; r..&'..'......2$
        .byte $71, $72, $41, $62, $C0, $26, $13, $26, $17, $1E, $F7, $27, $1E, $F2, $42, $71  ; qrab.&.&...'..bq
        .byte $72, $51, $72, $90, $26, $13, $FF  ; rqr.&..

sub_1A3F:
        LDX #$13

L1A41:
        JSR $E9F0
        JSR $EA24
        LDY #$02

L1A49:
        LDA ($D1),Y
        DEY
        STA ($D1),Y
        INY
        LDA ($F3),Y
        DEY
        STA ($F3),Y
        INY
        INY
        CPY #$27
        BNE L1A49
        DEX
        BNE L1A41
        RTS

sub_1A5E:
        LDX #$13

L1A60:
        JSR $E9F0
        JSR $EA24
        LDY #$25

L1A68:
        LDA ($D1),Y
        INY
        STA ($D1),Y
        DEY
        LDA ($F3),Y
        INY
        STA ($F3),Y
        DEY
        DEY
        BNE L1A68
        DEX
        BNE L1A60
        RTS

sub_1A7B:
        LDX #$01

L1A7D:
        JSR $E9F0
        JSR $EA24
        JSR sub_1A9A
        INX
        JSR $E9F0
        JSR $EA24
        LDY #$26

L1A8F:
        JSR sub_1AAB
        DEY
        BNE L1A8F
        CPX #$13
        BNE L1A7D
        RTS

sub_1A9A:
        LDA $D1
        STA $F7
        LDA $D2
        STA $F8
        LDA $F3
        STA $F9
        LDA $F4
        STA $FA
        RTS

sub_1AAB:
        LDA ($D1),Y
        STA ($F7),Y
        LDA ($F3),Y
        STA ($F9),Y
        RTS

sub_1AB4:
        LDX #$13

L1AB6:
        JSR $E9F0
        JSR $EA24
        JSR sub_1A9A
        DEX
        JSR $E9F0
        JSR $EA24
        LDY #$26

L1AC8:
        JSR sub_1AAB
        DEY
        BNE L1AC8
        CPX #$01
        BNE L1AB6
        RTS

sub_1AD3:
        STA $0346
        STA $B4
        LDA #$00
        STA $B5
        ASL $B4
        ROL $B5
        ASL $B4
        ROL $B5
        ASL $B4
        ROL $B5
        LDA $B4
        STA $0342
        LDA $B5
        STA $0343
        LDA $0346
        STA $B4
        LDA #$00
        STA $B5
        ASL $B4
        ROL $B5
        CLC
        LDA $B4
        ADC $0342
        STA $B4
        LDA $B5
        ADC $0343
        STA $B5
        ASL $B4
        ROL $B5
        ASL $B4
        ROL $B5
        ASL $B4
        ROL $B5
        CLC
        LDA $B5
        ADC #$50
        STA $B5
        RTS

sub_1B22:
        SEI
        LDA #$31
        STA $01
        RTS

sub_1B28:
        LDA #$37
        STA $01
        CLI
        RTS

loc_1B2E:
        LDA $0341
        JSR sub_1AD3
        LDX #$01

loc_1B36:
        JSR $E9F0
        JSR $EA24
        LDA #$01
        STA $0343
        LDY $0340
        STY $0342

L1B47:
        LDY $0342
        LDA ($B4),Y
        LDY $0343
        STA ($D1),Y
        JSR sub_1C01
        STA ($F3),Y
        INC $0342
        INC $0343
        LDA $0343
        CMP #$27
        BNE L1B47
        RTS

sub_1B64:
        LDA $0341
        CLC
        ADC #$12
        JSR sub_1AD3
        LDX #$13
        JMP loc_1B36

loc_1B72:
        LDA $0340
        STA $0344
        LDA #$01
        STA $0345

loc_1B7D:
        LDA $0341
        JSR sub_1AD3
        LDX #$01

L1B85:
        JSR $E9F0
        JSR $EA24
        LDY $0344
        LDA ($B4),Y
        LDY $0345
        STA ($D1),Y
        JSR sub_1C01
        STA ($F3),Y
        LDA $B4
        CLC
        ADC #$50
        STA $B4
        LDA $B5
        ADC #$00
        STA $B5
        INX
        CPX #$14
        BNE L1B85
        RTS

loc_1BAD:
        LDA $0340
        CLC
        ADC #$25
        STA $0344
        LDA #$26
        STA $0345
        JMP loc_1B7D

sub_1BBE:
        LDA $0340
        BEQ L1BEA
        JSR sub_1A5E
        DEC $0340
        JMP loc_1B72

sub_1BCC:
        LDA $0340
        CMP #$2A
        BEQ L1BEA
        JSR sub_1A3F
        INC $0340
        JMP loc_1BAD

sub_1BDC:
        LDA $0341
        BEQ L1BEA
        JSR sub_1AB4
        DEC $0341
        JMP loc_1B2E

L1BEA:
        LDA #$01
        STA $0353
        RTS

sub_1BF0:
        LDA $0341
        CMP #$15
        BEQ L1BEA
        JSR sub_1A7B
        INC $0341
        JSR sub_1B64
        RTS

sub_1C01:
        STX $0346
        CMP #$69
        BCC L1C1F
        CMP #$74
        BCC L1C15
        CMP #$7B
        BCC L1C25
        LDA #$00
        JMP loc_1C21

L1C15:
        SEC
        SBC #$69
        TAX
        LDA $1C2A,X
        JMP loc_1C21

L1C1F:
        LDA #$0B

loc_1C21:
        LDX $0346
        RTS

L1C25:
        LDA #$07
        JMP loc_1C21
        .byte $00, $00, $06, $02, $01, $06, $0B, $0B, $0B, $0B, $0B  ; ...........

sub_1C35:
        LDX #$23

L1C37:
        LDA $1C65,X
        STA $C400,X
        DEX
        BPL L1C37
        LDX #$1C

L1C42:
        LDA #$00
        STA $C423,X
        DEX
        BPL L1C42
        STA VIC_SPXMSB
        LDA #$01
        STA VIC_SPENA
        STA VIC_SP0COL
        LDA #$98
        STA VIC_SP0Y
        LDA #$B6
        STA VIC_SP0X
        LDA #$10
        STA $C3F8
        RTS
        .byte $1F, $80, $00, $3F, $C0, $00, $60, $60, $00, $C0, $30, $00, $C0, $30, $00, $C0  ; ...?..``..0..0..
        .byte $30, $00, $C0, $30, $00, $C0, $30, $00, $C0, $30, $00, $60, $60, $00, $3F, $C0  ; 0..0..0..0.``.?.
        .byte $00, $1F, $80  ; ...

sub_1C88:
        JSR sub_0E14
        LDA #$F7
        STA SID_RESFLT
        LDA #$00
        STA $1ACF
        LDX #$13

L1C97:
        TXA
        PHA
        JSR sub_1AB4
        PLA
        TAX
        TAX
        ASL A
        ASL A
        ASL A
        STA SID_FCUTH
        STA SID_V1FREQH
        STA SID_V2FREQH
        STA SID_V3FREQH
        LDY #$19
        JSR sub_1CF3
        DEX
        BNE L1C97
        LDA #$01
        STA $1ACF
        RTS

sub_1CBC:
        JSR sub_0E14
        LDX #$4F
        STA SID_VOLUME
        LDX #$13

L1CC6:
        TXA
        PHA
        JSR sub_1BF0
        PLA
        TAX
        EOR #$FF
        ASL A
        ASL A
        ASL A
        STA SID_V1FREQH
        STA SID_V2FREQH
        STA SID_V3FREQH
        STA SID_FCUTH
        DEX
        BNE L1CC6
        RTS

sub_1CE2:
        LDA #$80

sub_1CE4:
        STA SID_V1CTRL
        STA SID_V2CTRL
        STA SID_V3CTRL
        RTS

sub_1CEE:
        LDA #$81
        JMP sub_1CE4

sub_1CF3:
        JSR $EEB3
        DEY
        BNE sub_1CF3
        RTS

sub_1CFA:
        JSR $E9F0
        JSR $EA24
        LDY #$27

L1D02:
        LDA #$A0
        STA ($D1),Y
        LDA #$06
        STA ($F3),Y
        DEY
        BPL L1D02
        RTS

sub_1D0E:
        LDX #$16
        JSR $E9FF
        LDY #$0A
        JSR $E50C
        LDX $0347
        LDA $1D34,X
        TAX
        JSR sub_1E8B
        LDX $034A
        LDA $1D36,X
        TAX
        JSR sub_1E8B
        LDX #$29
        JSR sub_1E8B
        JMP sub_1EE2
        .byte $00, $09, $12, $1C, $25, $00, $00, $06, $0C, $11, $16, $1C, $20, $28, $31, $31  ; ....%....... (11
        .byte $37, $45, $53, $59, $66, $73, $9A, $45, $7C, $85, $90, $9A, $A3, $AC, $B5, $C1  ; 7esyfs.e|......A
        .byte $05, $45, $4C, $44, $4F, $49, $4E, $20, $5C, $05, $44, $41, $49, $4C, $4F, $52  ; .eldoin \.dailor
        .byte $20, $5C, $42, $45, $57, $45, $47, $55, $4E, $47, $53, $5C, $41, $4E, $47, $52  ;  \bewegungs\angr
        .byte $49, $46, $46, $53, $5C, $54, $4F, $52, $5C, $50, $48, $41, $53, $45, $5C, $20  ; iffs\tor\phase\ 
        .byte $28, $54, $4F, $52, $29, $5C, $57, $45, $49, $54, $45, $52, $5C, $53, $41, $56  ; (tor)\weiter\sav
        .byte $45, $20, $47, $41, $4D, $45, $5C, $05, $46, $49, $4C, $45, $1D, $28, $41, $2D  ; e game\.file.(a-
        .byte $5A, $29, $3F, $1D, $5C, $05, $44, $49, $53, $4B, $2D, $45, $52, $52, $4F, $52  ; z)?.\.disk-error
        .byte $21, $21, $5C, $9D, $2E, $20, $5A, $55, $47, $5C, $57, $49, $45, $53, $45, $5C  ; !!\.. zug\wiese\
        .byte $46, $4C, $55, $53, $53, $5C, $57, $41, $4C, $44, $5C, $45, $4E, $44, $45, $5C  ; fluss\wald\ende\
        .byte $53, $55, $4D, $50, $46, $5C, $54, $4F, $52, $5C, $47, $45, $42, $49, $52, $47  ; sumpf\tor\gebirg
        .byte $45, $5C, $50, $46, $4C, $41, $53, $54, $45, $52, $5C, $4D, $41, $55, $45, $52  ; e\pflaster\mauer
        .byte $5C, $53, $43, $48, $57, $45, $52, $54, $54, $52, $DF, $47, $45, $52, $5C, $42  ; \schwerttr.ger\b
        .byte $4F, $47, $45, $4E, $53, $43, $48, $FF, $54, $5A, $45, $4E, $5C, $41, $44, $4C  ; ogensch.tzen\adl
        .byte $45, $52, $5C, $4C, $41, $4E, $5A, $45, $4E, $54, $52, $DF, $47, $45, $52, $5C  ; er\lanzentr.ger\
        .byte $4B, $52, $49, $45, $47, $53, $53, $43, $48, $49, $46, $46, $5C, $52, $45, $49  ; kriegsschiff\rei
        .byte $54, $45, $52, $45, $49, $5C, $4B, $41, $54, $41, $50, $55, $4C, $54, $5C, $42  ; terei\katapult\b
        .byte $4C, $55, $54, $53, $41, $55, $47, $45, $52, $5C, $41, $58, $54, $4D, $DF, $4E  ; lutsauger\axtm.n
        .byte $4E, $45, $52, $5C, $46, $45, $4C, $44, $48, $45, $52, $52, $5C, $4C, $49, $4E  ; ner\feldherr\lin
        .byte $44, $57, $55, $52, $4D, $5C, $52, $41, $4D, $4D, $42, $4F, $43, $4B, $5C, $57  ; dwurm\rammbock\w
        .byte $41, $47, $45, $4E, $46, $41, $48, $52, $45, $52, $5C, $57, $4F, $4C, $46, $53  ; agenfahrer\wolfs
        .byte $52, $45, $49, $54, $45, $52, $5C  ; reiter\

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

loc_2307:
        LDX #$16
        JSR $E9FF
        INX
        JSR $E9FF
        LDX #$16
        LDY #$0E
        JSR $E50C
        JSR sub_2347
        LDX #$08
        JSR SETLFS
        LDA #$01
        LDX #$5C
        LDY #$03
        JSR SETNAM
        LDA #$4F
        STA $F8
        LDA #$F0
        STA $F7
        LDA #$F7
        LDX #$79
        LDY #$66
        JSR SAVE
        BCC L2346
        LDX #$16
        JSR $E9FF
        JSR sub_2391
        JMP loc_2307

L2346:
        RTS

sub_2347:
        LDX #$47
        JSR sub_1E8B
        JSR sub_23B9

L234F:
        JSR GETIN
        CMP #$41
        BCC L234F
        CMP #$5B
        BCS L234F
        STA $035C
        JSR CHROUT
        JSR sub_23BD

L2363:
        RTS

sub_2364:
        LDX #$12
        LDY #$0E
        JSR $E50C
        JSR sub_2347
        LDX #$08
        LDY #$01
        JSR SETLFS
        LDA #$01
        LDX #$5C
        LDY #$03
        JSR SETNAM
        LDA #$00
        JSR LOAD
        BCC L2363
        JSR sub_23A9
        JSR sub_2391
        JSR sub_23A9
        JMP sub_2364

sub_2391:
        JSR sub_23B9
        LDX $D6
        LDY #$0F
        JSR $E50C
        LDX #$55
        JSR sub_1E8B
        JSR sub_2129

L23A3:
        JSR GETIN
        BEQ L23A3
        RTS

sub_23A9:
        LDX #$14

L23AB:
        LDA #$69
        STA $C2DC,X
        LDA #$0B
        STA $DADC,X
        DEX
        BPL L23AB
        RTS

sub_23B9:
        LDA #$31
        BNE L23BF

sub_23BD:
        LDA #$7E

L23BF:
        STA $0EAC

L23C2:
        RTS

sub_23C3:
        LDX $034B
        DEX
        BNE L23C2
        LDA $034F
        CMP #$12
        BCC L23C2
        LDA #$11
        STA $034F
        JMP loc_1456