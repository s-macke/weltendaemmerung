; =============================================================================
; Movement Validation and Combat Logic
; Address range: $0A70 - $0BF2
; =============================================================================

sub_0A70:
        LDA $034A               ; GAME_STATE (game phase)
        CMP #$01
        BEQ L0A80
        CMP #$02
        BEQ L0A80
        LDA VIC_SP0COL
        CMP #$F1

L0A80:
        RTS

L0A81:
        LDA $0353               ; MOVE_FLAG (movement flag)
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
        LDA $0353               ; MOVE_FLAG (movement flag)
        BEQ L0A62
        LDA #$20
        JSR sub_1CE4
        JMP sub_1EE2

sub_0AA3:
        JSR sub_0A70

L0AA6:
        BEQ L0A80
        LDX $034C               ; CURSOR_MAP_X (cursor X on map)
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
        LDX $034C               ; CURSOR_MAP_X (cursor X on map)
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
        LDX $034C               ; CURSOR_MAP_X (cursor X on map)
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
        LDX $034C               ; CURSOR_MAP_X (cursor X on map)
        INX
        JSR sub_0F82
        JSR sub_0B10
        BCC L0B01
        PLA
        PLA
        JMP loc_0985

; -----------------------------------------------------------------------------
; L0B01 - Deduct Movement Points from Unit
; -----------------------------------------------------------------------------
; Loads current movement (unit[3]), subtracts terrain cost via sub_0B82,
; stores result back. Uses decimal mode so SBC operates in BCD.
; -----------------------------------------------------------------------------
L0B01:
        JSR sub_1FF6            ; Find unit record at cursor
        LDY #$03
        LDA ($F9),Y             ; Load unit[3] = current movement points
        SED                     ; Enable decimal mode (affects SBC in sub_0B82)
        JSR sub_0B82            ; Subtract movement cost - SBC uses BCD arithmetic
        STA ($F9),Y             ; Store updated movement points
        CLD                     ; Disable decimal mode
        RTS

sub_0B10:
        LDA ($B4),Y             ; MAP_PTR (map data ptr lo)
        LDX $034F               ; ACTION_UNIT (unit in action)
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
        STA $0353               ; MOVE_FLAG (movement flag)
        SEC
        RTS

L0B59:
        STA $0353               ; MOVE_FLAG (movement flag)
        CMP #$6B
        BNE L0B52
        LDX #$00
        STX $0353               ; MOVE_FLAG (movement flag)
        JSR sub_204C
        CLC
        RTS

L0B6A:
        STA $0353               ; MOVE_FLAG (movement flag)
        CMP #$74
        BCS L0B52

L0B71:
        LDX #$00
        STX $0353               ; MOVE_FLAG (movement flag)
        CLC
        RTS

L0B78:
        LDX #$00
        STX $0353               ; MOVE_FLAG (movement flag)
        JSR sub_209C
        CLC
        RTS

; -----------------------------------------------------------------------------
; sub_0B82 - Calculate and Subtract Movement Cost
; -----------------------------------------------------------------------------
; Called with decimal mode ON. Determines movement cost based on terrain
; under unit, then subtracts from current movement points using BCD SBC.
; Input: A = current movement points (on stack after PHA)
; Output: A = movement points after terrain cost subtracted (BCD)
; -----------------------------------------------------------------------------
sub_0B82:
        PHA                     ; Save current movement points
        LDY #$05
        LDA ($F9),Y             ; Load unit[5] = terrain under unit
        TAY                     ; Y = terrain type
        LDA $034F               ; Load unit tile code on map
        CLD                     ; Disable decimal mode for binary arithmetic
        SEC
        SBC #$0B                ; Convert tile to unit type index (binary SBC)
        SED                     ; Re-enable decimal mode for movement calc
        TAX                     ; X = unit type index
        TYA                     ; A = terrain type
        LDY #$03
        CMP #$6B                ; Forest terrain?
        BEQ L0BA5
        CMP #$6C                ; Edge terrain?
        BEQ L0BAB
        CMP #$6E                ; Gate terrain?
        BEQ L0BB1
        PLA                     ; Default: cost = 1
        SEC
        SBC #$01                ; BCD subtract 1 movement point
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
        STA $0342               ; TEMP_CALC (temp calc lo)
        PLA
        SEC
        SBC $0342               ; TEMP_CALC (temp calc lo)
        CMP #$20
        BCC L0BC2
        LDA #$00

L0BC2:
        RTS
        .byte $04, $04, $01, $04, $01, $04, $04, $02, $04, $01, $02, $02, $04, $04, $05, $02  ; ................
        .byte $02, $02, $01, $03, $00, $04, $02, $02, $04, $01, $02, $02, $01, $03, $07, $02  ; ................
        .byte $03, $03, $01, $03, $00, $04, $03, $03, $04, $01, $03, $03, $01, $04, $07, $04  ; ................
