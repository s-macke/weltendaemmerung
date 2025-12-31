; =============================================================================
; Combat System and Turn Management
; Address range: $12B1 - $15CC
; =============================================================================
;
; CURSOR/SPRITE COLOR STATE MACHINE (VIC_SP0COL / $D027)
; -------------------------------------------------------
; The cursor sprite (Sprite 0) color indicates the current attack state:
;
;   $01 = Normal        - Default cursor state, no attack in progress
;   $0A = Attack Select - Attacker selected, waiting for target selection
;   $FA = Attack Execute- Target selected, execute combat on next fire button
;   $F1 = Movement      - Movement mode indicator (used in movement phase)
;
; State Transitions:
;   Normal ($01) --[fire on own unit]--> Attack Select ($0A)
;   Attack Select ($0A) --[fire on enemy]--> Attack Execute ($FA)
;   Attack Execute ($FA) --[combat resolved]--> Normal ($01)
;   Attack Select ($0A) --[fire on empty/invalid]--> Normal ($01)
;
; =============================================================================

; -----------------------------------------------------------------------------
; sub_12B1 - Combat Idle Animation Entry
; -----------------------------------------------------------------------------
; Called during idle to animate owned units. Toggles cursor/sprite color bit 0
; to create a flashing effect for the selected unit.
; -----------------------------------------------------------------------------
sub_12B1:
        JSR sub_12D4            ; Check if unit belongs to current player
        BCC L12D3               ; Not owned -> return

loc_12B6:
        LDA VIC_SP0COL          ; Toggle cursor/sprite color bit 0
        EOR #$01                ; Creates flashing effect
        STA VIC_SP0COL
        BEQ L12D3               ; If color became 0, skip animation

; -----------------------------------------------------------------------------
; sub_12C0 - Idle Unit Animation
; -----------------------------------------------------------------------------
; Animates the unit at cursor during idle. Special handling for Feldherren
; (Commanders) which use a different animation pattern.
; Unit $11 = Eldoin's Feldherr, $16 = Dailor's Feldherr
; -----------------------------------------------------------------------------
sub_12C0:
        LDX $034F               ; ACTION_UNIT (unit in action)
        CPX #$11                ; Eldoin's Feldherr?
        BEQ L12CB               ; -> special animation
        CPX #$16                ; Dailor's Feldherr?
        BNE L12D0               ; No -> normal animation

L12CB:
        LDA #$20                ; Feldherr uses character $20
        JMP sub_1CE4            ; Display with special handling

L12D0:
        JSR sub_1CE2            ; Normal unit animation

L12D3:
        RTS

; -----------------------------------------------------------------------------
; sub_12D4 - Check Unit Ownership
; -----------------------------------------------------------------------------
; Verifies if the unit at cursor belongs to the current player.
; Eldoin (player 0) owns ACTION_UNIT $0B-$11 (unit types 0-6)
; Dailor (player 1) owns ACTION_UNIT $12-$1A (unit types 7-15)
;
; Input:  None (reads $034F and $0347)
; Output: Carry Set = unit belongs to current player
;         Carry Clear = unit does NOT belong to current player
; -----------------------------------------------------------------------------
sub_12D4:
        LDX $034F               ; ACTION_UNIT (unit in action)
        LDA $0347               ; CURRENT_PLAYER (active player)

; sub_12DA - Ownership check with player in A, unit in X
sub_12DA:
        BEQ L12E2               ; Player 0 (Eldoin)?
        ; Player 1 (Dailor): owns units >= $12
        CPX #$12
        BCC L12EA               ; X < $12 -> not Dailor's (CLC)
        BCS L12EC               ; X >= $12 -> is Dailor's (SEC)

L12E2:  ; Player 0 (Eldoin): owns units $0B-$11
        CPX #$0B
        BCC L12EA               ; X < $0B -> not a unit (CLC)
        CPX #$12
        BCC L12EC               ; $0B <= X < $12 -> is Eldoin's (SEC)

L12EA:
        CLC                     ; Not owned
        RTS

L12EC:
        SEC                     ; Owned by current player
        RTS

; -----------------------------------------------------------------------------
; sub_12EE - Initiate Attack / Process Attack Target
; -----------------------------------------------------------------------------
; Main attack handler called when fire button is pressed on a unit.
;
; State Machine:
;   1. If cursor/sprite color = $FA (attack execute mode):
;      -> Jump to L1328 to execute the attack
;   2. If cursor/sprite color != $FA (normal/select mode):
;      -> Validate unit ownership
;      -> Check unit has movement points (unit[3] != 0)
;      -> Set sprite to $0A (attack select mode)
;      -> Store attacker coordinates and pointer
;
; Variables Set:
;   $0355 = Attacker X coordinate
;   $0356 = Attacker Y coordinate
;   $0357 = Attacker unit type (0-15)
;   $0358-$0359 = Pointer to attacker's unit record
; -----------------------------------------------------------------------------
sub_12EE:
        LDA VIC_SP0COL
        CMP #$FA                ; Attack execute mode?
        BEQ L1328               ; Yes -> execute attack on target
        JSR sub_12D4            ; Check ownership
        BCC L12EA               ; Not owned -> return (CLC)
        JSR sub_1FF6            ; Get unit record pointer
        LDY #$03
        LDA ($F9),Y             ; Load unit[3] = movement points
        BEQ L1327               ; No movement points -> can't attack
        LDA #$0A
        STA VIC_SP0COL          ; Set cursor/sprite to "attack select" color
        LDA $034B               ; CURSOR_MAP_X (cursor X on map)
        STA $0355               ; Store as attack source X
        LDA $034C               ; CURSOR_MAP_Y (cursor Y on map)
        STA $0356               ; Store as attack source Y
        LDA $F9                 ; TEMP_PTR2 (general ptr lo)
        STA $0358               ; Store attacker pointer lo
        LDA $FA                 ; TEMP_PTR2 (general ptr hi)
        STA $0359               ; Store attacker pointer hi
        LDA $034F               ; ACTION_UNIT (unit in action)
        SEC
        SBC #$0B                ; Convert to unit type (0-15)
        STA $0357               ; Store attacker type

L1327:
        RTS

; -----------------------------------------------------------------------------
; L1328 - Execute Attack on Target
; -----------------------------------------------------------------------------
; Called when fire is pressed in attack execute mode ($FA).
; First validates range via sub_13AE, then checks for special attacks:
;
; STRUCTURE ATTACKERS (can destroy gates/fortifications):
;   Type $08 = Katapult (Catapult) - gates + walls
;   Type $0C = Lindwurm (Dragon) - gates + walls
;   Type $0D = Rammbock (Battering Ram) - gates only
;
; STRUCTURE TARGETS:
;   Index $09 = Mauer (Wall, char $72) -> destroyed by Katapult/Lindwurm only
;   Index $06 = Tor (Gate, char $6F) -> decrements gate counter, replaces with pavement
;
; For normal unit attacks, validates target is enemy unit then jumps to L1373.
; -----------------------------------------------------------------------------
L1328:
        JSR sub_13AE            ; Range check (returns if out of range)
        LDX $034F               ; ACTION_UNIT at target (defender)
        LDA $0357               ; ATTACKER_TYPE
        CMP #$08                ; Katapult?
        BEQ L134C               ; -> can attack structures
        CMP #$0C                ; Lindwurm?
        BEQ L134C               ; -> can attack structures
        CMP #$0D                ; Rammbock?
        BEQ L1350               ; -> can attack gates only

L133D:  ; Normal attack - verify target is enemy unit
        LDA $0347               ; CURRENT_PLAYER
        EOR #$01                ; Flip to get enemy player
        AND #$01
        JSR sub_12DA            ; Check if target belongs to enemy
        BCS L1373               ; Yes -> proceed with damage calc

L1349:
        JMP loc_13A6            ; Invalid target -> reset and return

L134C:  ; Katapult/Lindwurm structure attack
        CPX #$09                ; Target is Wall (Mauer) tile?
        BEQ L1361               ; -> destroy it directly

L1350:  ; Rammbock gate attack (gates only, not walls)
        CPX #$06                ; Target is gate tile?
        BNE L133D               ; No -> try normal attack
        LDA $034B               ; CURSOR_MAP_X
        CMP #$3C                ; X < 60 (Eldoin's territory)?
        BCS L1349               ; No -> can't destroy enemy gates
        JSR sub_0F8C            ; Get gate index
        DEC $4FF2,X             ; Decrement gate counter

L1361:  ; Structure destroyed
        LDA $0357               ; ATTACKER_TYPE
        JSR sub_15AC            ; Display attacker name
        JSR sub_2263            ; Play destruction sound
        JSR sub_1445            ; Clear attacker's movement
        LDA #$71                ; Pavement tile
        PHA                     ; Save for map update
        JMP loc_140E            ; Update map display

; -----------------------------------------------------------------------------
; L1373 - Calculate and Apply Combat Damage
; -----------------------------------------------------------------------------
; Performs the actual damage calculation for unit-vs-unit combat:
;   1. Display attacker and defender names
;   2. Clear attacker's movement points (attack consumes turn)
;   3. Look up base Attack (A) value from $1047 table
;   4. Add random modifier (0-4) via sub_1567
;   5. Subtract damage from defender's Defense (V) using BCD math
;   6. If defense <= 0 or underflows -> unit destroyed (L13FD)
;   7. Otherwise store reduced defense
;
; Damage Formula: damage = Attack[attacker_type] + random(0-4)
; New Defense: defense = defense - damage (BCD subtraction)
; -----------------------------------------------------------------------------
L1373:
        LDA $0357               ; ATTACKER_TYPE
        JSR sub_15AC            ; Display attacker unit name
        LDA $034F               ; ACTION_UNIT (defender)
        SEC
        SBC #$0B                ; Convert to unit type
        JSR sub_15AC            ; Display defender unit name
        JSR sub_1445            ; Clear attacker's movement points
        LDX $0357               ; ATTACKER_TYPE
        LDA $1047,X             ; Load base Attack value (A)
        JSR sub_1567            ; Add random modifier (0-4)
        STA $035C               ; Store total damage
        JSR sub_1FF6            ; Find defender's unit record
        LDY #$02
        LDA ($F9),Y             ; Load unit[2] = defender's defense (V)
        SED                     ; Enable decimal mode for damage calc
        SEC
        SBC $035C               ; BCD subtract: defense = defense - damage
        CLD                     ; Disable decimal mode
        BEQ L13FD               ; If result = 0, unit destroyed
        CMP #$5A                ; Check for underflow (BCD: $5A = negative)
        BCS L13FD               ; If underflow, unit destroyed
        STA ($F9),Y             ; Store reduced defense back to unit[2]

; -----------------------------------------------------------------------------
; loc_13A6 - Reset After Combat
; -----------------------------------------------------------------------------
; Resets cursor/sprite color to normal ($01) and refreshes display.
; Called after combat resolves or when attack is cancelled.
; -----------------------------------------------------------------------------
loc_13A6:
        LDA #$01
        STA VIC_SP0COL          ; Reset to normal cursor/sprite color
        JMP sub_1EE2            ; Refresh display

; -----------------------------------------------------------------------------
; sub_13AE - Range Check (Euclidean Distance)
; -----------------------------------------------------------------------------
; Calculates distance between attacker and target using BASIC ROM float routines:
;   distance = sqrt((src_x - dest_x)² + (src_y - dest_y)²)
;
; The result is compared against the unit's Range (R) value from the $1027 table.
;
; BCD TO BINARY CONVERSION QUIRK:
; The Range table at $1027 stores BCD values (for display purposes).
; The Euclidean distance result is a regular binary integer.
; Most range values (1,2,3,5,7,8) are identical in BCD and binary.
; However, the Catapult has Range BCD $12 (displays as "12"), which would
; incorrectly compare as 18 in binary. The code explicitly converts:
;   BCD $12 -> Binary $0C (both represent decimal 12)
; This ensures the Catapult's effective range matches its displayed range.
; -----------------------------------------------------------------------------
sub_13AE:
        LDA $0355               ; ATTACK_SRC_X (attack source X)
        SEC
        SBC $034B               ; CURSOR_MAP_X (cursor X on map)
        JSR $BC3C               ; Convert signed byte to FAC
        JSR $BC0C               ; Absolute value
        LDA $61                 ; FAC_MANTISSA (math calc)
        JSR $BA2B               ; Square the value
        JSR $BBCA               ; Store to temp
        LDA $0356               ; ATTACK_SRC_Y (attack source Y)
        SEC
        SBC $034C               ; CURSOR_MAP_Y (cursor Y on map)
        JSR $BC3C               ; Convert signed byte to FAC
        JSR $BC0C               ; Absolute value
        LDA $61                 ; FAC_MANTISSA (math calc)
        JSR $BA2B               ; Square the value
        LDA #$57
        LDY #$00
        JSR $BA8C               ; Add dx² + dy²
        LDA $61                 ; FAC_MANTISSA (math calc)
        JSR $B86A               ; Move to FAC
        JSR $BF71               ; Square root
        JSR $BC9B               ; Convert to integer -> $65
        LDX $0357               ; ATTACKER_TYPE (attacker type)
        LDA $1027,X             ; Load Range from BCD table
        CMP #$12                ; Is it BCD $12 (Catapult)?
        BNE L13F3               ; No - use value as-is
        LDA #$0C                ; Yes - convert BCD 12 to binary 12

L13F3:
        CMP $65                 ; ARG_MANTISSA (math calc)
        BCS L13FC
        PLA
        PLA
        JMP loc_13A6

L13FC:
        RTS

; -----------------------------------------------------------------------------
; L13FD - Handle Unit Destruction
; -----------------------------------------------------------------------------
; Called when a unit's defense reaches 0 or underflows.
;   1. Play destruction sound effect
;   2. Mark unit as dead (Y coordinate = $FF)
;   3. Get original terrain from unit[5]
;   4. Play high pitch sound effect
;   5. Update map display (restore terrain)
; -----------------------------------------------------------------------------
L13FD:
        JSR sub_20FB            ; Play destruction sound
        LDA #$FF
        LDY #$01
        STA ($F9),Y             ; Mark unit dead: unit[1] = $FF
        LDY #$05
        LDA ($F9),Y             ; Load unit[5] = original terrain
        PHA                     ; Save terrain for map restore
        JSR sub_2197            ; Play high pitch sound effect

; -----------------------------------------------------------------------------
; loc_140E - Update Map After Unit Removal
; -----------------------------------------------------------------------------
; Restores the original terrain tile on the map after a unit is destroyed
; or a structure is demolished. Also checks for victory conditions.
;
; Entry: Terrain tile on stack (from PHA)
; -----------------------------------------------------------------------------
loc_140E:
        JSR sub_1F1C            ; Get screen position for cursor
        JSR sub_1F77            ; Calculate screen offset
        PLA
        PHA
        STA ($D1),Y             ; Write terrain char to screen RAM
        JSR sub_1C01            ; Get terrain color
        STA ($F3),Y             ; Write color to color RAM
        LDX $034C               ; CURSOR_MAP_Y
        JSR sub_0F82            ; Get map data pointer
        PLA
        STA ($B4),Y             ; Write terrain to map data
        LDX $0347               ; CURRENT_PLAYER
        LDA $034F               ; ACTION_UNIT (destroyed unit type)
        CMP #$11                ; Was it Eldoin's Feldherr?
        BEQ loc_1456            ; Yes -> Dailor wins!
        LDA $0347               ; CURRENT_PLAYER
        BNE L1442               ; Dailor attacking -> skip count
        DEC $4FF0               ; Decrement Dailor unit count
        BNE L1442               ; Still units left -> continue
        LDA #$01                ; No Dailor units left
        STA $034F               ; Set flag for Eldoin victory
        JMP loc_1456            ; -> Eldoin wins!

L1442:
        JMP loc_13A6            ; Return to normal state

; -----------------------------------------------------------------------------
; sub_1445 - Clear Attacker Movement Points
; -----------------------------------------------------------------------------
; Sets the attacker's current movement points to 0, preventing further
; attacks this phase. Called after an attack is executed.
;
; Uses stored attacker pointer from $0358-$0359.
; -----------------------------------------------------------------------------
sub_1445:
        LDA $0358               ; ATTACKER_PTR lo
        STA $F9                 ; Set up pointer
        LDA $0359               ; ATTACKER_PTR hi
        STA $FA
        LDY #$03
        LDA #$00
        STA ($F9),Y             ; unit[3] = 0 (no movement left)
        RTS

; -----------------------------------------------------------------------------
; loc_1456 - Victory Screen
; -----------------------------------------------------------------------------
; Displays the victory screen when a player wins the game.
; Triggered by:
;   - Eldoin's Feldherr destroyed -> Dailor wins
;   - All Dailor units destroyed -> Eldoin wins
;
; Plays victory fanfare, displays winner message, waits for keypress,
; then restarts the game.
; -----------------------------------------------------------------------------
loc_1456:
        LDX #$02
        JSR sub_1581            ; Short delay
        JSR sub_1CE2            ; Final animation frame
        JSR sub_209C            ; Prepare victory display
        LDX #$00

; loc_1463 - Victory Fanfare Loop
; Plays a 7-note victory melody using all 3 SID voices
loc_1463:
        LDA $1512,X             ; Voice 1 frequency lo
        STA SID_V1FREQL
        LDA $1513,X             ; Voice 1 frequency hi
        STA SID_V1FREQH
        LDA $1514,X             ; Voice 2 frequency lo
        STA SID_V2FREQL
        LDA $1515,X             ; Voice 2 frequency hi
        STA SID_V2FREQH
        LDA $1516,X             ; Voice 3 frequency lo
        STA SID_V3FREQL
        LDA $1517,X             ; Voice 3 frequency hi
        STA SID_V3FREQH
        TXA
        PHA
        LDX #$0A
        JSR sub_1581            ; Note duration delay
        PLA
        CLC
        ADC #$06                ; Next note (6 bytes per chord)
        CMP #$2A                ; 7 notes * 6 = 42 ($2A)
        BEQ L149A               ; Done with fanfare
        TAX
        JMP loc_1463            ; Next note

L149A:  ; End of fanfare - prepare victory screen
        JSR sub_2263            ; Stop sound
        LDA #$00
        STA VIC_IRQMSK          ; Disable VIC interrupts
        STA VIC_VICIRQ
        STA VIC_SPENA           ; Disable sprites
        LDA #$07
        STA SID_RESFLT          ; Reset SID filter
        LDX #$01
        STX VIC_EXTCOL          ; Flash screen white
        STX VIC_BGCOL0
        LDY #$00
        JSR sub_1CF3            ; Delay
        DEX
        STX VIC_EXTCOL          ; Screen back to black
        STX VIC_BGCOL0
        JSR BASIC_CLRSCR        ; Clear screen
        LDX #$06
        JSR sub_1581            ; Delay
        LDX #$09                ; Column 9
        LDY #$10                ; Row 16
        JSR $E50C               ; Position cursor
        LDX #$00

L14D2:  ; Print victory message "SIEG... HERREN VON THAINFAL SIND NUN DIE"
        LDA $153C,X             ; Victory text at $153C
        JSR CHROUT              ; Print character
        INX
        CPX #$2B                ; 43 characters
        BNE L14D2
        LDX #$0C                ; Column 12
        LDY #$0F                ; Row 15
        JSR $E50C               ; Position cursor
        LDA $034F               ; ACTION_UNIT (victory flag)
        CMP #$11                ; Eldoin's Feldherr killed?
        BNE L14F3               ; No -> Eldoin won
        LDX #$09                ; Dailor won - display "DAILOR"
        JSR sub_1E8B
        JMP loc_14F8

L14F3:  ; Eldoin won
        LDX #$00                ; Display "ELDOIN"
        JSR sub_1E8B

loc_14F8:
        SEI
        LDA #$31                ; Restore default IRQ vector
        STA IRQ_VECTOR_LO
        LDA #$EA
        STA IRQ_VECTOR_HI
        CLI

L1504:  ; Wait for keypress
        JSR GETIN
        BEQ L1504               ; Loop until key pressed
        LDX #$F6
        TXS                     ; Reset stack pointer
        JSR sub_23BD            ; Cleanup
        JMP loc_080D            ; Restart game
        .byte $DB, $20, $14, $1A, $67, $11, $45, $1D, $ED, $15, $67, $11, $14, $1A, $89, $13  ; . ..g.e...g.....
        .byte $81, $0F, $ED, $15, $81, $0F, $0A, $0D, $3B, $17, $67, $11, $A2, $0E, $3B, $17  ; ........;.g...;.
        .byte $89, $13, $81, $0F, $3B, $17, $67, $11, $9E, $0B, $9E, $53, $49, $45, $47, $0D  ; ....;.g....sieg.
        .byte $0D, $05, $20, $20, $20, $48, $45, $52, $52, $45, $4E, $20, $56, $4F, $4E, $20  ; ..   herren von
        .byte $54, $48, $41, $49, $4E, $46, $41, $4C, $20, $53, $49, $4E, $44, $20, $4E, $55  ; thainfal sind nu
        .byte $4E, $20, $44, $49, $45  ; n die

; -----------------------------------------------------------------------------
; sub_1567 - Add Combat Modifier from ROM Sequence
; -----------------------------------------------------------------------------
; Adds a modifier (0-4) to attack value using BCD arithmetic.
; Uses self-modifying code to read successive bytes from KERNAL ROM ($E000+),
; creating a deterministic but varied sequence.
; Input: A = base attack value
; Output: A = attack value + modifier (BCD)
; -----------------------------------------------------------------------------
sub_1567:
        PHA
        LDA $E000               ; Read byte from KERNAL ROM (address modified below)
        AND #$07                ; Mask to 0-7 for table index
        INC $1569               ; Self-modify: increment address low byte ($E000→$E001→...)
        TAX                     ; X = index into modifier table
        PLA                     ; Restore attack value
        CLC
        SED                     ; Enable decimal mode
        ADC $1579,X             ; BCD add: attack = attack + modifier
        CLD                     ; Disable decimal mode
        RTS
; Modifier table indexed by (ROM byte & 7): values 0,1,1,2,2,3,3,4
; Distribution: 0=12.5%, 1=25%, 2=25%, 3=25%, 4=12.5%  Average=2.0
        .byte $00, $01, $01, $02, $02, $03, $03, $04

; -----------------------------------------------------------------------------
; sub_1581 - Delay Loop
; -----------------------------------------------------------------------------
; Simple delay routine. Loops X times, calling sub_1CF3 each iteration.
; Used for timing in animations and sound playback.
;
; Input: X = number of iterations
; -----------------------------------------------------------------------------
sub_1581:
        LDY #$00
        JSR sub_1CF3            ; Inner delay
        DEX
        BNE sub_1581
        RTS

; Victory fanfare frequency data (7 chords × 6 bytes = 42 bytes)
; Each chord: V1_lo, V1_hi, V2_lo, V2_hi, V3_lo, V3_hi
        .byte $29, $21, $D1, $21, $78, $21, $A4, $21, $D1, $21, $29, $21, $29, $21, $D1, $21  ; )!Q!x!.!Q!)!)!Q!
        .byte $15, $22, $78, $21, $29, $21, $29, $21, $5B, $21, $FD, $21, $D1, $21, $31, $22  ; ."x!)!)![!.!Q!1"
        .byte $63, $22  ; c"

; -----------------------------------------------------------------------------
; sub_15AC - Display Combat Unit Name
; -----------------------------------------------------------------------------
; Displays the name of a unit type during combat.
; Uses a pointer table at $158A to look up unit name strings.
;
; Input: A = unit type (0-15)
; Output: Unit name printed to screen
; -----------------------------------------------------------------------------
sub_15AC:
        ASL A                   ; Multiply by 2 (pointer table index)
        TAX
        LDA $158A,X             ; Load string pointer lo
        STA $15BB               ; Self-modify JSR target
        LDA $158B,X             ; Load string pointer hi
        STA $15BC
        JSR $0457               ; Print string (address modified above)
        LDX #$04
        JMP sub_1581            ; Short delay after display

; -----------------------------------------------------------------------------
; sub_15C2 - Initialize Unit Record Pointer
; -----------------------------------------------------------------------------
; Sets TEMP_PTR2 ($F9-$FA) to point to the start of unit data at $5FA0.
; Called before iterating through unit records.
;
; Output: $F9-$FA = $5FA0, Y = 0
; -----------------------------------------------------------------------------
sub_15C2:
        LDA #$A0
        STA $F9                 ; TEMP_PTR2 lo = $A0
        LDA #$5F
        STA $FA                 ; TEMP_PTR2 hi = $5F -> $5FA0
        LDY #$00
        RTS
