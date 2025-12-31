; =============================================================================
; Initialization - Hardware setup, memory initialization
; Address range: $080D - $0884
; =============================================================================

loc_080D:
        LDA #$9F
        STA $4FF0               ; ELDOIN_UNITS (Eldoin unit count)
        LDA #$00
        LDX #$18

L0816:
        STA SID_V1FREQL,X
        STA $0340,X             ; SCROLL_X (map scroll X)
        STA $0359,X             ; ATTACKER_PTR (attacker data ptr hi)
        STA $4FF2,X             ; GATE_FLAGS (gate/build location flags)
        DEX
        BPL L0816
        JSR sub_1B22
        LDA #$00
        STA $F7                 ; TEMP_PTR1 (general ptr lo)
        STA $F9                 ; TEMP_PTR2 (general ptr lo)
        TAY
        LDA #$D0
        STA $F8                 ; TEMP_PTR1 (general ptr hi)
        LDA #$E0
        STA $FA                 ; TEMP_PTR2 (general ptr hi)

L0837:
        LDA ($F7),Y             ; TEMP_PTR1 (general ptr lo)
        STA ($F9),Y             ; TEMP_PTR2 (general ptr lo)
        INY
        BNE L0837
        INC $F8                 ; TEMP_PTR1 (general ptr hi)
        INC $FA                 ; TEMP_PTR2 (general ptr hi)
        LDA $FA                 ; TEMP_PTR2 (general ptr hi)
        BNE L0837
        JSR sub_1B28
        LDA #$ED
        STA $0341               ; SCROLL_Y (map scroll Y)
        LDA #$C0
        STA $0288               ; HIBASE (screen mem page)
        LDA #$94
        STA CIA2_PRA
        LDA #$08
        STA VIC_VMCSB
        JSR sub_15CD
        JSR sub_0BF3
        JSR sub_0E56
        LDA $035D               ; MENU_SELECT (menu selection)
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
