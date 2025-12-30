; =============================================================================
; Unit Management
; Address range: $20B7 - $20E6
; =============================================================================
; Unit pointer manipulation and movement point management.
; These routines handle iterating through unit data and resetting
; movement points at the start of turns.
; =============================================================================

; -----------------------------------------------------------------------------
; sub_20B7 - Advance Unit Pointer
; -----------------------------------------------------------------------------
; Advances the unit data pointer ($F9) by 6 bytes (one unit record).
; Unit record structure: 6 bytes per unit
; Called when iterating through all units in the game.
; -----------------------------------------------------------------------------
sub_20B7:
        LDY #$06

L20B9:
        JSR sub_177A            ; Increment pointer $F9
        DEY
        BNE L20B9
        RTS

; -----------------------------------------------------------------------------
; sub_20C0 - Reset Unit Movement Points
; -----------------------------------------------------------------------------
; Copies movement values from offset 4 to offset 3 for all units.
; Called at the start of a new turn to restore movement points.
; Iterates through all units until finding one with zero at offset 4.
; -----------------------------------------------------------------------------
sub_20C0:
        JSR sub_15C2            ; Initialize unit pointer

loc_20C3:
        LDY #$04
        LDA ($F9),Y             ; Load max movement from offset 4
        BEQ L20D2               ; If zero, end of unit list
        DEY
        STA ($F9),Y             ; Store to current movement at offset 3
        JSR sub_20B7            ; Advance to next unit
        JMP loc_20C3

L20D2:
        RTS

; -----------------------------------------------------------------------------
; sub_20D3 - Set Unit Movement to 1
; -----------------------------------------------------------------------------
; Sets movement value to 1 for all units.
; Used for restricted movement phases (e.g., combat phase).
; -----------------------------------------------------------------------------
sub_20D3:
        JSR sub_15C2            ; Initialize unit pointer

loc_20D6:
        LDY #$04
        LDA ($F9),Y             ; Check if unit exists (offset 4)
        BEQ L20D2               ; If zero, end of unit list
        LDA #$01
        DEY
        STA ($F9),Y             ; Set current movement to 1
        JSR sub_20B7            ; Advance to next unit
        JMP loc_20D6
