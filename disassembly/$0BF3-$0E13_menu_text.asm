; =============================================================================
; Menu System and Text Display
; Address range: $0BF3 - $0E13
; =============================================================================

; -----------------------------------------------------------------------------
; sub_0BF3 - Initialize Screen and Set VIC-II Colors
; -----------------------------------------------------------------------------
; Sets up the game's initial color scheme:
;   - VIC_EXTCOL ($D020): Border color = $06 (Blue)
;   - VIC_BGCOL0 ($D021): Background color = $00 (Black) - initial value
;
; NOTE: During map display, a raster interrupt in $0E14-$0FAB_sound_sprites.asm
; changes the background color to Green ($05) for the map area. This creates
; the green meadow background visible in gameplay.
;
; Individual character foreground colors are set per-tile via Color RAM
; ($D800-$DBE7) using the color mapping in sub_1C01 (utilities_render.asm).
;
; C64 Color Palette Reference:
;   $00=Black, $01=White, $02=Red, $03=Cyan, $04=Purple, $05=Green,
;   $06=Blue, $07=Yellow, $08=Orange, $09=Brown, $0A=Light Red,
;   $0B=Dark Gray, $0C=Gray, $0D=Light Green, $0E=Light Blue, $0F=Light Gray
; -----------------------------------------------------------------------------
sub_0BF3:
        JSR BASIC_CLRSCR        ; Clear screen
        LDA #$06                ; Blue
        STA VIC_EXTCOL          ; Set border color
        LDA #$00                ; Black
        STA VIC_BGCOL0          ; Set background color
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
        STA ($D1),Y             ; SCREEN_PTR (screen line ptr lo)
        LDA #$01
        STA ($F3),Y             ; COLOR_PTR (color RAM ptr lo)
        LDY #$27
        LDA #$67
        STA ($D1),Y             ; SCREEN_PTR (screen line ptr lo)
        LDA #$01
        STA ($F3),Y             ; COLOR_PTR (color RAM ptr lo)
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
        JSR $E9F0               ; KERNAL: Set cursor row
        JSR $EA24               ; KERNAL: Calculate screen pointer
        LDY #$26                ; Column counter (38 columns)

; -----------------------------------------------------------------------------
; L0C51 - Fill Screen with Varied Terrain (Self-Modifying Code)
; -----------------------------------------------------------------------------
; Creates visual variation in terrain by reading from BASIC header memory.
; INC $0C52 modifies the LDA operand to cycle through memory addresses.
; ANDing with $01 produces alternating 0/1, added to $69 gives $69/$6A.
; This creates a checkerboard-like pattern of Meadow/River tiles.
; -----------------------------------------------------------------------------
L0C51:
        LDA $0801               ; Read byte from BASIC header (address modified below)
        INC $0C52               ; Self-modify: increment address low byte ($0801→$0802→...)
        AND #$01                ; Mask to 0 or 1
        CLC
        ADC #$69                ; Result: $69 (Meadow) or $6A (River)
        STA ($D1),Y             ; SCREEN_PTR (screen line ptr lo)
        LDA #$0B                ; Dark Gray color
        STA ($F3),Y             ; COLOR_PTR (color RAM ptr lo)
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
        STY $0344               ; TEMP_STORE (temp storage lo)
        LDA $0CD3,Y

L0C92:
        STA $0286               ; CHARCOLOR (char color)
        INY
        LDA $0CD3,Y
        STA $D3                 ; CURSOR_COL (cursor column)
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
        STA $035D               ; MENU_SELECT (menu selection)
        JSR sub_2364
        JMP loc_0CCF

loc_0CCF:
        STA $035D               ; MENU_SELECT (menu selection)
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
        STA $0346               ; COUNTER (general counter)
        LDA #$02
        STA $0342               ; TEMP_CALC (temp calc lo)
        CLI
        RTS
        .byte $CE, $46, $03, $F0, $03, $4C, $31, $EA, $A9, $02, $8D, $46, $03, $AD, $01, $08  ; Nf...l1....f....
        .byte $EE, $D0, $0D, $29, $0F, $AA, $20, $22, $1B, $BD, $48, $E3, $A8, $20, $28, $1B  ; .P.).. "..h.. (.
        .byte $AD, $42, $03, $E9, $01, $D0, $02, $A9, $FF, $9D, $48, $E3, $8C, $42, $03, $EE  ; .b...P....h..b..
        .byte $43, $03, $CE, $44, $03, $AD, $43, $03, $CD, $44, $03, $90, $03, $AD, $44, $03  ; c.Nd..c.Md....d.
        .byte $8D, $16, $D4, $4A, $6A, $6A, $8D, $01, $D4, $8D, $08, $D4, $8D, $0F, $D4, $4C  ; ..Tjjj..T..T..Tl
        .byte $31, $EA  ; 1.
