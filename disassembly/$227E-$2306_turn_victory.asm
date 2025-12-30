; =============================================================================
; Turn Counter and Victory Check
; Address range: $227E - $2306
; =============================================================================
; Handles turn progression and game ending conditions:
; - Turn counter increment (BCD format)
; - Turn display on screen
; - Victory check at turn 15
; - Player selection for next action
; =============================================================================

; -----------------------------------------------------------------------------
; sub_227E - Turn Counter Display and Victory Check
; -----------------------------------------------------------------------------
; Increments turn counter (BCD format), displays it on screen,
; and checks for game end at turn 15.
;
; Turn counter is stored at $4FFF in BCD format.
; Game ends when turn reaches $15 (15 decimal).
; -----------------------------------------------------------------------------
sub_227E:
        LDA $4FFF               ; Load current turn (BCD)
        SED                     ; Set decimal mode
        CLC
        ADC #$01                ; Increment turn
        STA $4FFF               ; Store new turn
        CLD                     ; Clear decimal mode
        PHA                     ; Save turn for later check
        LDX #$16                ; Screen column for turn display

L228C:
        JSR $E9FF               ; KERNAL: Set cursor position
        INX
        CPX #$19
        BNE L228C
        LDX #$16
        LDY #$10
        JSR $E50C               ; KERNAL: Clear screen region
        LDA $4FFF
        JSR sub_1F90            ; Display turn number
        LDX #$63
        JSR sub_1E8B            ; Print turn label string
        PLA                     ; Restore turn value
        CMP #$15                ; Is it turn 15?
        BNE L22B1               ; No, continue game
        STA $034F               ; ACTION_UNIT - store for victory screen
        JMP loc_1456            ; Jump to victory/game end routine

; -----------------------------------------------------------------------------
; L22B1 - Continue Game / Player Selection
; -----------------------------------------------------------------------------
; Displays prompts for player selection and waits for input.
; -----------------------------------------------------------------------------
L22B1:
        LDX #$17
        LDY #$10
        JSR $E50C
        LDX #$36
        JSR sub_1E8B            ; Print prompt string
        LDX #$18
        LDY #$0E
        JSR $E50C
        LDX #$3D
        JSR sub_1E8B            ; Print second prompt

; -----------------------------------------------------------------------------
; L22C9 - Player Selection Input Loop
; -----------------------------------------------------------------------------
; Handles cursor display and joystick input for player selection.
; Displays '>' cursor at selected option.
; -----------------------------------------------------------------------------
L22C9:
        LDA #$3E                ; '>' cursor character
        STA $C3A4               ; Screen position for option 1
        LDA #$01
        STA $DBA4               ; Color RAM for option 1
        LDA #$20                ; Space (clear cursor)
        STA $C3CC               ; Screen position for option 2

loc_22D8:
        LDA CIA1_PRB            ; Read joystick port
        TAX
        AND #$01                ; Check UP direction
        BEQ L22C9               ; If pressed, reset to option 1
        TXA
        AND #$02                ; Check DOWN direction
        BEQ L22ED               ; If pressed, move to option 2
        TXA
        AND #$10                ; Check FIRE button
        BEQ L22FF               ; If pressed, confirm selection
        JMP loc_22D8            ; Continue polling

L22ED:
        LDA #$3E                ; '>' cursor
        STA $C3CC               ; Move cursor to option 2
        LDA #$01
        STA $DBCC               ; Set color for option 2
        LDA #$20                ; Space
        STA $C3A4               ; Clear cursor from option 1
        JMP loc_22D8

; -----------------------------------------------------------------------------
; L22FF - Confirm Selection
; -----------------------------------------------------------------------------
; Checks which option was selected and returns accordingly.
; -----------------------------------------------------------------------------
L22FF:
        LDA $C3A4               ; Check if cursor at option 1
        CMP #$3E
        BNE loc_2307            ; If not, option 2 was selected
        RTS                     ; Return (option 1 selected)
