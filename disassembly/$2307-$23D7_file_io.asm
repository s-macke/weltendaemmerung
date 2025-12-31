; =============================================================================
; File I/O - Save/Load Game
; Address range: $2307 - $23D7
; =============================================================================
;
; SAVE FILE FORMAT
; ----------------
; The game saves a contiguous memory block from $4FF0 to $6678 (5,769 bytes):
;
; | Address Range | Size    | Contents                              |
; |---------------|---------|---------------------------------------|
; | $4FF0-$4FFF   | 16 B    | Game state (unit count, gates, turn#) |
; | $5000-$5F9F   | 3,200 B | Map data (80x40 tiles)                |
; | $5FA0-$6678   | 1,753 B | Unit records (~292 units, 6 bytes ea) |
;
; Game State Variables ($4FF0-$4FFF):
;   $4FF0 - STATE_DAILOR_UNITS: Dailor unit counter (decremented on kill)
;   $4FF2-$4FFE - STATE_GATE_FLAGS: Fortification flags (13 locations)
;   $4FFF - STATE_TURN_COUNTER: Current turn (BCD, max $15)
;
; Unit Record Structure (6 bytes each at $5FA0+):
;   Offset 0: X coordinate (0-79)
;   Offset 1: Y coordinate (0-39, $FF=destroyed)
;   Offset 2: V - Current defense (BCD)
;   Offset 3: B_current - Current movement points (BCD)
;   Offset 4: B_max - Maximum movement points (BCD, 0=end marker)
;   Offset 5: Original terrain tile under unit
;
; Filename: Single letter A-Z, stored at $035C
; =============================================================================

; -----------------------------------------------------------------------------
; loc_2307 - Save Game to Disk
; -----------------------------------------------------------------------------
; Saves memory range $4FF0-$6678 to disk using KERNAL SAVE routine.
; On error, displays message and retries.
; -----------------------------------------------------------------------------
loc_2307:
        LDX #$16
        JSR $E9FF               ; KERNAL: Close logical file 22
        INX
        JSR $E9FF               ; KERNAL: Close logical file 23
        LDX #$16
        LDY #$0E
        JSR $E50C               ; KERNAL: Set cursor position
        JSR sub_2347            ; Get filename letter from user (A-Z)
        LDX #$08                ; Device 8 (disk drive)
        JSR SETLFS              ; Set logical file parameters
        LDA #$01                ; Filename length = 1
        LDX #$5C                ; Filename at $035C (lo)
        LDY #$03                ; Filename at $035C (hi)
        JSR SETNAM              ; Set filename
        LDA #$4F
        STA $F8                 ; TEMP_PTR1 hi = $4F -> $4FF0
        LDA #$F0
        STA $F7                 ; TEMP_PTR1 lo = $F0
        LDA #$F7                ; ZP pointer location for start address
        LDX #$79                ; End address lo = $79
        LDY #$66                ; End address hi = $66 -> $6679 (exclusive)
        JSR SAVE                ; KERNAL: Save $4FF0-$6678 to disk
        BCC L2346               ; Success? Return
        LDX #$16
        JSR $E9FF               ; Close file on error
        JSR sub_2391            ; Display error message
        JMP loc_2307            ; Retry save

L2346:
        RTS

; -----------------------------------------------------------------------------
; sub_2347 - Get Save/Load Filename Letter
; -----------------------------------------------------------------------------
; Prompts user for single letter A-Z, stores at $035C
; -----------------------------------------------------------------------------
sub_2347:
        LDX #$47
        JSR sub_1E8B            ; Display prompt text
        JSR sub_23B9            ; Show cursor

L234F:
        JSR GETIN               ; KERNAL: Get character from keyboard
        CMP #$41                ; < 'A'?
        BCC L234F               ; Yes, wait for valid input
        CMP #$5B                ; > 'Z'?
        BCS L234F               ; Yes, wait for valid input
        STA $035C               ; SAVE_LETTER - store letter A-Z as filename
        JSR CHROUT              ; KERNAL: Echo character to screen
        JSR sub_23BD            ; Hide cursor

L2363:
        RTS

; -----------------------------------------------------------------------------
; sub_2364 - Load Game from Disk
; -----------------------------------------------------------------------------
; Loads save file into memory $4FF0-$6678, restoring complete game state.
; On error, displays message and retries.
; -----------------------------------------------------------------------------
sub_2364:
        LDX #$12
        LDY #$0E
        JSR $E50C               ; KERNAL: Set cursor position
        JSR sub_2347            ; Get filename letter from user (A-Z)
        LDX #$08                ; Device 8 (disk drive)
        LDY #$01                ; Secondary address
        JSR SETLFS              ; Set logical file parameters
        LDA #$01                ; Filename length = 1
        LDX #$5C                ; Filename at $035C (lo)
        LDY #$03                ; Filename at $035C (hi)
        JSR SETNAM              ; Set filename
        LDA #$00                ; Load to address in file header
        JSR LOAD                ; KERNAL: Load file -> $4FF0-$6678
        BCC L2363               ; Success? Return
        JSR sub_23A9            ; Clear error area
        JSR sub_2391            ; Display error message
        JSR sub_23A9            ; Clear error area
        JMP sub_2364            ; Retry load

; -----------------------------------------------------------------------------
; sub_2391 - Display Error Message and Wait for Key
; -----------------------------------------------------------------------------
sub_2391:
        JSR sub_23B9            ; Show cursor
        LDX $D6                 ; CURSOR_ROW - get current cursor row
        LDY #$0F
        JSR $E50C               ; KERNAL: Set cursor position
        LDX #$55
        JSR sub_1E8B            ; Display error message text
        JSR sub_2129            ; Additional display setup

L23A3:
        JSR GETIN               ; KERNAL: Get keyboard input
        BEQ L23A3               ; Wait for any key
        RTS

; -----------------------------------------------------------------------------
; sub_23A9 - Clear Error Message Area
; -----------------------------------------------------------------------------
; Fills screen area with spaces to clear error messages
; -----------------------------------------------------------------------------
sub_23A9:
        LDX #$14                ; 21 characters to clear

L23AB:
        LDA #$69                ; Space character
        STA $C2DC,X             ; Write to screen RAM
        LDA #$0B                ; Dark gray color
        STA $DADC,X             ; Write to color RAM
        DEX
        BPL L23AB
        RTS

; -----------------------------------------------------------------------------
; sub_23B9 - Show Input Cursor
; -----------------------------------------------------------------------------
sub_23B9:
        LDA #$31                ; Cursor character (visible)
        BNE L23BF

; -----------------------------------------------------------------------------
; sub_23BD - Hide Input Cursor
; -----------------------------------------------------------------------------
sub_23BD:
        LDA #$7E                ; Blank character (hidden)

L23BF:
        STA $0EAC               ; Update cursor display

L23C2:
        RTS

; -----------------------------------------------------------------------------
; sub_23C3 - Boundary Check for Unit Selection
; -----------------------------------------------------------------------------
; Validates cursor position and unit type for edge cases
; -----------------------------------------------------------------------------
sub_23C3:
        LDX $034B               ; CURSOR_MAP_X - cursor X on map
        DEX
        BNE L23C2               ; If not at left edge, return
        LDA $034F               ; ACTION_UNIT - unit in action
        CMP #$12                ; Check boundary
        BCC L23C2               ; If valid, return
        LDA #$11                ; Clamp to valid range
        STA $034F               ; ACTION_UNIT - store corrected value
        JMP loc_1456            ; Jump to update handler
