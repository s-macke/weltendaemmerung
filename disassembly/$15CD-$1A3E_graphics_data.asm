; =============================================================================
; Character Graphics and Pattern Data
; Address range: $15CD - $1A3E
; =============================================================================
;
; CUSTOM CHARACTER SET LAYOUT:
; ---------------------------
; 38 custom 8x8 pixel tiles are stored here and copied to $E2F0 at runtime.
; Since character set base is at $E000, these tiles map to character codes:
;   - Tile 0-10  -> Char $5E-$68 (94-104)  -> Color: Dark Gray ($0B) -> UI/Border
;   - Tile 11-12 -> Char $69-$6A (105-106) -> Color: Black ($00)     -> Terrain
;   - Tile 13    -> Char $6B (107)         -> Color: Blue ($06)      -> Terrain
;   - Tile 14    -> Char $6C (108)         -> Color: Red ($02)       -> Terrain
;   - Tile 15    -> Char $6D (109)         -> Color: White ($01)     -> Terrain
;   - Tile 16    -> Char $6E (110)         -> Color: Blue ($06)      -> Terrain
;   - Tile 17-21 -> Char $6F-$73 (111-115) -> Color: Dark Gray ($0B) -> Terrain
;   - Tile 22-28 -> Char $74-$7A (116-122) -> Color: Yellow ($07)    -> Unit icons
;   - Tile 29-37 -> Char $7B-$83 (123-131) -> Color: Black ($00)     -> Unit icons
;
; TERRAIN TYPE MAPPING (terrain_index = char_code - $69):
; -------------------------------------------------------
;   Tile 11 -> Char $69 -> Index 0 -> Wiese (Meadow)
;   Tile 12 -> Char $6A -> Index 1 -> Fluss (River)
;   Tile 13 -> Char $6B -> Index 2 -> Wald (Forest)
;   Tile 14 -> Char $6C -> Index 3 -> Ende (Edge)
;   Tile 15 -> Char $6D -> Index 4 -> Sumpf (Swamp)
;   Tile 16 -> Char $6E -> Index 5 -> Tor (Gate)
;   Tile 17 -> Char $6F -> Index 6 -> Gebirge (Mountains)
;   Tile 18 -> Char $70 -> Index 7 -> Pflaster (Pavement)
;   Tile 19 -> Char $71 -> Index 8 -> Mauer (Wall)
;   Tile 20 -> Char $72 -> Index 9 -> (additional terrain)
;   Tile 21 -> Char $73 -> Index 10 -> (additional terrain)
;
; Units on map are stored as: unit_type + $74 (Char $74-$83)
;
; Color mapping is handled by sub_1C01 in utilities_render.asm
; Terrain index calculation is in sub_1F1C in display_terrain.asm
; Background color: Green ($05) during map display (via raster interrupt)
; Border color: Blue ($06)
; =============================================================================

; -----------------------------------------------------------------------------
; sub_15CD - Copy Custom Character Patterns to Character RAM
; -----------------------------------------------------------------------------
; Copies 38 custom 8x8 character patterns from $15F0 to $E2F0.
; Data is terminated by $AB byte.
; Destination $E2F0 = character codes $5E-$83 (94-131) in the charset.
; -----------------------------------------------------------------------------
sub_15CD:
        LDX #$00

loc_15CF:
        LDA $15F0,X             ; Load pattern byte from source
        CMP #$AB                ; Check for terminator
        BEQ L15E5               ; Exit if terminator found
        STA $E2F0,X             ; Store to character RAM
        INX
        BNE loc_15CF
        INC $15D1               ; Self-modifying: increment source address high byte
        INC $15D8               ; Self-modifying: increment dest address high byte
        JMP loc_15CF

L15E5:
        LDA #$15                ; Reset source address to $15F0
        STA $15D1
        LDA #$E2                ; Reset dest address to $E2F0
        STA $15D8
        RTS

; -----------------------------------------------------------------------------
; Custom Character Pattern Data (38 tiles, 8 bytes each = 304 bytes)
; -----------------------------------------------------------------------------
; Format: 8 bytes per tile, 1 byte per row (top to bottom)
; Bit 7 = leftmost pixel, Bit 0 = rightmost pixel
; Bit value 1 = foreground color, 0 = background color
;
; TILE LAYOUT:
;   Tiles 0-10  ($5E-$68): UI border/frame elements
;   Tile 11 ($69): Wiese (Meadow) - sparse dot pattern
;   Tile 12 ($6A): Fluss (River) - water pattern
;   Tile 13 ($6B): Wald (Forest) - tree pattern
;   Tile 14 ($6C): Ende (Edge) - boundary marker
;   Tile 15 ($6D): Sumpf (Swamp) - marshy pattern
;   Tile 16 ($6E): Tor (Gate) - gate structure
;   Tile 17 ($6F): Gebirge (Mountains) - mountain pattern
;   Tile 18 ($70): Pflaster (Pavement) - road pattern
;   Tile 19 ($71): Mauer (Wall) - wall structure
;   Tiles 20-21 ($72-$73): Additional terrain patterns
;   Tiles 22-28 ($74-$7A): Unit type icons (Yellow)
;   Tiles 29-37 ($7B-$83): Additional unit icons (Black)
; -----------------------------------------------------------------------------
; Tile 0-1 (Char $5E-$5F): Dark Gray - Border/frame characters
        .byte $66, $00, $66, $66, $66, $66, $3C, $00, $DB, $3C, $66, $7E, $66, $66, $66, $00  ; f.ffff<..<f~fff.
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $7F, $FF, $C0, $DF, $DF, $D8, $DB, $DA  ; .............X.Z
        .byte $FE, $FF, $03, $FB, $FB, $1B, $DB, $5B, $DA, $DB, $D8, $DF, $DF, $C0, $FF, $7F  ; .......[Z.X.....
        .byte $5B, $DB, $1B, $FB, $FB, $03, $FF, $FE, $00, $FF, $00, $FF, $FF, $00, $FF, $FF  ; [...............
        .byte $FF, $FF, $00, $FF, $FF, $00, $FF, $00, $5B, $5B, $5B, $5B, $5B, $5B, $5B, $5B  ; ........[[[[[[[[
        .byte $DA, $DA, $DA, $DA, $DA, $DA, $DA, $DA, $02, $40, $08, $01, $04, $20, $81, $10  ; ZZZZZZZZ.@... ..
        .byte $00, $48, $01, $20, $04, $40, $00, $44, $FF, $F8, $77, $8F, $FF, $F8, $77, $8F  ; .h. .@.d..w...w.
        .byte $00, $18, $3C, $2C, $76, $7E, $5A, $18, $00, $5A, $BD, $E7, $E7, $BD, $5A, $3C  ; ..<,v~z..z....z<
        .byte $E0, $00, $3E, $00, $F0, $06, $00, $7C, $00, $7E, $DB, $DB, $DB, $DB, $DB, $FF  ; ..>....|.~......
        .byte $00, $18, $34, $72, $72, $F1, $D9, $8C, $DF, $00, $FB, $FB, $FB, $00, $DF, $DF  ; ..4rr.Y.........
        .byte $00, $7F, $40, $5F, $5F, $58, $5B, $5B, $5B, $5B, $58, $5F, $5F, $40, $7F, $00  ; ..@__x[[[[x__@..
        .byte $E7, $E7, $E7, $E7, $81, $A5, $E7, $FF, $C3, $D1, $D9, $C0, $D9, $D1, $C3, $FF  ; ........CQY.YQC.
        .byte $FF, $F9, $31, $83, $C7, $E7, $FF, $FF, $FF, $F1, $F9, $E5, $CF, $9F, $BF, $FF  ; ..1.G.......O...
        .byte $FF, $DB, $C9, $C9, $C9, $4A, $00, $81, $CF, $C9, $C9, $83, $83, $93, $93, $FF  ; ..IIIj..OII.....
        .byte $FF, $C3, $95, $B1, $8D, $A9, $C3, $FF, $C3, $8B, $9B, $03, $9B, $8B, $C3, $FF  ; .C....C.C.....C.
        .byte $FF, $FB, $F9, $99, $93, $87, $83, $FF, $FF, $E7, $C3, $99, $99, $BD, $FF, $FF  ; ..........C.....
        .byte $97, $83, $93, $B7, $E7, $E7, $E7, $FF, $FF, $C3, $95, $B1, $8D, $A9, $C3, $FF  ; .........C....C.
        .byte $FF, $87, $E3, $93, $F3, $E3, $C3, $C1, $FF, $FF, $9F, $00, $00, $9F, $FF, $FF  ; ......CA........
        .byte $FF, $FF, $F3, $E3, $01, $C9, $E3, $FF, $E7, $E3, $13, $81, $01, $C9, $8C, $FF  ; .....I.......I..
        .byte $AB  ; .

sub_1721:
        LDA #$88
        STA $F7                 ; TEMP_PTR1 (general ptr lo)
        LDA #$17
        STA $F8                 ; TEMP_PTR1 (general ptr hi)
        LDY #$00
        STY $F9                 ; TEMP_PTR2 (general ptr lo)
        LDA #$50
        STA $FA                 ; TEMP_PTR2 (general ptr hi)

L1731:
        LDA ($F7),Y             ; TEMP_PTR1 (general ptr lo)
        JSR sub_1781
        CMP #$04
        BCS L1742
        LDX #$01
        CLC
        ADC #$72
        JMP loc_1759

L1742:
        CMP #$FF
        BEQ L1780
        PHA
        LSR A
        LSR A
        LSR A
        LSR A
        TAX
        PLA
        AND #$0F
        CMP #$08
        BCC L1756
        SEC
        SBC #$11

L1756:
        CLC
        ADC #$6A

loc_1759:
        JSR sub_1766
        STA ($F9),Y             ; TEMP_PTR2 (general ptr lo)
        JSR sub_177A
        DEX
        BNE loc_1759
        BEQ L1731

sub_1766:
        CMP #$69
        BEQ L176E
        CMP #$6A
        BNE L1779

L176E:
        LDA $0801
        INC $176F
        AND #$01
        CLC
        ADC #$69

L1779:
        RTS

sub_177A:
        INC $F9                 ; TEMP_PTR2 (general ptr lo)
        BNE L1780
        INC $FA                 ; TEMP_PTR2 (general ptr hi)

L1780:
        RTS

sub_1781:
        INC $F7                 ; TEMP_PTR1 (general ptr lo)
        BNE L1787
        INC $F8                 ; TEMP_PTR1 (general ptr hi)

L1787:
        RTS
        .byte $13, $26, $17, $1E, $F7, $27, $1E, $46, $A1, $64, $F2, $C2, $96, $13, $26, $27  ; .&...'.f.d.B..&'
        .byte $1E, $F7, $27, $1E, $36, $22, $C1, $54, $F2, $92, $56, $40, $26, $16, $37, $1E  ; ..'.6"At..v@&.7.
        .byte $F7, $27, $1E, $26, $20, $42, $B1, $44, $F2, $82, $46, $60, $16, $47, $1E, $F7  ; .'.& b.d..f`.g..
        .byte $27, $1E, $60, $52, $91, $34, $F2, $32, $30, $12, $46, $80, $47, $1E, $57, $00  ; '.`r.4.20.f.g.w.
        .byte $5C, $15, $5C, $1B, $70, $62, $81, $44, $B2, $10, $12, $70, $46, $80, $47, $15  ; \.\.pb.d...pf.g.
        .byte $57, $1E, $F0, $60, $42, $24, $61, $34, $22, $14, $52, $20, $22, $A0, $26, $90  ; w..`b$a4".r ".&.
        .byte $47, $1E, $57, $1E, $F0, $60, $52, $14, $71, $54, $42, $F0, $15, $A0, $47, $1E  ; g.w..`r.qtb...g.
        .byte $57, $1E, $F0, $20, $18, $3D, $19, $42, $24, $71, $44, $10, $22, $F0, $36, $90  ; w.. .=.b$qd.".6.
        .byte $47, $1E, $57, $1E, $F0, $20, $1F, $37, $1E, $32, $34, $71, $34, $F0, $40, $46  ; g.w.. .7.24q4.@f
        .byte $80, $47, $1E, $57, $1E, $F0, $20, $15, $37, $1E, $22, $20, $24, $81, $24, $E0  ; .g.w.. .7." $.$.
        .byte $16, $30, $46, $90, $47, $1E, $57, $1E, $F0, $20, $1F, $37, $1E, $50, $24, $71  ; .0f.g.w.. .7.p$q
        .byte $24, $E0, $76, $A0, $47, $1E, $57, $1E, $F0, $20, $1A, $3C, $1B, $40, $34, $61  ; $.v.g.w.. .<.@4a
        .byte $44, $30, $24, $90, $16, $10, $46, $A0, $47, $1E, $57, $1E, $F0, $B0, $34, $61  ; d0$...f.g.w...4a
        .byte $94, $B0, $36, $B0, $47, $1E, $57, $01, $6D, $19, $F0, $40, $24, $91, $64, $D0  ; ..6.g.w.m..@$.dP
        .byte $36, $A0, $47, $1E, $C7, $1E, $60, $1D, $19, $A0, $24, $51, $10, $51, $44, $D0  ; 6.g.G.`...$q.qdP
        .byte $46, $A0, $47, $1E, $C7, $1E, $70, $1E, $A0, $24, $41, $30, $41, $34, $F0, $36  ; f.g.G.p..$a0a4.6
        .byte $A0, $47, $01, $2D, $19, $97, $1E, $70, $1E, $A0, $24, $31, $60, $21, $24, $F0  ; .g.-...p..$1`!$.
        .byte $20, $15, $A0, $16, $77, $1E, $57, $00, $3C, $1B, $70, $1E, $C0, $31, $18, $4D  ;  ...w.w.<.p..1.m
        .byte $19, $31, $F0, $30, $26, $80, $26, $77, $1E, $57, $1E, $B0, $1E, $B0, $41, $1F  ; .1.0&.&w.w....a.
        .byte $47, $1E, $31, $F0, $20, $26, $90, $26, $77, $1E, $57, $1E, $A0, $1C, $1B, $C0  ; g.1. &.&w.w.....
        .byte $31, $1F, $47, $1E, $31, $1D, $19, $E0, $36, $A0, $16, $77, $1E, $57, $15, $F7  ; 1.g.1...6..w.w..
        .byte $C7, $15, $47, $15, $47, $15, $E0, $36, $B0, $77, $1E, $57, $1E, $F0, $80, $41  ; G.g.g..6.w.w...a
        .byte $1F, $47, $1E, $31, $1C, $1B, $F0, $26, $B0, $77, $1E, $57, $1E, $F0, $70, $51  ; .g.1...&.w.w..pq
        .byte $1F, $47, $1E, $31, $F0, $10, $46, $A0, $77, $1E, $57, $01, $3D, $19, $60, $18  ; .g.1..f.w.w.=.`.
        .byte $2D, $19, $70, $14, $51, $1A, $4C, $1B, $41, $F0, $36, $B0, $47, $00, $2C, $1B  ; -.p.q.l.a.6.g.,.
        .byte $97, $1E, $60, $15, $27, $1E, $60, $24, $51, $60, $41, $F0, $10, $36, $A0, $47  ; ..`.'.`$q`a..6.g
        .byte $1E, $C7, $1E, $60, $1F, $27, $1E, $60, $34, $51, $50, $31, $F0, $30, $26, $A0  ; .G.`.'.`4qp1.0&.
        .byte $47, $1E, $C7, $1E, $60, $1A, $2C, $1B, $70, $24, $61, $30, $41, $40, $32, $A0  ; g.G.`.,.p$a0a@2.
        .byte $46, $90, $47, $1E, $57, $00, $6C, $1B, $F0, $20, $44, $41, $20, $41, $14, $50  ; f.g.w.l.. da a.p
        .byte $52, $60, $56, $90, $47, $1E, $57, $1E, $F0, $A0, $34, $51, $10, $51, $24, $30  ; r`v.g.w...4q.q$0
        .byte $42, $50, $86, $80, $47, $1E, $57, $1E, $F0, $40, $18, $4D, $19, $34, $D1, $24  ; bp..g.w..@.m.4Q$
        .byte $62, $30, $26, $10, $66, $80, $47, $1E, $57, $1E, $D0, $1D, $19, $40, $1F, $40  ; b0&.f.g.w.P..@.@
        .byte $1E, $34, $F1, $14, $52, $70, $16, $10, $46, $70, $47, $1E, $57, $1E, $E0, $1E  ; .4..rp..fpg.w...
        .byte $90, $54, $F1, $11, $32, $C0, $26, $40, $36, $47, $1E, $57, $1E, $E0, $1E, $A0  ; .t..2.&@6g.w....
        .byte $14, $1D, $19, $24, $71, $34, $51, $42, $B0, $36, $10, $56, $47, $1E, $57, $15  ; ...$q4qb.6.vg.w.
        .byte $E0, $1E, $70, $1D, $19, $30, $1E, $24, $71, $24, $30, $51, $32, $B0, $26, $15  ; ..p..0.$q$0q2.&.
        .byte $16, $10, $36, $47, $15, $57, $1E, $C0, $12, $1C, $1B, $80, $1E, $30, $1E, $24  ; ..6g.w.......0.$
        .byte $61, $34, $30, $12, $41, $42, $A0, $26, $40, $26, $47, $1E, $57, $1E, $B0, $52  ; a40.ab.&@&g.w..r
        .byte $70, $1E, $20, $1C, $1B, $14, $71, $44, $32, $51, $42, $80, $26, $60, $16, $47  ; p. ...qd2qb.&`.g
        .byte $1E, $57, $01, $BD, $19, $52, $60, $1E, $30, $24, $61, $44, $52, $41, $42, $F0  ; .w...r`.0$adrab.
        .byte $20, $16, $37, $1E, $F7, $27, $1E, $72, $40, $1E, $30, $12, $34, $61, $82, $41  ;  .7..'.r@.0.4a.a
        .byte $52, $E0, $16, $26, $27, $1E, $F7, $27, $1E, $A2, $1C, $1B, $12, $10, $32, $24  ; r..&'..'......2$
        .byte $71, $72, $41, $62, $C0, $26, $13, $26, $17, $1E, $F7, $27, $1E, $F2, $42, $71  ; qrab.&.&...'..bq
        .byte $72, $51, $72, $90, $26, $13, $FF  ; rqr.&..
