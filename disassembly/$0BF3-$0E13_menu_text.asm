; =============================================================================
; Menu System and Text Display
; Address range: $0BF3 - $0E13
; =============================================================================
;
; This module handles the title screen display and menu system:
;   - sub_0BF3: Main title screen initialization
;     - Draws decorative border frame (characters $61-$68)
;     - Fills interior with checkered terrain pattern
;     - Displays title text and credits
;     - Waits for F1 (load game) or F3 (new game)
;   - title_text_data: PETSCII-encoded title text with color/position data
;   - sub_0DA3: Carriage return helper
;   - sub_0DAB: Title screen IRQ handler setup
;
; See docs/title_screen.md for full documentation.
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

; -----------------------------------------------------------------------------
; L0C02 - Draw Top and Bottom Border Lines
; -----------------------------------------------------------------------------
; Fills row 0 with char $66 and row 24 ($C320) with char $65
; Sets color to White ($01) for both rows
; Characters $65-$66 are horizontal border pieces from custom charset
; -----------------------------------------------------------------------------
L0C02:
        LDA #$66                ; Top border character
        STA $C000,X             ; Screen row 0
        LDA #$65                ; Bottom border character
        STA $C320,X             ; Screen row 24
        LDA #$01                ; White color
        STA COLOR_RAM,X         ; Color for row 0
        STA $DB20,X             ; Color for row 24
        DEX
        BPL L0C02

; -----------------------------------------------------------------------------
; L0C19 - Draw Left and Right Border Columns
; -----------------------------------------------------------------------------
; For each of 19 rows ($13), places vertical border characters:
;   Column 0: char $68 (left border)
;   Column 39 ($27): char $67 (right border)
; Uses KERNAL routines to calculate screen line pointers
; -----------------------------------------------------------------------------
        LDX #$13                ; 19 rows

L0C19:
        JSR $E9F0               ; KERNAL: Set cursor row (X = row number)
        JSR $EA24               ; KERNAL: Calculate screen pointer -> ($D1)
        LDA #$68                ; Left border character
        LDY #$00                ; Column 0
        STA ($D1),Y             ; SCREEN_PTR (screen line ptr lo)
        LDA #$01                ; White color
        STA ($F3),Y             ; COLOR_PTR (color RAM ptr lo)
        LDY #$27                ; Column 39
        LDA #$67                ; Right border character
        STA ($D1),Y             ; SCREEN_PTR (screen line ptr lo)
        LDA #$01                ; White color
        STA ($F3),Y             ; COLOR_PTR (color RAM ptr lo)
        DEX
        BNE L0C19

; -----------------------------------------------------------------------------
; Place Corner Characters
; -----------------------------------------------------------------------------
; Four corners use distinct characters $61-$64:
;   $61 = top-left ($C000)
;   $62 = top-right ($C027)
;   $63 = bottom-left ($C320)
;   $64 = bottom-right ($C347)
; -----------------------------------------------------------------------------
        LDX #$61                ; Top-left corner
        STX $C000
        INX                     ; $62 = top-right corner
        STX $C027
        INX                     ; $63 = bottom-left corner
        STX $C320
        INX                     ; $64 = bottom-right corner
        STX $C347

; -----------------------------------------------------------------------------
; L0C49 - Fill Interior with Checkered Terrain Pattern
; -----------------------------------------------------------------------------
; Fills 19 rows x 38 columns with alternating meadow tiles ($69/$6A)
; Creates visual texture for the title screen background
; -----------------------------------------------------------------------------
        LDX #$13                ; 19 rows

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

; -----------------------------------------------------------------------------
; L0C6A - Clear Status Line Area (Rows 21-24)
; -----------------------------------------------------------------------------
; Clears 4 rows at bottom of screen for status display
; X counts from $15 (21) to $18 (24)
; -----------------------------------------------------------------------------
        LDX #$15

L0C6A:
        JSR sub_1CFA            ; Clear row X
        INX
        CPX #$19                ; Until row 25
        BNE L0C6A

; -----------------------------------------------------------------------------
; Initialize Sound and Display Title Text
; -----------------------------------------------------------------------------
        JSR sub_0DAB            ; Set up title screen IRQ handler
        JSR sub_0DA3            ; Output carriage return
        JSR sub_209C            ; Additional sound setup
        LDA #$81
        JSR sub_20E7            ; Configure SID attack/decay
        LDA #$F7
        JSR sub_20F1            ; Configure SID sustain/release
        LDA #$81
        JSR sub_1CE4            ; Set SID voice control (triangle + gate)

; -----------------------------------------------------------------------------
; L0C92 - Title Text Display Loop
; -----------------------------------------------------------------------------
; Reads PETSCII text data from title_text_data ($0CD3) and displays it.
;
; Data format for each line:
;   Byte 0: Color code (stored in CHARCOLOR $0286)
;   Byte 1: Column position (stored in CURSOR_COL $D3)
;   Bytes 2+: Text characters until $5C (line terminator)
;
; Special codes:
;   $5C = End of line / carriage return
;   $5C $5C = End of all text data
;   $97 = Reverse video on
;   $A9 = Space in reverse video
; -----------------------------------------------------------------------------
        LDY #$00
        STY $0344               ; Clear temp storage
        LDA $0CD3,Y             ; Load first byte (color)

L0C92:
        STA $0286               ; CHARCOLOR - set text color
        INY
        LDA $0CD3,Y             ; Load column position
        STA $D3                 ; CURSOR_COL - set cursor column
        TYA
        PHA
        JSR $E56C               ; KERNAL: Move cursor to column
        PLA
        TAY

; -----------------------------------------------------------------------------
; loc_0CA2 - Output Characters Until Line Terminator
; -----------------------------------------------------------------------------
loc_0CA2:
        INY
        LDA $0CD3,Y             ; Load next character
        CMP #$5C                ; Is it line terminator?
        BEQ L0CB0               ; Yes: handle newline
        JSR CHROUT              ; No: output character
        JMP loc_0CA2            ; Continue with next character

; -----------------------------------------------------------------------------
; L0CB0 - Handle Line Terminator
; -----------------------------------------------------------------------------
L0CB0:
        JSR sub_0DA3            ; Output carriage return
        INY
        LDA $0CD3,Y             ; Check next byte
        CMP #$5C                ; Another $5C = end of text
        BNE L0C92               ; No: process next line

; -----------------------------------------------------------------------------
; L0CBB - Menu Input Loop
; -----------------------------------------------------------------------------
; Waits for user to press F1 or F3:
;   F1 ($85): Load saved game - calls sub_2364 (disk I/O)
;   F3 ($86): Start new game - continues to game initialization
;
; Stores selection in MENU_SELECT ($035D) for later processing.
; -----------------------------------------------------------------------------
L0CBB:
        JSR GETIN               ; KERNAL: Read keyboard
        CMP #$86                ; F3 key?
        BEQ loc_0CCF            ; Yes: new game selected
        CMP #$85                ; F1 key?
        BNE L0CBB               ; No: keep polling
        STA $035D               ; Store F1 selection
        JSR sub_2364            ; Load saved game from disk
        JMP loc_0CCF

loc_0CCF:
        STA $035D               ; MENU_SELECT - store final selection
        RTS

; =============================================================================
; title_text_data - PETSCII Encoded Title Screen Text ($0CD3)
; =============================================================================
; Format: [color] [column] [text...] $5C (repeat) $5C $5C (end)
;
; Decoded content:
;   Yellow, col 11: "DIRK MEIER SCHRIEB:"
;   White, col 13:  "WELTENDAEMMERUNG"
;   Green, col 8:   "(C) 1987 MARKT UND TECHNIK"
;   Lt Blue, col 7: "EIN FANTASY-STRATEGIE-SPIEL"
;   Lt Blue, col 11: "FUER ZWEI FELDHERREN"
;   (blank line)
;   Purple, col 9:  "<F1> ALTES SPIEL LADEN"
;   Purple, col 8:  "<F3> NEUES SPIEL STARTEN"
;
; Control codes used:
;   $97 = RVS ON (reverse video)
;   $A9 = Shifted space
;   $9E, $9A, $9C, $1E = Color codes embedded in text
;   $5C = Line terminator
; =============================================================================
title_text_data:
        .byte $07, $0B, $44, $49, $52, $4B, $97, $A9, $9E, $4D, $45, $49, $45, $52, $97, $A9  ; Yellow,11: "DIRK MEIER"
        .byte $9E, $53, $43, $48, $52, $49, $45, $42, $3A, $5C, $01, $0D, $57, $45, $4C, $54  ; "SCHRIEB:" \ White,13: "WELT"
        .byte $45, $4E, $44, $DF, $4D, $4D, $45, $52, $55, $4E, $47, $5C, $05, $08, $28, $43  ; "ENDAEMMERUNG" \ Green,8: "(C"
        .byte $29, $97, $A9, $1E, $31, $39, $38, $37, $97, $A9, $1E, $4D, $41, $52, $4B, $54  ; ") 1987 MARKT"
        .byte $97, $A9, $1E, $55, $4E, $44, $97, $A9, $1E, $54, $45, $43, $48, $4E, $49, $4B  ; " UND TECHNIK"
        .byte $97, $5C, $0E, $07, $45, $49, $4E, $97, $A9, $9A, $46, $41, $4E, $54, $41, $53  ; \ LtBlue,7: "EIN FANTAS"
        .byte $59, $2D, $53, $54, $52, $41, $54, $45, $47, $49, $45, $2D, $53, $50, $49, $45  ; "Y-STRATEGIE-SPIE"
        .byte $4C, $5C, $0E, $0B, $46, $FF, $52, $97, $A9, $9A, $5A, $57, $45, $49, $97, $A9  ; "L" \ LtBlue,11: "FUER ZWEI"
        .byte $9A, $46, $45, $4C, $44, $48, $45, $52, $52, $45, $4E, $5C, $00, $00, $5C, $04  ; " FELDHERREN" \ blank \ Purple
        .byte $09, $3C, $46, $31, $3E, $97, $A9, $9C, $41, $4C, $54, $45, $53, $97, $A9, $9C  ; ,9: "<F1> ALTES"
        .byte $53, $50, $49, $45, $4C, $97, $A9, $9C, $4C, $41, $44, $45, $4E, $5C, $04, $08  ; " SPIEL LADEN" \ Purple,8
        .byte $3C, $46, $33, $3E, $97, $A9, $9C, $4E, $45, $55, $45, $53, $97, $A9, $9C, $53  ; : "<F3> NEUES S"
        .byte $50, $49, $45, $4C, $97, $A9, $9C, $53, $54, $41, $52, $54, $45, $4E, $5C, $5C  ; "PIEL STARTEN" \ end

; -----------------------------------------------------------------------------
; sub_0DA3 - Output Double Carriage Return
; -----------------------------------------------------------------------------
; Outputs two carriage return characters ($0D) for line spacing.
; -----------------------------------------------------------------------------
sub_0DA3:
        LDA #$0D                ; Carriage return
        JSR CHROUT              ; Output first CR
        JMP CHROUT              ; Output second CR (tail call)

; -----------------------------------------------------------------------------
; sub_0DAB - Set Up Title Screen IRQ Handler
; -----------------------------------------------------------------------------
; Installs custom IRQ vector pointing to $0DC2 for title screen animation.
; The handler at $0DC2 (in raw data below) creates visual effects during
; the title display by modifying SID frequencies based on timing.
; -----------------------------------------------------------------------------
sub_0DAB:
        SEI                     ; Disable interrupts
        LDA #$C2
        STA IRQ_VECTOR_LO       ; IRQ vector low byte -> $C2
        LDA #$0D
        STA IRQ_VECTOR_HI       ; IRQ vector high byte -> $0D (=$0DC2)
        LDA #$02
        STA $0346               ; IRQ timing counter
        LDA #$02
        STA $0342               ; Animation state
        CLI                     ; Re-enable interrupts
        RTS

; -----------------------------------------------------------------------------
; IRQ Handler Code (raw bytes at $0DC2)
; -----------------------------------------------------------------------------
; This interrupt handler creates title screen sound/animation effects.
; Disassembled:
;   $0DC2: DEC $0346      ; Decrement counter
;          BEQ +3         ; If zero, continue
;          JMP $EA31      ; Otherwise, exit to KERNAL IRQ
;          LDA #$02
;          STA $0346      ; Reset counter
;          ... (SID manipulation for sound effects)
; -----------------------------------------------------------------------------
        .byte $CE, $46, $03, $F0, $03, $4C, $31, $EA, $A9, $02, $8D, $46, $03, $AD, $01, $08  ; DEC $0346; BEQ +3; JMP $EA31...
        .byte $EE, $D0, $0D, $29, $0F, $AA, $20, $22, $1B, $BD, $48, $E3, $A8, $20, $28, $1B  ; INC; AND #$0F; TAX; JSR...
        .byte $AD, $42, $03, $E9, $01, $D0, $02, $A9, $FF, $9D, $48, $E3, $8C, $42, $03, $EE  ; LDA $0342; SBC #$01...
        .byte $43, $03, $CE, $44, $03, $AD, $43, $03, $CD, $44, $03, $90, $03, $AD, $44, $03  ; ...frequency manipulation...
        .byte $8D, $16, $D4, $4A, $6A, $6A, $8D, $01, $D4, $8D, $08, $D4, $8D, $0F, $D4, $4C  ; STA SID regs; JMP $EA31
        .byte $31, $EA  ; JMP $EA31 (exit to KERNAL)
