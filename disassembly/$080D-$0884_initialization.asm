; =============================================================================
; Initialization - Hardware setup, memory initialization
; Address range: $080D - $0884
; =============================================================================

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
