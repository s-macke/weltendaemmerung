; =============================================================================
; Initialization - Hardware setup, memory initialization
; Address range: $080D - $0884
; =============================================================================
;
; This module handles the complete startup sequence from BASIC SYS 2061:
;   1. Clear hardware registers (SID, game state variables)
;   2. Copy character ROM to RAM for custom character set
;   3. Configure VIC-II for custom screen/character memory
;   4. Display title screen and wait for menu selection
;   5. Load game data (new or saved)
;   6. Play intro animation with music
;   7. Initialize cursor sprite and enter main loop
;
; See docs/title_screen.md for full documentation.
; =============================================================================

; -----------------------------------------------------------------------------
; loc_080D - Main Entry Point (called via SYS 2061 from BASIC header)
; -----------------------------------------------------------------------------
; ASYMMETRIC UNIT TRACKING:
; The game only tracks Dailor's unit count ($4FF0), NOT Eldoin's.
; Victory conditions:
;   - Eldoin wins by reducing $4FF0 to zero (all Dailor units destroyed)
;   - Dailor wins by killing Eldoin's Feldherr (commander unit $11)
; This is an intentional asymmetry - Dailor has numerical advantage (164 units)
; but Eldoin's Feldherr is a high-value target.
;
; UNIT COUNT VALUE:
; Initialized to $9F (159 decimal), NOT $A4 (164).
; The docs state Dailor has 164 units, but counter starts at 159.
; Possible explanations:
;   1. Some units are not counted (structures, special units)
;   2. Counter was manually tuned for game balance
;   3. Documentation error (actual unit count may be 159)
; The exact reason is unclear from the code alone.
; -----------------------------------------------------------------------------
loc_080D:
        LDA #$9F                ; Initialize Dailor unit counter (159 units)
        STA $4FF0               ; STATE_DAILOR_UNITS (decremented on kill)
        LDA #$00
        LDX #$18

; -----------------------------------------------------------------------------
; L0816 - Clear Hardware and State Memory
; -----------------------------------------------------------------------------
; Zeros out:
;   - SID registers ($D400-$D418) - silence audio
;   - Game variables ($0340-$0358) - scroll position, temp storage
;   - Attack state ($0359-$0371) - attacker pointers
;   - Gate flags ($4FF2-$500A) - fortification state
; -----------------------------------------------------------------------------
L0816:
        STA SID_V1FREQL,X
        STA $0340,X             ; SCROLL_X (map scroll X)
        STA $0359,X             ; ATTACKER_PTR (attacker data ptr hi)
        STA $4FF2,X             ; STATE_GATE_FLAGS (gate/build location flags)
        DEX
        BPL L0816

; -----------------------------------------------------------------------------
; Copy Character ROM to RAM ($D000 -> $E000)
; -----------------------------------------------------------------------------
; The C64 character ROM at $D000 is normally hidden behind I/O registers.
; sub_1B22 banks out ROMs to access it, then we copy 4KB to $E000 in RAM.
; This allows custom characters to be added at $E2F0 (tiles $5E-$83).
; -----------------------------------------------------------------------------
        JSR sub_1B22            ; Bank out ROMs (see RAM at $D000)
        LDA #$00
        STA $F7                 ; TEMP_PTR1 (general ptr lo)
        STA $F9                 ; TEMP_PTR2 (general ptr lo)
        TAY
        LDA #$D0
        STA $F8                 ; Source: $D000 (Character ROM)
        LDA #$E0
        STA $FA                 ; Dest: $E000 (RAM copy)

L0837:
        LDA ($F7),Y             ; Read from Character ROM
        STA ($F9),Y             ; Write to RAM
        INY
        BNE L0837
        INC $F8                 ; Next source page
        INC $FA                 ; Next dest page
        LDA $FA
        BNE L0837               ; Loop until $FA wraps ($E000+$1000=$F000, but stops at $0000)
        JSR sub_1B28            ; Bank ROMs back in

; -----------------------------------------------------------------------------
; Configure VIC-II Memory Layout
; -----------------------------------------------------------------------------
; Screen memory: $C000-$C3FF (set via HIBASE $0288 = $C0)
; Character set: $E000-$EFFF (set via CIA2_PRA and VIC_VMCSB)
;
; CIA2_PRA = $94: VIC bank 1 ($4000-$7FFF)... wait, that's not right.
; Actually: CIA2 bits 0-1 select VIC bank (inverted):
;   $94 = %10010100 -> bits 0-1 = %00 -> bank 3 ($C000-$FFFF)
;
; VIC_VMCSB = $08:
;   bits 4-7 = screen offset (0 = $C000)
;   bits 1-3 = char set offset (4 = +$2000 = $E000 in VIC bank)
; -----------------------------------------------------------------------------
        LDA #$ED
        STA $0341               ; SCROLL_Y - initial map scroll position
        LDA #$C0
        STA $0288               ; HIBASE - screen at $C000
        LDA #$94
        STA CIA2_PRA            ; VIC bank 3 ($C000-$FFFF)
        LDA #$08
        STA VIC_VMCSB           ; Screen $C000, chars $E000

; -----------------------------------------------------------------------------
; Display Title Screen
; -----------------------------------------------------------------------------
        JSR sub_15CD            ; Load custom character patterns to $E2F0
        JSR sub_0BF3            ; Display title screen and menu, wait for input
        JSR sub_0E56            ; Set up raster IRQ handler

; -----------------------------------------------------------------------------
; Handle Menu Selection
; -----------------------------------------------------------------------------
; MENU_SELECT ($035D) contains:
;   $85 = F1 pressed (load saved game) - sub_2364 already called in sub_0BF3
;   $86 = F3 pressed (new game) - need to decompress map and init game
;   $C4 = Special value indicating saved game was loaded
; -----------------------------------------------------------------------------
        LDA $035D               ; MENU_SELECT (menu selection)
        CMP #$C4                ; Was saved game loaded?
        BEQ L0873               ; Yes: skip map decompression
        JSR sub_1721            ; Decompress map data ($1788 -> $5000)
        JSR sub_0FAC            ; Initialize game logic and unit placement

; -----------------------------------------------------------------------------
; L0873 - Title Screen Animation Sequence
; -----------------------------------------------------------------------------
; Plays dramatic intro animation before entering gameplay:
;   1. Scroll screen up with ascending "victory" music
;   2. Reload character patterns (may have been modified)
;   3. Scroll screen down with descending "defeat" music
;   4. Initialize cursor sprite at center of map
;   5. Set SID to noise waveform for ambient sound
;   6. Final initialization before main loop
; -----------------------------------------------------------------------------
L0873:
        JSR sub_1C88            ; Victory music + scroll up (19 rows)
        JSR sub_15CD            ; Reload custom characters
        JSR sub_1CBC            ; Defeat music + scroll down (19 rows)
        JSR sub_1C35            ; Initialize cursor sprite at map center
        JSR sub_1CE2            ; Set SID voices to noise waveform
        JSR sub_1D0E            ; Final init (continues to main loop)
