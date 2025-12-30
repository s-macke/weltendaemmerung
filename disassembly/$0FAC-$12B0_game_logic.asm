; =============================================================================
; Core Game Logic and Data Tables
; Address range: $0FAC - $12B0
; =============================================================================
;
; UNIT STAT TABLES (BCD encoded values):
; --------------------------------------
; $1017 (16 bytes) - V (Verteidigung/Defense) - stored in unit[2], can change
; $1027 (16 bytes) - R (Reichweite/Range) - constant, read from table
; $1037 (16 bytes) - B (Bewegung/Movement) - stored in unit[3]/[4]
; $1047 (16 bytes) - A (Angriff/Attack) - constant, read from table
;
; Unit types (index 0-15):
;   0=Schwertträger, 1=Bogenschützen, 2=Adler, 3=Lanzenträger,
;   4=Kriegsschiff, 5=Reiterei, 6=Katapult, 7=Blutsauger,
;   8=Axtmänner, 9=Feldherr, 10=Lindwurm, 11=Rammbock,
;   12=Wagenfahrer, 13=Wolfsreiter, 14=Unit14, 15=Unit15
;
; UNIT PLACEMENT DATA ($1057-$11A6):
; ----------------------------------
; Initial unit positions for both players (Feldoin and Dailor).
; Format:
;   $8X       - Unit type marker (X = 0-15)
;   X, Y      - Coordinate pairs for each unit of that type
;   ...       - More X,Y pairs
;   $8X       - Next unit type
;   ...
;   $FF       - End of data
;
; Units with X < 40 belong to Feldoin (Player 1, left side)
; Units with X >= 40 belong to Dailor (Player 2, right side)
;
; Total: 292 units (Feldoin: 128, Dailor: 164)
; =============================================================================

; -----------------------------------------------------------------------------
; sub_0FAC - Initialize Units from Placement Data
; -----------------------------------------------------------------------------
; Reads placement table at $1057 and creates unit records at $5FA0.
; Unit record structure (6 bytes):
;   [0] X coordinate    [1] Y coordinate
;   [2] V (defense)     [3] B current (movement)
;   [4] B max           [5] Original terrain
; -----------------------------------------------------------------------------
sub_0FAC:
        LDA #$57
        STA $F7                 ; Placement data pointer lo ($1057)
        LDA #$10
        STA $F8                 ; Placement data pointer hi
        JSR sub_15C2            ; Init unit record pointer ($F9=$5FA0)

loc_0FB7:
        LDA ($F7),Y             ; Read from placement data
        BMI L1003               ; If >= $80, it's a unit type marker
        STA ($F9),Y             ; Store X coord → unit[0]
        PHA
        JSR sub_177A            ; Advance unit pointer
        JSR sub_1781            ; Advance placement pointer
        LDA ($F7),Y             ; Read Y coord from placement
        STA ($F9),Y             ; Store Y coord → unit[1]
        PHA
        JSR sub_177A            ; Advance unit pointer
        JSR sub_1781            ; Advance placement pointer
        LDX $034E               ; Get unit type index
        LDA $1017,X             ; Load V (defense) from stat table
        STA ($F9),Y             ; Store V → unit[2]
        JSR sub_177A            ; Advance unit pointer
        LDA $1037,X             ; Load B (movement) from stat table
        STA ($F9),Y             ; Store B current → unit[3]
        JSR sub_177A            ; Advance unit pointer
        STA ($F9),Y             ; Store B max → unit[4] (same value)
        JSR sub_177A            ; Advance unit pointer
        PLA                     ; Restore Y coord
        JSR sub_1AD3            ; Calculate map offset
        PLA                     ; Restore X coord
        TAY
        LDA ($B4),Y             ; Read original terrain from map
        TAX                     ; Save terrain in X
        LDA $034E               ; Get unit type
        CLC
        ADC #$74                ; Convert to tile char ($74-$83)
        STA ($B4),Y             ; Place unit on map
        LDY #$00
        TXA                     ; Get saved terrain
        STA ($F9),Y             ; Store terrain → unit[5]
        JSR sub_177A            ; Advance to next unit record
        JMP loc_0FB7            ; Process next unit

L1003:                          ; Handle unit type marker ($8X)
        CMP #$FF                ; Check for end marker
        BEQ L1012
        AND #$1F                ; Extract unit type (0-15)
        STA $034E               ; Store as current unit type
        JSR sub_1781            ; Advance placement pointer
        JMP loc_0FB7

L1012:                          ; End of placement data
        LDY #$04
        STA ($F9),Y             ; Mark end of unit list (0 in unit[4])
        RTS

; -----------------------------------------------------------------------------
; Unit Stat Tables (BCD encoded, 16 bytes each)
; Display order: R B A V | Table address order: V R B A
; -----------------------------------------------------------------------------
; $1017 - V (Verteidigung/Defense) - stored in unit[2], decreases when hit
;         Schwert Bogen Adler Lanze Schif Reite Katap Bluts Axtmä Feldh Lindw Rambo Wagen Wolfs Unt14 Unt15
        .byte $16, $12, $11, $14, $18, $10, $16, $12, $05, $10, $16, $16, $30, $05, $16, $18
;       BCD:   16   12   11   14   18   10   16   12    5   10   16   16   30    5   16   18

; $1027 - R (Reichweite/Range) - constant, read from table during display
        .byte $01, $08, $02, $02, $08, $05, $01, $08, $12, $01, $01, $01, $02, $01, $07, $03
;       BCD:    1    8    2    2    8    5    1    8   12    1    1    1    2    1    7    3

; $1037 - B (Bewegung/Movement) - stored in unit[3] (current) and unit[4] (max)
        .byte $10, $10, $12, $10, $08, $15, $10, $10, $09, $12, $10, $10, $10, $10, $14, $12
;       BCD:   10   10   12   10    8   15   10   10    9   12   10   10   10   10   14   12

; $1047 - A (Angriff/Attack) - constant, read from table during display
        .byte $04, $05, $07, $05, $20, $06, $06, $05, $01, $08, $04, $06, $30, $01, $10, $08
;       BCD:    4    5    7    5   20    6    6    5    1    8    4    6   30    1   10    8

; -----------------------------------------------------------------------------
; Unit Placement Data ($1057)
; -----------------------------------------------------------------------------
        .byte $80, $0C, $08, $0D, $08, $0E, $08, $10, $08, $11, $08, $12, $08, $14, $08, $15  ; ................
        .byte $08, $16, $08, $18, $08, $19, $08, $1A, $08, $0C, $0A, $0D, $0A, $0E, $0A, $0F  ; ................
        .byte $0A, $10, $0A, $11, $0A, $12, $0A, $13, $0A, $14, $0A, $15, $0A, $16, $0A, $17  ; ................
        .byte $0A, $18, $0A, $19, $0A, $1A, $0A, $81, $0C, $06, $0D, $06, $0E, $06, $10, $06  ; ................
        .byte $11, $06, $12, $06, $14, $06, $15, $06, $16, $06, $18, $06, $19, $06, $1A, $06  ; ................
        .byte $0C, $21, $0D, $21, $0E, $21, $0F, $21, $10, $21, $11, $21, $12, $21, $13, $21  ; .!.!.!.!.!.!.!.!
        .byte $14, $21, $15, $21, $16, $21, $2D, $12, $2D, $16, $10, $1D, $11, $1D, $12, $1D  ; .!.!.!-.-.......
        .byte $10, $1E, $11, $1E, $12, $1E, $10, $1F, $11, $1F, $12, $1F, $82, $1D, $0D, $1E  ; ................
        .byte $0E, $1F, $0F, $20, $10, $20, $11, $1F, $11, $1E, $11, $1D, $11, $1D, $17, $1E  ; ... . ..........
        .byte $17, $1F, $17, $20, $17, $20, $18, $1F, $19, $1E, $1A, $1D, $1B, $83, $0C, $07  ; ... . ..........
        .byte $0D, $07, $0E, $07, $10, $07, $11, $07, $12, $07, $14, $07, $15, $07, $16, $07  ; ................
        .byte $18, $07, $19, $07, $1A, $07, $34, $14, $0C, $1D, $0D, $1D, $0E, $1D, $0C, $1E  ; ......4.........
        .byte $0D, $1E, $0E, $1E, $0C, $1F, $0D, $1F, $0E, $1F, $14, $1D, $15, $1D, $16, $1D  ; ................
        .byte $14, $1F, $15, $1F, $16, $1F, $14, $1E, $15, $1E, $16, $1E, $84, $26, $13, $27  ; .............&.'
        .byte $13, $2F, $13, $2F, $15, $27, $15, $26, $15, $85, $13, $0F, $14, $0F, $15, $0F  ; ././.'.&........
        .byte $13, $10, $14, $10, $15, $10, $13, $11, $14, $11, $15, $11, $13, $17, $14, $17  ; ................
        .byte $15, $17, $13, $18, $14, $18, $15, $18, $13, $19, $14, $19, $15, $19, $86, $13  ; ................
        .byte $0C, $87, $47, $09, $47, $0A, $47, $0B, $47, $0C, $47, $0D, $47, $0E, $47, $0F  ; ..g.g.g.g.g.g.g.
        .byte $47, $10, $47, $11, $47, $12, $47, $13, $47, $14, $47, $15, $47, $16, $47, $17  ; g.g.g.g.g.g.g.g.
        .byte $47, $18, $47, $19, $47, $1A, $47, $1B, $4C, $04, $4C, $05, $4C, $06, $4C, $07  ; g.g.g.g.l.l.l.l.
        .byte $4C, $09, $4C, $0A, $4C, $0B, $4C, $0C, $4C, $13, $4C, $14, $4C, $15, $4C, $16  ; l.l.l.l.l.l.l.l.
        .byte $4C, $18, $4C, $19, $4C, $1A, $4C, $1B, $88, $4E, $0A, $4E, $0B, $4E, $14, $4E  ; l.l.l.l..n.n.n.n
        .byte $15, $89, $89, $4A, $01, $4B, $01, $4A, $02, $4B, $02, $4C, $02, $4D, $02, $4E  ; ...j.k.j.k.l.m.n
        .byte $02, $4A, $1D, $4B, $1D, $4C, $1D, $4D, $1D, $4E, $1D, $4A, $1E, $4B, $1E, $46  ; .j.k.l.m.n.j.k.f
        .byte $0B, $46, $0C, $46, $0D, $46, $17, $46, $18, $46, $19, $8A, $49, $04, $4A, $04  ; .f.f.f.f.f..i.j.
        .byte $4B, $04, $49, $05, $4A, $05, $4B, $05, $49, $06, $4A, $06, $4B, $06, $49, $07  ; k.i.j.k.i.j.k.i.
        .byte $4A, $07, $4B, $07, $49, $0A, $4A, $0A, $4B, $0A, $49, $0B, $4A, $0B, $4B, $0B  ; j.k.i.j.k.i.j.k.
        .byte $49, $0C, $4A, $0C, $4B, $0C, $49, $09, $4A, $09, $4B, $09, $49, $0E, $4A, $0E  ; i.j.k.i.j.k.i.j.
        .byte $4B, $0E, $49, $0F, $4A, $0F, $4B, $0F, $49, $10, $4A, $10, $4B, $10, $49, $11  ; k.i.j.k.i.j.k.i.
        .byte $4A, $11, $4B, $11, $49, $13, $4A, $13, $4B, $13, $49, $14, $4A, $14, $4B, $14  ; j.k.i.j.k.i.j.k.
        .byte $49, $15, $4A, $15, $4B, $15, $49, $16, $4A, $16, $4B, $16, $49, $18, $4A, $18  ; i.j.k.i.j.k.i.j.
        .byte $4B, $18, $49, $19, $4A, $19, $4B, $19, $49, $1A, $4A, $1A, $4B, $1A, $49, $1B  ; k.i.j.k.i.j.k.i.
        .byte $4A, $1B, $4B, $1B, $46, $0E, $46, $0F, $46, $10, $46, $14, $46, $15, $46, $16  ; j.k.f.f.f.f.f.f.
        .byte $8B, $45, $12, $8C, $4E, $0F, $4E, $10, $8D, $4D, $0A, $4D, $0B, $4D, $14, $4D  ; .e..n.n..m.m.m.m
        .byte $15, $8E, $4D, $09, $4E, $09, $4D, $0C, $4E, $0C, $4D, $13, $4E, $13, $4D, $16  ; ..m.n.m.n.m.n.m.
        .byte $4E, $16, $8F, $4D, $04, $4E, $04, $4D, $05, $4E, $05, $4D, $06, $4E, $06, $4D  ; n..m.n.m.n.m.n.m
        .byte $07, $4E, $07, $4D, $18, $4E, $18, $4D, $19, $4E, $19, $4D, $1A, $4E, $1A, $4D  ; .n.m.n.m.n.m.n.m
        .byte $1B, $4E, $1B, $46, $11, $46, $12, $46, $13, $FF  ; .n.f.f.f..
