; =============================================================================
; Unit Management
; Address range: $20B7 - $20E6
; =============================================================================
; Unit pointer manipulation and movement point management.
; These routines handle iterating through unit data and resetting
; movement points at the start of turns.
;
; UNIT RECORD STRUCTURE (6 bytes per unit at $5FA0):
; --------------------------------------------------
;   [0] X coordinate (0-79)
;   [1] Y coordinate (0-39)
;   [2] V (Verteidigung/Defense) - from $1017, can decrease in combat
;   [3] B current (Bewegung/Movement) - from $1037, decreases on move
;   [4] B max (Movement reset value) - from $1037, 0 marks end of list
;   [5] Original terrain under unit
;
; Note: R (Range, $1027) and A (Attack, $1047) are NOT stored per-unit,
;       they are read from tables using the unit type index.
; =============================================================================

; -----------------------------------------------------------------------------
; sub_20B7 - Advance Unit Pointer
; -----------------------------------------------------------------------------
; Advances the unit data pointer ($F9) by 6 bytes (one unit record).
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
; sub_20C0 - Reset Unit Movement Points (B current = B max)
; -----------------------------------------------------------------------------
; Copies B max (unit[4]) to B current (unit[3]) for all units.
; Called at STATE 6 transition (end of Torphase for Dailor) to restore
; all units' movement points for the new round.
;
; CALLED FROM: loc_1EA8 when combined state = 6 (end of round)
; -----------------------------------------------------------------------------
sub_20C0:
        JSR sub_15C2            ; Initialize unit pointer ($F9 = $5FA0)

loc_20C3:
        LDY #$04
        LDA ($F9),Y             ; Load B max from unit[4]
        BEQ L20D2               ; If zero, end of unit list
        DEY
        STA ($F9),Y             ; Store to B current at unit[3]
        JSR sub_20B7            ; Advance to next unit
        JMP loc_20C3

L20D2:
        RTS

; -----------------------------------------------------------------------------
; sub_20D3 - Initialize Attack Phase (B current = 1)
; -----------------------------------------------------------------------------
; Sets B current (unit[3]) to 1 for all units.
; Called at STATES 2,3 transition (entering Angriffsphase).
; During attack phase, B_current is repurposed as "attacks remaining" counter:
;   - Set to 1 here (each unit can attack once)
;   - Checked by sub_12EE before allowing attack (BEQ L1327 if 0)
;   - Set to 0 by sub_1445 after unit attacks
;
; CALLED FROM: loc_1EA8 when combined state = 2 or 3
;   State 2: Dailor finishes Bewegungsphase, Eldoin enters Angriffsphase
;   State 3: Eldoin finishes Angriffsphase, Dailor enters Angriffsphase
; -----------------------------------------------------------------------------
sub_20D3:
        JSR sub_15C2            ; Initialize unit pointer ($F9 = $5FA0)

loc_20D6:
        LDY #$04
        LDA ($F9),Y             ; Check B max at unit[4]
        BEQ L20D2               ; If zero, end of unit list
        LDA #$01                ; Set B current to 1 (BCD)
        DEY
        STA ($F9),Y             ; Store to unit[3]
        JSR sub_20B7            ; Advance to next unit
        JMP loc_20D6
