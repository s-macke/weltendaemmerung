; =============================================================================
; Utilities, Rendering, and Music
; Address range: $1A3F - $1E8A
; =============================================================================
;
; This module provides core rendering utilities for map scrolling, terrain
; color lookup, sprite cursor control, sound effects, and delay routines.
;
; KEY FUNCTIONS USED BY COMBAT SYSTEM:
;   sub_1C01 - Get terrain/unit color for display
;   sub_1CE2 - Set SID voices to noise waveform (unit animation sound)
;   sub_1CF3 - Delay loop (used for timing in combat animations)
;
; =============================================================================

; -----------------------------------------------------------------------------
; sub_1A3F - Scroll Screen Left (Shift Characters Right)
; -----------------------------------------------------------------------------
; Scrolls the visible map area left by shifting all characters one position
; to the right. Used when player moves cursor past left edge.
; Processes 19 rows ($13), columns 2-38.
; -----------------------------------------------------------------------------
sub_1A3F:
        LDX #$13

L1A41:
        JSR $E9F0
        JSR $EA24
        LDY #$02

L1A49:
        LDA ($D1),Y             ; SCREEN_PTR (screen line ptr lo)
        DEY
        STA ($D1),Y             ; SCREEN_PTR (screen line ptr lo)
        INY
        LDA ($F3),Y             ; COLOR_PTR (color RAM ptr lo)
        DEY
        STA ($F3),Y             ; COLOR_PTR (color RAM ptr lo)
        INY
        INY
        CPY #$27
        BNE L1A49
        DEX
        BNE L1A41
        RTS

; -----------------------------------------------------------------------------
; sub_1A5E - Scroll Screen Right (Shift Characters Left)
; -----------------------------------------------------------------------------
; Scrolls the visible map area right by shifting all characters one position
; to the left. Used when player moves cursor past right edge.
; -----------------------------------------------------------------------------
sub_1A5E:
        LDX #$13

L1A60:
        JSR $E9F0
        JSR $EA24
        LDY #$25

L1A68:
        LDA ($D1),Y             ; SCREEN_PTR (screen line ptr lo)
        INY
        STA ($D1),Y             ; SCREEN_PTR (screen line ptr lo)
        DEY
        LDA ($F3),Y             ; COLOR_PTR (color RAM ptr lo)
        INY
        STA ($F3),Y             ; COLOR_PTR (color RAM ptr lo)
        DEY
        DEY
        BNE L1A68
        DEX
        BNE L1A60
        RTS

; -----------------------------------------------------------------------------
; sub_1A7B - Scroll Screen Down (Shift Characters Up)
; -----------------------------------------------------------------------------
; Scrolls the visible map area down by shifting rows upward.
; Used when player moves cursor past bottom edge.
; -----------------------------------------------------------------------------
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

; -----------------------------------------------------------------------------
; sub_1A9A - Save Screen/Color Pointers to Temp
; -----------------------------------------------------------------------------
; Copies KERNAL screen ($D1-$D2) and color ($F3-$F4) pointers to temp
; storage ($F7-$F8 and $F9-$FA) for row copy operations.
; -----------------------------------------------------------------------------
sub_1A9A:
        LDA $D1                 ; SCREEN_PTR (screen line ptr lo)
        STA $F7                 ; TEMP_PTR1 (general ptr lo)
        LDA $D2                 ; SCREEN_PTR (screen line ptr hi)
        STA $F8                 ; TEMP_PTR1 (general ptr hi)
        LDA $F3                 ; COLOR_PTR (color RAM ptr lo)
        STA $F9                 ; TEMP_PTR2 (general ptr lo)
        LDA $F4                 ; COLOR_PTR (color RAM ptr hi)
        STA $FA                 ; TEMP_PTR2 (general ptr hi)
        RTS

; -----------------------------------------------------------------------------
; sub_1AAB - Copy Screen Character and Color
; -----------------------------------------------------------------------------
; Copies character and color at offset Y from source to destination pointers.
; Used during screen scrolling operations.
; -----------------------------------------------------------------------------
sub_1AAB:
        LDA ($D1),Y             ; SCREEN_PTR (screen line ptr lo)
        STA ($F7),Y             ; TEMP_PTR1 (general ptr lo)
        LDA ($F3),Y             ; COLOR_PTR (color RAM ptr lo)
        STA ($F9),Y             ; TEMP_PTR2 (general ptr lo)
        RTS

; -----------------------------------------------------------------------------
; sub_1AB4 - Scroll Screen Up (Shift Characters Down)
; -----------------------------------------------------------------------------
; Scrolls the visible map area up by shifting rows downward.
; Used when player moves cursor past top edge.
; -----------------------------------------------------------------------------
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

; -----------------------------------------------------------------------------
; sub_1AD3 - Calculate Map Data Pointer for Row
; -----------------------------------------------------------------------------
; Calculates the pointer to map data for a given Y coordinate (row).
; Map data is stored at $5000 with 80 ($50) bytes per row.
;
; Formula: MAP_PTR = $5000 + (Y * 80)
;
; Input:  A = Y coordinate (map row 0-39)
; Output: $B4-$B5 = pointer to start of that row in map data
; -----------------------------------------------------------------------------
sub_1AD3:
        STA $0346               ; SCRATCH_VAR (general counter)
        STA $B4                 ; MAP_PTR (map data ptr lo)
        LDA #$00
        STA $B5                 ; MAP_PTR (map data ptr hi)
        ASL $B4                 ; MAP_PTR (map data ptr lo)
        ROL $B5                 ; MAP_PTR (map data ptr hi)
        ASL $B4                 ; MAP_PTR (map data ptr lo)
        ROL $B5                 ; MAP_PTR (map data ptr hi)
        ASL $B4                 ; MAP_PTR (map data ptr lo)
        ROL $B5                 ; MAP_PTR (map data ptr hi)
        LDA $B4                 ; MAP_PTR (map data ptr lo)
        STA $0342               ; TEMP_CALC (temp calc lo)
        LDA $B5                 ; MAP_PTR (map data ptr hi)
        STA $0343               ; TEMP_CALC (temp calc hi)
        LDA $0346               ; SCRATCH_VAR (general counter)
        STA $B4                 ; MAP_PTR (map data ptr lo)
        LDA #$00
        STA $B5                 ; MAP_PTR (map data ptr hi)
        ASL $B4                 ; MAP_PTR (map data ptr lo)
        ROL $B5                 ; MAP_PTR (map data ptr hi)
        CLC
        LDA $B4                 ; MAP_PTR (map data ptr lo)
        ADC $0342               ; TEMP_CALC (temp calc lo)
        STA $B4                 ; MAP_PTR (map data ptr lo)
        LDA $B5                 ; MAP_PTR (map data ptr hi)
        ADC $0343               ; TEMP_CALC (temp calc hi)
        STA $B5                 ; MAP_PTR (map data ptr hi)
        ASL $B4                 ; MAP_PTR (map data ptr lo)
        ROL $B5                 ; MAP_PTR (map data ptr hi)
        ASL $B4                 ; MAP_PTR (map data ptr lo)
        ROL $B5                 ; MAP_PTR (map data ptr hi)
        ASL $B4                 ; MAP_PTR (map data ptr lo)
        ROL $B5                 ; MAP_PTR (map data ptr hi)
        CLC
        LDA $B5                 ; MAP_PTR (map data ptr hi)
        ADC #$50                ; Add $50 for base address $5000
        STA $B5                 ; MAP_PTR hi = $50 + overflow
        RTS

; -----------------------------------------------------------------------------
; sub_1B22 - Disable BASIC/KERNAL ROMs (Bank Out)
; -----------------------------------------------------------------------------
; Switches CPU memory configuration to see RAM at $A000-$BFFF and $E000-$FFFF
; instead of BASIC and KERNAL ROMs. Disables interrupts during this time.
; Used to access the copied character ROM or other data in RAM.
; -----------------------------------------------------------------------------
sub_1B22:
        SEI                     ; Disable interrupts
        LDA #$31                ; Bit pattern: RAM visible at $A000 and $E000
        STA $01                 ; CPU_PORT (memory config)
        RTS

; -----------------------------------------------------------------------------
; sub_1B28 - Enable BASIC/KERNAL ROMs (Bank In)
; -----------------------------------------------------------------------------
; Restores normal memory configuration with BASIC and KERNAL ROMs visible.
; Re-enables interrupts.
; -----------------------------------------------------------------------------
sub_1B28:
        LDA #$37                ; Bit pattern: Normal ROM configuration
        STA $01                 ; CPU_PORT (memory config)
        CLI                     ; Re-enable interrupts
        RTS

loc_1B2E:
        LDA $0341               ; SCROLL_Y (map scroll Y)
        JSR sub_1AD3
        LDX #$01

loc_1B36:
        JSR $E9F0
        JSR $EA24
        LDA #$01
        STA $0343               ; TEMP_CALC (temp calc hi)
        LDY $0340               ; SCROLL_X (map scroll X)
        STY $0342               ; TEMP_CALC (temp calc lo)

L1B47:
        LDY $0342               ; TEMP_CALC (temp calc lo)
        LDA ($B4),Y             ; MAP_PTR (map data ptr lo)
        LDY $0343               ; TEMP_CALC (temp calc hi)
        STA ($D1),Y             ; SCREEN_PTR (screen line ptr lo)
        JSR sub_1C01
        STA ($F3),Y             ; COLOR_PTR (color RAM ptr lo)
        INC $0342               ; TEMP_CALC (temp calc lo)
        INC $0343               ; TEMP_CALC (temp calc hi)
        LDA $0343               ; TEMP_CALC (temp calc hi)
        CMP #$27
        BNE L1B47
        RTS

sub_1B64:
        LDA $0341               ; SCROLL_Y (map scroll Y)
        CLC
        ADC #$12
        JSR sub_1AD3
        LDX #$13
        JMP loc_1B36

loc_1B72:
        LDA $0340               ; SCROLL_X (map scroll X)
        STA $0344               ; TEMP_STORE (temp storage lo)
        LDA #$01
        STA $0345               ; TEMP_STORE (temp storage hi)

loc_1B7D:
        LDA $0341               ; SCROLL_Y (map scroll Y)
        JSR sub_1AD3
        LDX #$01

L1B85:
        JSR $E9F0
        JSR $EA24
        LDY $0344               ; TEMP_STORE (temp storage lo)
        LDA ($B4),Y             ; MAP_PTR (map data ptr lo)
        LDY $0345               ; TEMP_STORE (temp storage hi)
        STA ($D1),Y             ; SCREEN_PTR (screen line ptr lo)
        JSR sub_1C01
        STA ($F3),Y             ; COLOR_PTR (color RAM ptr lo)
        LDA $B4                 ; MAP_PTR (map data ptr lo)
        CLC
        ADC #$50
        STA $B4                 ; MAP_PTR (map data ptr lo)
        LDA $B5                 ; MAP_PTR (map data ptr hi)
        ADC #$00
        STA $B5                 ; MAP_PTR (map data ptr hi)
        INX
        CPX #$14
        BNE L1B85
        RTS

loc_1BAD:
        LDA $0340               ; SCROLL_X (map scroll X)
        CLC
        ADC #$25
        STA $0344               ; TEMP_STORE (temp storage lo)
        LDA #$26
        STA $0345               ; TEMP_STORE (temp storage hi)
        JMP loc_1B7D

sub_1BBE:
        LDA $0340               ; SCROLL_X (map scroll X)
        BEQ L1BEA
        JSR sub_1A5E
        DEC $0340               ; SCROLL_X (map scroll X)
        JMP loc_1B72

sub_1BCC:
        LDA $0340               ; SCROLL_X (map scroll X)
        CMP #$2A
        BEQ L1BEA
        JSR sub_1A3F
        INC $0340               ; SCROLL_X (map scroll X)
        JMP loc_1BAD

sub_1BDC:
        LDA $0341               ; SCROLL_Y (map scroll Y)
        BEQ L1BEA
        JSR sub_1AB4
        DEC $0341               ; SCROLL_Y (map scroll Y)
        JMP loc_1B2E

L1BEA:
        LDA #$01
        STA $0353               ; MOVE_FLAG (movement flag)
        RTS

sub_1BF0:
        LDA $0341               ; SCROLL_Y (map scroll Y)
        CMP #$15
        BEQ L1BEA
        JSR sub_1A7B
        INC $0341               ; SCROLL_Y (map scroll Y)
        JSR sub_1B64
        RTS

; -----------------------------------------------------------------------------
; sub_1C01 - Get Foreground Color for Character Code
; -----------------------------------------------------------------------------
; Input:  A = character code (tile index as used on screen)
; Output: A = C64 color code for foreground
; Preserves: X register
;
; COLOR MAPPING TABLE:
; -------------------
; Char Code Range     | Color Code | Color Name  | Used For
; --------------------|------------|-------------|------------------
; $00-$68 (0-104)     | $0B        | Dark Gray   | UI borders, frame
; $69     (105)       | $00        | Black       | Wiese (Meadow) var 1
; $6A     (106)       | $00        | Black       | Wiese (Meadow) var 2
; $6B     (107)       | $06        | Blue        | Fluss (River)
; $6C     (108)       | $02        | Red         | Wald (Forest)
; $6D     (109)       | $01        | White       | Ende (End-Marker)
; $6E     (110)       | $06        | Blue        | Sumpf (Swamp)
; $6F-$73 (111-115)   | $0B        | Dark Gray   | Tor/Gebirge/Pflaster/Mauer
; $74-$7A (116-122)   | $07        | Yellow      | Unit icons
; $7B+    (123+)      | $00        | Black       | Unit icons
;
; Background color: Green ($05) during map display (via raster interrupt in $0E14)
; -----------------------------------------------------------------------------
sub_1C01:
        STX $0346               ; Save X register
        CMP #$69                ; Check if < $69
        BCC L1C1F               ; Yes: use Dark Gray ($0B)
        CMP #$74                ; Check if < $74
        BCC L1C15               ; Yes: use lookup table ($69-$73)
        CMP #$7B                ; Check if < $7B
        BCC L1C25               ; Yes: use Yellow ($07)
        LDA #$00                ; >= $7B: use Black
        JMP loc_1C21

L1C15:                          ; Lookup table for $69-$73
        SEC
        SBC #$69                ; Convert to table index (0-10)
        TAX
        LDA $1C2A,X             ; Load color from lookup table
        JMP loc_1C21

L1C1F:                          ; Default for $00-$68
        LDA #$0B                ; Dark Gray

loc_1C21:
        LDX $0346               ; Restore X register
        RTS

L1C25:                          ; Yellow for $74-$7A
        LDA #$07                ; Yellow
        JMP loc_1C21

; Color lookup table for character codes $69-$73 (11 entries)
; Index: char_code - $69 -> color
; $69=Black, $6A=Black, $6B=Blue, $6C=Red, $6D=White, $6E=Blue, $6F-$73=Dark Gray
color_lookup_table:
        .byte $00, $00, $06, $02, $01, $06, $0B, $0B, $0B, $0B, $0B

; -----------------------------------------------------------------------------
; sub_1C35 - Initialize Cursor Sprite
; -----------------------------------------------------------------------------
; Sets up Sprite 0 as the game cursor:
;   - Copies sprite pattern data to VIC bank ($C400)
;   - Enables Sprite 0 only
;   - Sets initial color to white ($01 = Normal state)
;   - Positions sprite at center of map view
;   - Points sprite to pattern at $C400 (pointer = $10)
;
; The cursor sprite color is used as a state machine for combat:
;   $01 = Normal (white)
;   $0A = Attack Select (light green)
;   $FA = Attack Execute
;   $F1 = Movement mode
; -----------------------------------------------------------------------------
sub_1C35:
        LDX #$23                ; Copy 36 bytes of sprite data

L1C37:
        LDA $1C65,X             ; Source: sprite pattern at $1C65
        STA $C400,X             ; Dest: VIC sprite block at $C400
        DEX
        BPL L1C37
        LDX #$1C                ; Clear remaining sprite block

L1C42:
        LDA #$00
        STA $C423,X
        DEX
        BPL L1C42
        STA VIC_SPXMSB          ; Clear X MSB (all sprites X < 256)
        LDA #$01
        STA VIC_SPENA           ; Enable Sprite 0 only
        STA VIC_SP0COL          ; Set color to white (Normal state)
        LDA #$98
        STA VIC_SP0Y            ; Initial Y position
        LDA #$B6
        STA VIC_SP0X            ; Initial X position
        LDA #$10
        STA $C3F8               ; Sprite 0 pointer = $10 -> $C400
        RTS

; Cursor sprite pattern data (circle/ring shape, 36 bytes)
        .byte $1F, $80, $00, $3F, $C0, $00, $60, $60, $00, $C0, $30, $00, $C0, $30, $00, $C0
        .byte $30, $00, $C0, $30, $00, $C0, $30, $00, $C0, $30, $00, $60, $60, $00, $3F, $C0
        .byte $00, $1F, $80

; -----------------------------------------------------------------------------
; sub_1C88 - Victory Music (Scroll Up Effect)
; -----------------------------------------------------------------------------
; Plays ascending victory music while scrolling the screen upward.
; Used when Eldoin wins by eliminating all Dailor units.
; -----------------------------------------------------------------------------
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

; -----------------------------------------------------------------------------
; sub_1CBC - Defeat Music (Scroll Down Effect)
; -----------------------------------------------------------------------------
; Plays descending defeat music while scrolling the screen downward.
; Used when a player loses.
; -----------------------------------------------------------------------------
sub_1CBC:
        JSR sub_0E14            ; Initialize SID
        LDX #$4F
        STA SID_VOLUME          ; Set volume
        LDX #$13                ; 19 iterations

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

; -----------------------------------------------------------------------------
; sub_1CE2 - Set SID Voices to Noise Waveform
; -----------------------------------------------------------------------------
; Sets all three SID voices to noise waveform ($80) without gate.
; Used for unit idle animation sound effect - creates a brief noise burst.
; Called from attack system's sub_12C0 for unit animation.
; -----------------------------------------------------------------------------
sub_1CE2:
        LDA #$80                ; Noise waveform, gate off

; -----------------------------------------------------------------------------
; sub_1CE4 - Set SID Voice Control Registers
; -----------------------------------------------------------------------------
; Sets all three SID voice control registers to the value in A.
; Voice control bits: Noise=$80, Pulse=$40, Saw=$20, Triangle=$10, Gate=$01
;
; Input: A = voice control byte
; Common values used:
;   $80 = Noise waveform, gate off (idle sound)
;   $81 = Noise waveform, gate on (sustained sound)
;   $14 = Triangle waveform, gate off (phase transition)
;   $20 = Sawtooth waveform (used in music)
; -----------------------------------------------------------------------------
sub_1CE4:
        STA SID_V1CTRL          ; Voice 1 control
        STA SID_V2CTRL          ; Voice 2 control
        STA SID_V3CTRL          ; Voice 3 control
        RTS

; -----------------------------------------------------------------------------
; sub_1CEE - Set SID Voices to Noise with Gate On
; -----------------------------------------------------------------------------
; Sets all SID voices to noise waveform ($81) with gate on.
; Creates sustained noise sound.
; -----------------------------------------------------------------------------
sub_1CEE:
        LDA #$81                ; Noise waveform, gate on
        JMP sub_1CE4

; -----------------------------------------------------------------------------
; sub_1CF3 - Delay Loop
; -----------------------------------------------------------------------------
; Creates a delay by calling KERNAL scan keyboard routine multiple times.
; Uses self-decrementing Y register as iteration counter.
;
; Input: Y = number of iterations (decrements to 0)
; Called from: sub_1581 (combat animations), various sound routines
; -----------------------------------------------------------------------------
sub_1CF3:
        JSR $EEB3               ; KERNAL: Scan keyboard matrix
        DEY
        BNE sub_1CF3
        RTS

; -----------------------------------------------------------------------------
; sub_1CFA - Clear Screen Row
; -----------------------------------------------------------------------------
; Fills an entire screen row with spaces ($A0) in blue color ($06).
; Used to clear status/info lines before redrawing.
; -----------------------------------------------------------------------------
sub_1CFA:
        JSR $E9F0               ; KERNAL: Get screen line address
        JSR $EA24               ; KERNAL: Set color pointer
        LDY #$27                ; 40 characters (0-$27)

L1D02:
        LDA #$A0                ; Shifted space character
        STA ($D1),Y             ; SCREEN_PTR (screen line ptr lo)
        LDA #$06                ; Blue color
        STA ($F3),Y             ; COLOR_PTR (color RAM ptr lo)
        DEY
        BPL L1D02
        RTS

; -----------------------------------------------------------------------------
; sub_1D0E - Display Current Phase and Player
; -----------------------------------------------------------------------------
; Displays "[PLAYER] [PHASE]PHASE" on screen, e.g. "ELDOIN BEWEGUNGSPHASE"
; Uses lookup tables at $1D34 (player names) and $1D36 (phase names)
; -----------------------------------------------------------------------------
sub_1D0E:
        LDX #$16
        JSR $E9FF               ; Set cursor row
        LDY #$0A
        JSR $E50C               ; Clear line area
        LDX $0347               ; CURRENT_PLAYER (0=Eldoin, 1=Dailor)
        LDA $1D34,X             ; Get player name string offset
        TAX
        JSR sub_1E8B            ; Print player name
        LDX $034A               ; GAME_STATE (0=Bewegung, 1=Angriff, 2=Tor)
        LDA $1D36,X             ; Get phase name string offset
        TAX
        JSR sub_1E8B            ; Print phase name prefix
        LDX #$29                ; "PHASE" suffix offset
        JSR sub_1E8B            ; Print "PHASE"
        JMP sub_1EE2            ; Update terrain display

; -----------------------------------------------------------------------------
; String Offset Lookup Tables and Game Text Data
; -----------------------------------------------------------------------------
; $1D34: Player name offsets (2 bytes)
;   [0] = "ELDOIN " (offset $00)
;   [1] = "DAILOR "  (offset $09)
;
; $1D36: Game phase name offsets (3 bytes)
;   [0] = "BEWEGUNGS" (Movement phase)   - offset $12
;   [1] = "ANGRIFFS"  (Attack phase)     - offset $1C
;   [2] = "TOR"       (Gate/Fort phase)  - offset $25
;
; $1D39: Terrain/Unit name offsets (used by sub_1EE2)
;
; TERRAIN NAME OFFSETS ($1D39+):
;   Index 0: Wiese (Meadow)      - Char $69 (variant 1)
;   Index 1: Wiese (Meadow)      - Char $6A (variant 2)
;   Index 2: Fluss (River)       - Char $6B
;   Index 3: Wald (Forest)       - Char $6C
;   Index 4: Ende (End-Marker)   - Char $6D
;   Index 5: Sumpf (Swamp)       - Char $6E
;   Index 6: Tor (Gate)          - Char $6F
;   Index 7: Gebirge (Mountains) - Char $70
;   Index 8: Pflaster (Pavement) - Char $71
;   Index 9-10: Mauer (Wall)     - Char $72-$73
;
; UNIT TYPE NAME OFFSETS ($1D39+11):
;   Index 11+: Unit type names (Schwertträger, Bogenschützen, etc.)
; -----------------------------------------------------------------------------
        .byte $00, $09, $12, $1C, $25, $00, $00, $06, $0C, $11, $16, $1C, $20, $28, $31, $31  ; ....%....... (11
        .byte $37, $45, $53, $59, $66, $73, $9A, $45, $7C, $85, $90, $9A, $A3, $AC, $B5, $C1  ; 7esyfs.e|......A

; Game text strings (PETSCII encoded, $5C = backslash separator)
        .byte $05, $45, $4C, $44, $4F, $49, $4E, $20, $5C, $05, $44, $41, $49, $4C, $4F, $52  ; .eldoin \.dailor
        .byte $20, $5C, $42, $45, $57, $45, $47, $55, $4E, $47, $53, $5C, $41, $4E, $47, $52  ;  \bewegungs\angr
        .byte $49, $46, $46, $53, $5C, $54, $4F, $52, $5C, $50, $48, $41, $53, $45, $5C, $20  ; iffs\tor\phase\
        .byte $28, $54, $4F, $52, $29, $5C, $57, $45, $49, $54, $45, $52, $5C, $53, $41, $56  ; (tor)\weiter\sav
        .byte $45, $20, $47, $41, $4D, $45, $5C, $05, $46, $49, $4C, $45, $1D, $28, $41, $2D  ; e game\.file.(a-
        .byte $5A, $29, $3F, $1D, $5C, $05, $44, $49, $53, $4B, $2D, $45, $52, $52, $4F, $52  ; z)?.\.disk-error

; Terrain type names (German)
; zug\wiese\fluss\wald\ende\sumpf\tor\gebirge\pflaster\mauer\
        .byte $21, $21, $5C, $9D, $2E, $20, $5A, $55, $47, $5C, $57, $49, $45, $53, $45, $5C  ; !!\.. zug\wiese\
        .byte $46, $4C, $55, $53, $53, $5C, $57, $41, $4C, $44, $5C, $45, $4E, $44, $45, $5C  ; fluss\wald\ende\
        .byte $53, $55, $4D, $50, $46, $5C, $54, $4F, $52, $5C, $47, $45, $42, $49, $52, $47  ; sumpf\tor\gebirg
        .byte $45, $5C, $50, $46, $4C, $41, $53, $54, $45, $52, $5C, $4D, $41, $55, $45, $52  ; e\pflaster\mauer\

; Unit type names (German)
; schwertträger\bogenschützen\adler\lanzenträger\kriegsschiff\
; reiterei\katapult\blutsauger\axtmänner\feldherr\lindwurm\
; rammbock\wagenfahrer\wolfsreiter\
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
