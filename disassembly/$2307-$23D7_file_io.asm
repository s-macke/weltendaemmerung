; =============================================================================
; File I/O - Save/Load Game
; Address range: $2307 - $23D7
; =============================================================================

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
        STA $F8                 ; TEMP_PTR1 (general ptr hi)
        LDA #$F0
        STA $F7                 ; TEMP_PTR1 (general ptr lo)
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
        STA $035C               ; SAVE_LETTER (save filename)
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
        LDX $D6                 ; CURSOR_ROW (cursor row)
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
        LDX $034B               ; CURSOR_MAP_X (cursor X on map)
        DEX
        BNE L23C2
        LDA $034F               ; ACTION_UNIT (unit in action)
        CMP #$12
        BCC L23C2
        LDA #$11
        STA $034F               ; ACTION_UNIT (unit in action)
        JMP loc_1456
