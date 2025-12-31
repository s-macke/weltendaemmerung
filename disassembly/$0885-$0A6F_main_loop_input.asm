; =============================================================================
; Main Game Loop and Input Handling
; Address range: $0885 - $0A6F
; =============================================================================

loc_0885:
        LDX #$32

L0887:
        JSR $EEB3
        DEX
        BNE L0887

loc_088D:
        LDA $0347               ; CURRENT_PLAYER (active player)
        EOR #$01
        AND #$01
        TAX
        LDA CIA1_PRA,X
        EOR #$1F
        AND #$1F
        STA $0354               ; JOY_STATE (joystick state)
        BNE L08AA
        STA $034D               ; PREV_JOY (prev joystick)
        JSR sub_12C0
        JMP loc_088D

L08AA:
        CMP #$10
        BNE L08BC
        CMP $034D               ; PREV_JOY (prev joystick)
        BEQ loc_0885
        STA $034D               ; PREV_JOY (prev joystick)
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
        LDA $0354               ; JOY_STATE (joystick state)
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
        LDA ($F9),Y             ; TEMP_PTR2 (general ptr lo)
        BNE L09C5
        JMP loc_12B6

L09C5:
        LDY #$05
        LDA ($F9),Y             ; TEMP_PTR2 (general ptr lo)
        PHA
        LDA $F9                 ; TEMP_PTR2 (general ptr lo)
        STA $0350               ; STORED_PTR (F9/FA backup lo)
        LDA $FA                 ; TEMP_PTR2 (general ptr hi)
        STA $0351               ; STORED_PTR (F9/FA backup hi)
        JSR sub_1F1C
        JSR sub_1F77
        LDA ($D1),Y             ; SCREEN_PTR (screen line ptr lo)
        STA $0352               ; STORED_CHAR (stored char)
        PLA
        PHA
        STA ($D1),Y             ; SCREEN_PTR (screen line ptr lo)
        JSR sub_1C01
        STA ($F3),Y             ; COLOR_PTR (color RAM ptr lo)
        LDX $034C               ; CURSOR_MAP_Y (cursor Y on map)
        JSR sub_0F82
        PLA
        STA ($B4),Y             ; MAP_PTR (map data ptr lo)

L09F1:
        RTS

sub_09F2:
        JSR sub_0A70
        BEQ L09F1
        JSR sub_1F1C
        JSR sub_1F77
        LDA ($D1),Y             ; SCREEN_PTR (screen line ptr lo)
        PHA
        LDA $0352               ; STORED_CHAR (stored char)
        STA ($D1),Y             ; SCREEN_PTR (screen line ptr lo)
        PHA
        JSR sub_1C01
        STA ($F3),Y             ; COLOR_PTR (color RAM ptr lo)
        LDX $034C               ; CURSOR_MAP_Y (cursor Y on map)
        JSR sub_0F82
        PLA
        STA ($B4),Y             ; MAP_PTR (map data ptr lo)
        LDA $0350               ; STORED_PTR (F9/FA backup lo)
        STA $F9                 ; TEMP_PTR2 (general ptr lo)
        LDA $0351               ; STORED_PTR (F9/FA backup hi)
        STA $FA                 ; TEMP_PTR2 (general ptr hi)
        LDY #$00
        LDX $034B               ; CURSOR_MAP_X (cursor X on map)
        DEX
        TXA
        STA ($F9),Y             ; TEMP_PTR2 (general ptr lo)
        INY
        LDX $034C               ; CURSOR_MAP_Y (cursor Y on map)
        DEX
        TXA
        STA ($F9),Y             ; TEMP_PTR2 (general ptr lo)
        LDY #$05
        PLA
        STA ($F9),Y             ; TEMP_PTR2 (general ptr lo)
        LDA $0352               ; STORED_CHAR (stored char)
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
        LDA $0353               ; MOVE_FLAG (movement flag)
        BNE L0A62
        JSR sub_2013

L0A62:
        JMP sub_1EE2

L0A65:
        LDA $0353               ; MOVE_FLAG (movement flag)
        BEQ L0A62
        JSR sub_1CE2
        JMP sub_1EE2
