; =============================================================================
; Main Game Loop and Input Handling
; Address range: $0885 - $0A6F
; =============================================================================
;
; MAIN LOOP STRUCTURE
; -------------------
; The game uses a tight polling loop that:
; 1. Waits for joystick input (with animation during idle)
; 2. Processes directional input to move cursor
; 3. Handles fire button for phase-specific actions
;
; JOYSTICK STATE MACHINE
; ----------------------
; The joystick is read from CIA1 port A ($DC00) or B ($DC01) based on player.
; Bits are inverted and masked to get active-low signals:
;   Bit 0: Up
;   Bit 1: Down
;   Bit 2: Left
;   Bit 3: Right
;   Bit 4: Fire button
;
; State transitions:
;   No input ($00)      -> Animate unit, continue polling
;   Fire only ($10)     -> sub_0ECF handles phase action (attack/torphase/end turn)
;   Direction + Fire    -> Process movement, then fire action
;   Direction only      -> Move cursor in that direction
;
; INPUT DEBOUNCING
; ----------------
; Fire button is debounced via $034D (PREV_JOY):
;   - If fire pressed and same as previous state, restart with delay loop
;   - Prevents multiple triggers from single button press
;
; ADAPTIVE DELAY
; --------------
; $0886 (self-modified) controls main loop delay:
;   $96 (150) = slow delay when fire NOT held (normal cursor movement)
;   $14 (20)  = fast delay when fire IS held (rapid movement)
;
; CURSOR MOVEMENT
; ---------------
; Sprite 0 position (VIC_SP0X/Y) is cursor position on screen.
; Movement is 8 pixels per step (one character cell).
; Boundary checks trigger map scrolling at screen edges.
;
; =============================================================================

; -----------------------------------------------------------------------------
; loc_0885: Main loop entry with delay
; Calls KERNAL $EEB3 (scan keyboard) 50 times as delay/debounce
; -----------------------------------------------------------------------------
loc_0885:
        LDX #$32

L0887:
        JSR $EEB3
        DEX
        BNE L0887

; -----------------------------------------------------------------------------
; loc_088D: Main polling loop - read joystick and dispatch
; Player 0 (Eldoin) uses joystick port 2 ($DC00)
; Player 1 (Dailor) uses joystick port 1 ($DC01)
; -----------------------------------------------------------------------------
loc_088D:
        LDA $0347               ; CURRENT_PLAYER (active player)
        EOR #$01                ; Invert: player 0->1, player 1->0
        AND #$01                ; Ensure 0 or 1
        TAX                     ; X = port offset (0=port A, 1=port B)
        LDA CIA1_PRA,X          ; Read joystick port
        EOR #$1F                ; Invert bits 0-4 (active low -> active high)
        AND #$1F                ; Mask to bits 0-4 only
        STA $0354               ; JOY_STATE (joystick state)
        BNE L08AA               ; If any input, process it
        STA $034D               ; Clear previous joystick state
        JSR sub_12C0            ; Animate current unit while idle
        JMP loc_088D            ; Continue polling

; -----------------------------------------------------------------------------
; L08AA: Fire button only pressed (no direction)
; Triggers phase-specific action via sub_0ECF
; -----------------------------------------------------------------------------
L08AA:
        CMP #$10                ; Fire button only? (bit 4 set, bits 0-3 clear)
        BNE L08BC               ; No, has direction - go to directional handler
        CMP $034D               ; Same as previous state? (debounce)
        BEQ loc_0885            ; Yes, restart with delay
        STA $034D               ; Store new state
        JSR sub_0ECF            ; Handle fire button (attack/torphase/end turn)
        JMP loc_0885            ; Restart with delay

; -----------------------------------------------------------------------------
; L08BC: Directional input (with or without fire)
; Dispatches to movement handlers by testing direction bits via ROR
; After ROR: Carry = tested bit, continue testing remaining bits
;   Bit 0 (Up)    -> L08ED (move cursor up)
;   Bit 1 (Down)  -> L0911 (move cursor down)
;   Bit 2 (Left)  -> L092E (move cursor left)
;   Bit 3 (Right) -> loc_096F (move cursor right)
; -----------------------------------------------------------------------------
L08BC:
        PHA                     ; Save joystick state
        JSR sub_09B4            ; Check if movement allowed, show unit
        PLA                     ; Restore joystick state
        ROR A                   ; Bit 0 (Up) -> Carry
        BCS L08ED               ; If Up pressed, jump to up handler

loc_08C4:
        ROR A                   ; Bit 1 (Down) -> Carry
        BCS L0911               ; If Down pressed, jump to down handler

loc_08C7:
        ROR A                   ; Bit 2 (Left) -> Carry
        BCS L092E               ; If Left pressed, jump to left handler

loc_08CA:
        ROR A                   ; Bit 3 (Right) -> Carry
        BCS L08E5               ; If Right pressed, jump to right handler

; -----------------------------------------------------------------------------
; loc_08CD: Movement complete - restore display and update unit position
; -----------------------------------------------------------------------------
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
        JMP loc_096F          ; Jump to right handler

L08E8:
        LDA #$14              ; Fast delay (fire held)
        JMP loc_08DF

; -----------------------------------------------------------------------------
; L08ED: Move cursor UP
; Screen boundary: Y=$38 (top edge) triggers map scroll up via sub_1BDC
; -----------------------------------------------------------------------------
L08ED:
        PHA                   ; Save joystick state
        JSR sub_0AD5          ; Update map position for up movement
        LDA VIC_SP0Y          ; Get cursor Y position
        CMP #$38              ; At top screen edge?
        BEQ L0969             ; Yes, scroll map up
        SEC
        SBC #$08              ; Move cursor up 8 pixels (1 tile)
        STA VIC_SP0Y

loc_08FE:
        JSR sub_0A70          ; Check if movement allowed
        BEQ L0907             ; If blocked, check next direction

loc_0903:
        PLA                   ; Restore joystick state
        JMP loc_08CD          ; Finish movement processing

L0907:
        PLA                   ; Movement blocked
        JMP loc_08C4          ; Continue to check Down direction

L090B:
        JSR sub_1BF0          ; Scroll map down (cursor at bottom)
        JMP loc_0922

; -----------------------------------------------------------------------------
; L0911: Move cursor DOWN
; Screen boundary: Y=$C8 (bottom edge) triggers map scroll down via sub_1BF0
; -----------------------------------------------------------------------------
L0911:
        PHA                   ; Save joystick state
        JSR sub_0AEB          ; Update map position for down movement
        LDA VIC_SP0Y          ; Get cursor Y position
        CMP #$C8              ; At bottom screen edge?
        BEQ L090B             ; Yes, scroll map down
        CLC
        ADC #$08              ; Move cursor down 8 pixels (1 tile)
        STA VIC_SP0Y

loc_0922:
        JSR sub_0A70          ; Check if movement allowed
        BEQ L092A             ; If blocked, check next direction
        JMP loc_0903          ; Movement allowed, finish

L092A:
        PLA                   ; Movement blocked
        JMP loc_08C7          ; Continue to check Left direction

; -----------------------------------------------------------------------------
; L092E: Move cursor LEFT
; Screen boundary: X=$1E (left edge) triggers map scroll left via sub_1BBE
; X position uses MSB for values > 255 (sprite X coordinate)
; -----------------------------------------------------------------------------
L092E:
        PHA                   ; Save joystick state
        JSR sub_0AA3          ; Update map position for left movement
        LDA VIC_SPXMSB        ; Get sprite X MSB (bit 8)
        AND #$01              ; Check if X > 255
        BNE L0949             ; Yes, handle extended X
        LDA VIC_SP0X          ; Get cursor X position (low byte)
        CMP #$1E              ; At left screen edge?
        BEQ L09A8             ; Yes, scroll map left

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
        JSR sub_1BDC          ; Scroll map up (cursor at top)
        JMP loc_08FE

; -----------------------------------------------------------------------------
; loc_096F: Move cursor RIGHT
; Screen boundary: X=$47 (right edge, MSB=1) triggers map scroll right
; Handles extended X coordinate (9-bit) via VIC_SPXMSB
; -----------------------------------------------------------------------------
loc_096F:
        PHA                   ; Save joystick state
        JSR sub_0ABB          ; Update map position for right movement
        LDA VIC_SPXMSB        ; Get sprite X MSB (bit 8)
        BEQ L0991             ; If X < 256, check low byte boundary
        LDA VIC_SP0X          ; X > 255, check extended boundary
        CMP #$47              ; At right screen edge? (X=$147)
        BEQ L09AE             ; Yes, scroll map right

L097F:
        CLC
        ADC #$08              ; Move cursor right 8 pixels (1 tile)
        STA VIC_SP0X

loc_0985:
        JSR sub_0A70          ; Check if movement allowed
        BEQ L098D             ; If blocked, finish
        JMP loc_0903          ; Movement allowed, finish processing

L098D:
        PLA                   ; Movement blocked
        JMP loc_08CD          ; Finish (no more directions to check)

L0991:
        LDA VIC_SP0X          ; X < 256
        CMP #$FE              ; At X=254 boundary?
        BNE L097F             ; No, just move right
        LDA VIC_SPXMSB        ; Cross into extended range
        ORA #$01              ; Set MSB (X becomes > 255)
        STA VIC_SPXMSB
        LDA #$07              ; X low byte = 7 (total X=$107)
        STA VIC_SP0X
        JMP loc_0985

L09A8:
        JSR sub_1BBE          ; Scroll map left
        JMP loc_095D

L09AE:
        JSR sub_1BCC          ; Scroll map right
        JMP loc_0985

; =============================================================================
; sub_09B4: Check if Unit Can Move / Show Unit on Screen
; =============================================================================
; Called before processing directional input.
; If unit found at cursor and has movement points > 0:
;   - Saves unit's current tile to $0352
;   - Displays unit on screen (replaces terrain with unit tile)
;   - Updates map data
; If unit has 0 movement points:
;   - Jumps to loc_12B6 to flash cursor (no movement allowed)
;
; Returns:
;   Z=1 if no unit or movement blocked
;   Z=0 if unit ready to move
; -----------------------------------------------------------------------------
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

; =============================================================================
; sub_09F2: Restore Terrain / Update Unit Position After Movement
; =============================================================================
; Called after cursor movement completes.
; - Restores the original terrain tile that was saved in $0352
; - Updates the unit's position in memory (X-1, Y-1 coordinates)
; - Plays terrain-specific sound effects based on destination tile
;
; TERRAIN SOUND EFFECTS:
;   $76, $7D (Water/Sea)   -> Swoosh sound if not moving (sub_2013)
;   $78 (Forest/Trees)     -> Rustling sound if moving (sub_1CE2)
;   $79, $82, $83 (Gates)  -> Jump to movement handler (L0A81)
;   $7A, $7F (Mountains)   -> Jump to mountain handler (L0A96)
;   Other terrain          -> No special sound, update display
; -----------------------------------------------------------------------------
sub_09F2:
        JSR sub_0A70            ; Check phase allows movement
        BEQ L09F1               ; If not, return immediately
        JSR sub_1F1C            ; Calculate screen coordinates
        JSR sub_1F77            ; Set up screen pointer
        LDA ($D1),Y             ; Get current screen character
        PHA                     ; Save it
        LDA $0352               ; Get saved original terrain tile
        STA ($D1),Y             ; Restore terrain on screen
        PHA                     ; Save terrain for map update
        JSR sub_1C01            ; Get terrain color
        STA ($F3),Y             ; Update color RAM
        LDX $034C               ; Get cursor map Y position
        JSR sub_0F82            ; Calculate map pointer
        PLA
        STA ($B4),Y             ; Restore terrain in map data
        LDA $0350               ; Restore unit pointer from backup
        STA $F9
        LDA $0351
        STA $FA
        ; Update unit's stored position (offset 0=X, offset 1=Y)
        LDY #$00
        LDX $034B               ; Get cursor map X
        DEX                     ; Convert to 0-based
        TXA
        STA ($F9),Y             ; Store new X position in unit record
        INY
        LDX $034C               ; Get cursor map Y
        DEX                     ; Convert to 0-based
        TXA
        STA ($F9),Y             ; Store new Y position in unit record
        LDY #$05
        PLA
        STA ($F9),Y             ; Store display tile in unit record
        ; Check terrain type for sound effects
        LDA $0352               ; Get destination terrain
        CMP #$76                ; Water?
        BEQ L0A5A
        CMP #$7D                ; Sea?
        BEQ L0A5A
        CMP #$78                ; Forest?
        BEQ L0A65
        CMP #$79                ; Gate type 1?
        BEQ L0A81
        CMP #$83                ; Gate type 2?
        BEQ L0A81
        CMP #$7A                ; Mountain type 1?
        BEQ L0A96
        CMP #$7F                ; Mountain type 2?
        BEQ L0A96
        CMP #$82                ; Fortification?
        BEQ L0A81
        JMP sub_1EE2            ; Default: update terrain info display

; Water/Sea terrain - play swoosh if stationary
L0A5A:
        LDA $0353               ; Check movement flag
        BNE L0A62               ; If moving, skip sound
        JSR sub_2013            ; Play water swoosh sound

L0A62:
        JMP sub_1EE2            ; Update terrain info display

; Forest terrain - play rustling if moving
L0A65:
        LDA $0353               ; Check movement flag
        BEQ L0A62               ; If not moving, skip sound
        JSR sub_1CE2            ; Play forest rustling sound
        JMP sub_1EE2            ; Update terrain info display
