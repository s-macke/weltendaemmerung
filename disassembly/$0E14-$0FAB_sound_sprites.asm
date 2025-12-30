; =============================================================================
; Sound Initialization and Sprite Handling
; Address range: $0E14 - $0FAB
; =============================================================================

sub_0E14:
        LDA #$4F
        STA SID_VOLUME
        LDA #$F3
        STA SID_RESFLT
        LDX #$01
        STX $0343               ; TEMP_CALC (temp calc hi)
        DEX
        STX $0344               ; TEMP_STORE (temp storage lo)
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
        LDA $034A               ; GAME_STATE (game phase)
        CMP #$02
        BNE L0EF6
        LDX $034B               ; CURSOR_MAP_Y (cursor Y on map)
        LDA $0347               ; CURRENT_PLAYER (active player)
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
        LDA $034A               ; GAME_STATE (game phase)
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
        STA $034E               ; UNIT_TYPE_IDX (unit type index)
        JSR sub_0F8C
        JSR sub_1F1C

loc_0F11:
        CMP #$06
        BEQ L0F4E
        CMP #$0B
        BCC L0F2B
        STA $034E               ; UNIT_TYPE_IDX (unit type index)
        JSR sub_1FF6
        LDY #$05
        LDA ($F9),Y             ; TEMP_PTR2 (general ptr lo)
        TAX
        TXA
        SEC
        SBC #$69
        JMP loc_0F11

L0F2B:
        LDA #$6F

loc_0F2D:
        PHA
        LDX $034E               ; UNIT_TYPE_IDX (unit type index)
        BNE L0F77
        JSR sub_1F77
        PLA
        PHA
        STA ($D1),Y             ; SCREEN_PTR (screen line ptr lo)
        JSR sub_1C01
        STA ($F3),Y             ; COLOR_PTR (color RAM ptr lo)
        LDX $034C               ; CURSOR_MAP_X (cursor X on map)
        JSR sub_0F82
        PLA
        STA ($B4),Y             ; MAP_PTR (map data ptr lo)
        JSR sub_1F82
        JMP sub_1EE2

L0F4E:
        LDA $0347               ; CURRENT_PLAYER (active player)
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
        STA ($F9),Y             ; TEMP_PTR2 (general ptr lo)
        JMP sub_1F82

sub_0F82:
        DEX
        TXA
        JSR sub_1AD3
        LDY $034B               ; CURSOR_MAP_Y (cursor Y on map)
        DEY
        RTS

sub_0F8C:
        LDX #$0C

L0F8E:
        LDA $034B               ; CURSOR_MAP_Y (cursor Y on map)
        CMP $0F5D,X
        BNE L0F9E
        LDA $034C               ; CURSOR_MAP_X (cursor X on map)
        CMP $0F6A,X
        BEQ L0FA1

L0F9E:
        DEX
        BPL L0F8E

L0FA1:
        BMI L0FA9
        LDA $4FF2,X             ; TOWN_FLAGS (town capture flags)
        BMI L0FA9
        RTS

L0FA9:
        PLA
        PLA
        RTS
