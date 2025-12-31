; =============================================================================
; Movement Validation and Combat Logic
; Address range: $0A70 - $0BF2
; =============================================================================

; -----------------------------------------------------------------------------
; sub_0A70 - Check if Movement is Allowed in Current Phase
; -----------------------------------------------------------------------------
; Returns Z=1 (equal) if movement should be skipped/restricted.
; In Angriffsphase (Phase 1) and Torphase (Phase 2), certain movement
; checks are bypassed (combat/fortification actions take priority).
;
; Phase 0 (Bewegungsphase): Full movement validation
; Phase 1 (Angriffsphase): Movement restricted, returns Z=1
; Phase 2 (Torphase): Fortification mode, returns Z=1
; -----------------------------------------------------------------------------
sub_0A70:
        LDA $034A               ; GAME_STATE (game phase)
        CMP #$01                ; Angriffsphase?
        BEQ L0A80               ; Yes, skip movement (Z=1)
        CMP #$02                ; Torphase?
        BEQ L0A80               ; Yes, skip movement (Z=1)
        ; Phase 0: Check sprite color for movement state
        LDA VIC_SP0COL
        CMP #$F1                ; Compare with movement indicator color

L0A80:
        RTS

L0A81:
        LDA $0353               ; MOVE_FLAG (movement flag)
        BNE L0A62
        LDX #$03

L0A88:
        LDY #$5A
        JSR sub_1CF3
        JSR sub_20A4
        DEX
        BNE L0A88
        JMP sub_1EE2

L0A96:
        LDA $0353               ; MOVE_FLAG (movement flag)
        BEQ L0A62
        LDA #$20
        JSR sub_1CE4
        JMP sub_1EE2

; -----------------------------------------------------------------------------
; sub_0AA3 - Move Cursor Left (Joystick West)
; -----------------------------------------------------------------------------
; Handles unit movement to the left (Y coordinate decreases).
; Flow: Phase check -> Boundary check -> Terrain validation -> Deduct cost
; If movement blocked or boundary hit, returns to input handler at loc_08FE.
; -----------------------------------------------------------------------------
sub_0AA3:
        JSR sub_0A70            ; Check if movement allowed in current phase

L0AA6:
        BEQ L0A80               ; Z=1: movement restricted, return
        LDX $034C               ; Load CURSOR_MAP_Y
        JSR sub_0F82            ; Get map pointer for current row
        DEY                     ; Decrement Y (move left)
        BMI L0AB6               ; If Y < 0, at left boundary - abort
        JSR sub_0B10            ; Validate terrain at destination
        BCC L0B01               ; Carry clear = allowed, deduct points

L0AB6:
        PLA                     ; Movement blocked - clean up stack
        PLA
        JMP loc_08FE            ; Return to main input handler (left)

; -----------------------------------------------------------------------------
; sub_0ABB - Move Cursor Right (Joystick East)
; -----------------------------------------------------------------------------
; Handles unit movement to the right (Y coordinate increases).
; Checks right boundary at Y=$50 (80 tiles).
; If movement blocked, returns to input handler at loc_0922.
; -----------------------------------------------------------------------------
sub_0ABB:
        JSR sub_0A70            ; Check if movement allowed in current phase
        BEQ L0A80               ; Z=1: movement restricted, return
        LDX $034C               ; Load CURSOR_MAP_Y
        JSR sub_0F82            ; Get map pointer for current row
        INY                     ; Increment Y (move right)
        CPY #$50                ; Check right boundary (80 tiles)
        BEQ L0AB6               ; At boundary - abort
        JSR sub_0B10            ; Validate terrain at destination
        BCC L0B01               ; Carry clear = allowed, deduct points
        PLA                     ; Movement blocked - clean up stack
        PLA
        JMP loc_0922            ; Return to main input handler (right)

; -----------------------------------------------------------------------------
; sub_0AD5 - Move Cursor Up (Joystick North)
; -----------------------------------------------------------------------------
; Handles unit movement upward (X coordinate decreases).
; If movement blocked, returns to input handler at loc_095D.
; -----------------------------------------------------------------------------
sub_0AD5:
        JSR sub_0A70            ; Check if movement allowed in current phase
        BEQ L0A80               ; Z=1: movement restricted, return
        LDX $034C               ; Load CURSOR_MAP_Y
        DEX                     ; Decrement X (move up)
        JSR sub_0F82            ; Get map pointer for new row
        JSR sub_0B10            ; Validate terrain at destination
        BCC L0B01               ; Carry clear = allowed, deduct points
        PLA                     ; Movement blocked - clean up stack
        PLA
        JMP loc_095D            ; Return to main input handler (up)

; -----------------------------------------------------------------------------
; sub_0AEB - Move Cursor Down (Joystick South)
; -----------------------------------------------------------------------------
; Handles unit movement downward (X coordinate increases).
; If movement blocked, returns to input handler at loc_0985.
; -----------------------------------------------------------------------------
sub_0AEB:
        JSR sub_0A70            ; Check if movement allowed in current phase
        BEQ L0AA6               ; Z=1: movement restricted, return via left handler
        LDX $034C               ; Load CURSOR_MAP_Y
        INX                     ; Increment X (move down)
        JSR sub_0F82            ; Get map pointer for new row
        JSR sub_0B10            ; Validate terrain at destination
        BCC L0B01               ; Carry clear = allowed, deduct points
        PLA                     ; Movement blocked - clean up stack
        PLA
        JMP loc_0985            ; Return to main input handler (down)

; -----------------------------------------------------------------------------
; L0B01 - Deduct Movement Points from Unit
; -----------------------------------------------------------------------------
; Loads current movement (unit[3]), subtracts terrain cost via sub_0B82,
; stores result back. Uses decimal mode so SBC operates in BCD.
; -----------------------------------------------------------------------------
L0B01:
        JSR sub_1FF6            ; Find unit record at cursor
        LDY #$03
        LDA ($F9),Y             ; Load unit[3] = current movement points
        SED                     ; Enable decimal mode (affects SBC in sub_0B82)
        JSR sub_0B82            ; Subtract movement cost - SBC uses BCD arithmetic
        STA ($F9),Y             ; Store updated movement points
        CLD                     ; Disable decimal mode
        RTS

; -----------------------------------------------------------------------------
; sub_0B10 - Validate Terrain at Destination
; -----------------------------------------------------------------------------
; Checks if the unit can move to the destination tile.
; Different units have different terrain access rules.
;
; INPUT:
;   ($B4),Y = Map pointer to destination tile
;   $034F = ACTION_UNIT (current unit type on map, char code $74+)
;
; OUTPUT:
;   Carry Clear (CLC): Movement allowed
;   Carry Set (SEC): Movement blocked
;   $0353 = MOVE_FLAG updated
;
; TERRAIN CODES:
;   $69-$6A: Wiese (Meadow) - passable
;   $6B: Fluss (River) - special handling
;   $6C: Wald (Forest) - passable with cost
;   $6D: Ende (End-marker) - passable
;   $6E: Sumpf (Swamp) - passable with cost
;   $6F: Tor (Gate) - blocked for most units
;   $70: Gebirge (Mountains) - blocked for most units
;   $72-$73: Mauer (Wall) - blocked
;   >= $74: Another unit present - blocked
;
; UNIT SPECIAL CASES:
;   $0D (Eagle): Can pass all terrain
;   $14 (Bloodsucker): Can pass all terrain
;   $0F (Warship): Special river handling
;   $10, $19, $1A: Direct movement units
;   $11, $16: Movement with sound effect
; -----------------------------------------------------------------------------
sub_0B10:
        LDA ($B4),Y             ; Load destination tile char code
        LDX $034F               ; Load ACTION_UNIT (unit type + $74)
        CPX #$0D                ; Eagle?
        BEQ L0B6A               ; Yes, special flying movement
        CPX #$14                ; Bloodsucker?
        BEQ L0B6A               ; Yes, special flying movement
        CPX #$0F                ; Warship?
        BEQ L0B59               ; Yes, special water handling
        CMP #$69                ; Char < Wiese ($69)?
        BCC L0B52               ; Yes, blocked (UI/border)
        CMP #$73                ; Wall variant 2 ($73)?
        BEQ L0B52               ; Yes, blocked
        CMP #$72                ; Wall variant 1 ($72)?
        BEQ L0B52               ; Yes, blocked
        CMP #$6F                ; Tor (Gate, $6F)?
        BEQ L0B52               ; Yes, blocked for most units
        CMP #$70                ; Gebirge (Mountains, $70)?
        BEQ L0B52               ; Yes, blocked for most units
        CMP #$74                ; Unit present (>= $74)?
        BCS L0B52               ; Yes, collision - blocked
        CPX #$11                ; Commander (Eldoin)?
        BEQ L0B78               ; Yes, movement with sound
        CPX #$16                ; Commander (Dailor)?
        BEQ L0B78               ; Yes, movement with sound
        CPX #$10                ; Cavalry?
        BEQ L0B71               ; Yes, direct movement
        CPX #$1A                ; Wolf Riders?
        BEQ L0B71               ; Yes, direct movement
        CPX #$19                ; Wagon Drivers?
        BEQ L0B71               ; Yes, direct movement
        JSR sub_20A4            ; Standard movement update
        CLC                     ; Allow movement
        RTS

L0B52:                          ; Movement blocked
        LDA #$01
        STA $0353               ; Set MOVE_FLAG = blocked
        SEC                     ; Return with carry set (blocked)
        RTS

L0B59:                          ; Warship special handling
        STA $0353               ; Store terrain in MOVE_FLAG
        CMP #$6B                ; Is destination River ($6B)?
        BNE L0B52               ; No, block movement
        LDX #$00
        STX $0353               ; Clear MOVE_FLAG
        JSR sub_204C            ; Warship movement update
        CLC                     ; Allow movement
        RTS

L0B6A:                          ; Flying units (Eagle, Bloodsucker)
        STA $0353               ; Store terrain in MOVE_FLAG
        CMP #$74                ; Is another unit present?
        BCS L0B52               ; Yes, collision - blocked

L0B71:                          ; Direct movement (no extra update)
        LDX #$00
        STX $0353               ; Clear MOVE_FLAG
        CLC                     ; Allow movement
        RTS

L0B78:                          ; Movement with sound (Commanders)
        LDX #$00
        STX $0353               ; Clear MOVE_FLAG
        JSR sub_209C            ; Play sound effect
        CLC                     ; Allow movement
        RTS

; -----------------------------------------------------------------------------
; sub_0B82 - Calculate and Subtract Movement Cost
; -----------------------------------------------------------------------------
; Called with decimal mode ON. Determines movement cost based on terrain
; under unit, then subtracts from current movement points using BCD SBC.
; Input: A = current movement points (on stack after PHA)
; Output: A = movement points after terrain cost subtracted (BCD)
; -----------------------------------------------------------------------------
sub_0B82:
        PHA                     ; Save current movement points
        LDY #$05
        LDA ($F9),Y             ; Load unit[5] = terrain under unit
        TAY                     ; Y = terrain type
        LDA $034F               ; Load unit tile code on map
        CLD                     ; Disable decimal mode for binary arithmetic
        SEC
        SBC #$0B                ; Convert tile to unit type index (binary SBC)
        SED                     ; Re-enable decimal mode for movement calc
        TAX                     ; X = unit type index
        TYA                     ; A = terrain type
        LDY #$03
        CMP #$6B                ; River terrain (Fluss)?
        BEQ L0BA5
        CMP #$6C                ; Forest terrain (Wald)?
        BEQ L0BAB
        CMP #$6E                ; Swamp terrain (Sumpf)?
        BEQ L0BB1
        PLA                     ; Default: cost = 1
        SEC
        SBC #$01                ; BCD subtract 1 movement point
        RTS

L0BA5:
        LDA $0BC3,X             ; River cost table (indexed by unit type)
        JMP loc_0BB4

L0BAB:
        LDA $0BD3,X             ; Forest cost table (indexed by unit type)
        JMP loc_0BB4

L0BB1:
        LDA $0BE3,X             ; Swamp cost table (indexed by unit type)

loc_0BB4:
        STA $0342               ; TEMP_CALC (temp calc lo)
        PLA
        SEC
        SBC $0342               ; TEMP_CALC (temp calc lo)
        CMP #$20
        BCC L0BC2
        LDA #$00

L0BC2:
        RTS

; -----------------------------------------------------------------------------
; Movement Cost Tables - Per-unit costs for special terrain types
; -----------------------------------------------------------------------------
; Each table has 16 bytes, one per unit type (0-15).
; Unit types: 0=Schwertträger, 1=Bogenschützen(E), 2=Adler, 3=Lanzenträger,
;             4=Kriegsschiff, 5=Reiterei, 6=Feldherr(E), 7=Bogenschützen(D),
;             8=Katapult, 9=Blutsauger, 10=Axtmänner, 11=Feldherr(D),
;             12=Lindwurm, 13=Rammbock, 14=Wagenfahrer, 15=Wolfsreiter
; -----------------------------------------------------------------------------

; $0BC3: River (Fluss) movement costs - terrain char $6B
        .byte $04, $04, $01, $04, $01, $04, $04, $02, $04, $01, $02, $02, $04, $04, $05, $02

; $0BD3: Forest (Wald) movement costs - terrain char $6C
        .byte $02, $02, $01, $03, $00, $04, $02, $02, $04, $01, $02, $02, $01, $03, $07, $02

; $0BE3: Swamp (Sumpf) movement costs - terrain char $6E
        .byte $03, $03, $01, $03, $00, $04, $03, $03, $04, $01, $03, $03, $01, $04, $07, $04
