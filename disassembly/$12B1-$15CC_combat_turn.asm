; =============================================================================
; Combat System and Turn Management
; Address range: $12B1 - $15CC
; =============================================================================

sub_12B1:
        JSR sub_12D4
        BCC L12D3

loc_12B6:
        LDA VIC_SP0COL
        EOR #$01
        STA VIC_SP0COL
        BEQ L12D3

sub_12C0:
        LDX $034F               ; ACTION_UNIT (unit in action)
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
        LDX $034F               ; ACTION_UNIT (unit in action)
        LDA $0347               ; CURRENT_PLAYER (active player)

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
        LDA ($F9),Y             ; TEMP_PTR2 (general ptr lo)
        BEQ L1327
        LDA #$0A
        STA VIC_SP0COL
        LDA $034B               ; CURSOR_MAP_Y (cursor Y on map)
        STA $0355               ; ATTACK_SRC_Y (attack source Y)
        LDA $034C               ; CURSOR_MAP_X (cursor X on map)
        STA $0356               ; ATTACK_SRC_X (attack source X)
        LDA $F9                 ; TEMP_PTR2 (general ptr lo)
        STA $0358               ; ATTACKER_PTR (attacker data ptr lo)
        LDA $FA                 ; TEMP_PTR2 (general ptr hi)
        STA $0359               ; ATTACKER_PTR (attacker data ptr hi)
        LDA $034F               ; ACTION_UNIT (unit in action)
        SEC
        SBC #$0B
        STA $0357               ; ATTACKER_TYPE (attacker type)

L1327:
        RTS

L1328:
        JSR sub_13AE
        LDX $034F               ; ACTION_UNIT (unit in action)
        LDA $0357               ; ATTACKER_TYPE (attacker type)
        CMP #$08
        BEQ L134C
        CMP #$0C
        BEQ L134C
        CMP #$0D
        BEQ L1350

L133D:
        LDA $0347               ; CURRENT_PLAYER (active player)
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
        LDA $034B               ; CURSOR_MAP_Y (cursor Y on map)
        CMP #$3C
        BCS L1349
        JSR sub_0F8C
        DEC $4FF2,X             ; GATE_FLAGS (gate/build location flags)

L1361:
        LDA $0357               ; ATTACKER_TYPE (attacker type)
        JSR sub_15AC
        JSR sub_2263
        JSR sub_1445
        LDA #$71
        PHA
        JMP loc_140E

L1373:
        LDA $0357               ; ATTACKER_TYPE (attacker type)
        JSR sub_15AC
        LDA $034F               ; ACTION_UNIT (unit in action)
        SEC
        SBC #$0B
        JSR sub_15AC
        JSR sub_1445
        LDX $0357               ; ATTACKER_TYPE (attacker type)
        LDA $1047,X
        JSR sub_1567
        STA $035C               ; SAVE_LETTER (save filename)
        JSR sub_1FF6            ; Find defender's unit record
        LDY #$02
        LDA ($F9),Y             ; Load unit[2] = defender's defense (V)
        SED                     ; Enable decimal mode for damage calc
        SEC
        SBC $035C               ; BCD subtract: defense = defense - attack damage
        CLD                     ; Disable decimal mode
        BEQ L13FD               ; If result = 0, unit destroyed
        CMP #$5A                ; Check for underflow (BCD: $5A = negative)
        BCS L13FD               ; If underflow, unit destroyed
        STA ($F9),Y             ; Store reduced defense back to unit[2]

loc_13A6:
        LDA #$01
        STA VIC_SP0COL
        JMP sub_1EE2

sub_13AE:
        LDA $0355               ; ATTACK_SRC_Y (attack source Y)
        SEC
        SBC $034B               ; CURSOR_MAP_Y (cursor Y on map)
        JSR $BC3C
        JSR $BC0C
        LDA $61                 ; FAC_MANTISSA (math calc)
        JSR $BA2B
        JSR $BBCA
        LDA $0356               ; ATTACK_SRC_X (attack source X)
        SEC
        SBC $034C               ; CURSOR_MAP_X (cursor X on map)
        JSR $BC3C
        JSR $BC0C
        LDA $61                 ; FAC_MANTISSA (math calc)
        JSR $BA2B
        LDA #$57
        LDY #$00
        JSR $BA8C
        LDA $61                 ; FAC_MANTISSA (math calc)
        JSR $B86A
        JSR $BF71
        JSR $BC9B
        LDX $0357               ; ATTACKER_TYPE (attacker type)
        LDA $1027,X
        CMP #$12
        BNE L13F3
        LDA #$0C

L13F3:
        CMP $65                 ; ARG_MANTISSA (math calc)
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
        STA ($F9),Y             ; TEMP_PTR2 (general ptr lo)
        LDY #$05
        LDA ($F9),Y             ; TEMP_PTR2 (general ptr lo)
        PHA
        JSR sub_2197

loc_140E:
        JSR sub_1F1C
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
        LDX $0347               ; CURRENT_PLAYER (active player)
        LDA $034F               ; ACTION_UNIT (unit in action)
        CMP #$11
        BEQ loc_1456
        LDA $0347               ; CURRENT_PLAYER (active player)
        BNE L1442
        DEC $4FF0               ; ELDOIN_UNITS (Eldoin unit count)
        BNE L1442
        LDA #$01
        STA $034F               ; ACTION_UNIT (unit in action)
        JMP loc_1456

L1442:
        JMP loc_13A6

sub_1445:
        LDA $0358               ; ATTACKER_PTR (attacker data ptr lo)
        STA $F9                 ; TEMP_PTR2 (general ptr lo)
        LDA $0359               ; ATTACKER_PTR (attacker data ptr hi)
        STA $FA                 ; TEMP_PTR2 (general ptr hi)
        LDY #$03
        LDA #$00
        STA ($F9),Y             ; TEMP_PTR2 (general ptr lo)
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
        LDA $034F               ; ACTION_UNIT (unit in action)
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

; -----------------------------------------------------------------------------
; sub_1567 - Add Combat Modifier from ROM Sequence
; -----------------------------------------------------------------------------
; Adds a modifier (0-4) to attack value using BCD arithmetic.
; Uses self-modifying code to read successive bytes from KERNAL ROM ($E000+),
; creating a deterministic but varied sequence.
; Input: A = base attack value
; Output: A = attack value + modifier (BCD)
; -----------------------------------------------------------------------------
sub_1567:
        PHA
        LDA $E000               ; Read byte from KERNAL ROM (address modified below)
        AND #$07                ; Mask to 0-7 for table index
        INC $1569               ; Self-modify: increment address low byte ($E000→$E001→...)
        TAX                     ; X = index into modifier table
        PLA                     ; Restore attack value
        CLC
        SED                     ; Enable decimal mode
        ADC $1579,X             ; BCD add: attack = attack + modifier
        CLD                     ; Disable decimal mode
        RTS
; Modifier table indexed by (ROM byte & 7): values 0,1,1,2,2,3,3,4
        .byte $00, $01, $01, $02, $02, $03, $03, $04

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
        STA $F9                 ; TEMP_PTR2 (general ptr lo)
        LDA #$5F
        STA $FA                 ; TEMP_PTR2 (general ptr hi)
        LDY #$00
        RTS
