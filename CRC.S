
;***************************************
;* CRC-Berechnung (z.Z. nur ein Objekt möglich)

;*******************
;* Export: Funktionen

export init_crc
export create_crc
export block_crc
export get_crc
export destroy_crc


                TEXT

;*******************
;* void init_crc (void): Initialisierung der crc-Berechnung (crc-Tabelle erstellen)

init_crc:       movem.l D3,-(SP)

                lea     crc_mem,A0      ;crc table-Adressen auf 256 Bytes runden
                adda.w  #255,A0
                move.l  A0,D0
                clr.b   D0
                movea.l D0,A0

                move.l  A0,crc_tables   ;Adressen sichern

                lea     256(A0),A0      ;crct_lo+256
                lea     256(A0),A1      ;crct_hi+256

                move.w  #$A001,D2

                move.w  #256-1,D1       ; for (i = 0x100; i--;) {

make1:          move.w  D1,D0           ; crc = i;

                moveq   #7,D3
make2:          lsr.w   #1,D0
                bcc.s   make3
                eor.w   D2,D0           ; ; crc = (crc >> 1) ^ CRC_16
make3:          dbra    D3,make2        ;  for (j=8;--j>=0;)

                move.b  D0,-(A0)        ; crct_lo[i] = (unsigned char) crc
                lsr.w   #8,D0
                move.b  D0,-(A1)        ; crct_hi[i] = crc >> 8
                dbra    D1,make1

                movem.l (SP)+,D3
                rts


;*******************
;* crc_t *create_crc (void): Erzeugen eines crc-Objektes
;* OUT A0.l: crc_t *crc: Zeiger auf crc-Objekt

create_crc:     lea     object,A0
                clr.w   (A0)
                rts


;*******************
;* void block_crc (uchar *, long, crc_t *): CRC eines Blocks berechnen
;* IN  D0.l: long  n   : Länge des Blocks (max. 1MB !!!)
;*     A0.l: uchar *ptr: Adresse des Blocks
;*     A1.l: crc_t *crc: Zeiger auf crc-Objekt

block_crc:      movem.l D3-D5/A2,-(SP)

                moveq   #0,D2
                moveq   #0,D3

                move.b  (A1)+,D3        ; crchi = crc >> 8;
                move.b  (A1),D2         ; crclo = (unsigned char) crc

                move.l  crc_tables,D1
                move.l  D1,D5

                moveq   #16,D4
                cmp.l   D4,D0
                blt     end_crc

                move.l  D0,D4

                lsr.l   #4,D0
                subq.l  #1,D0

;!!! neu: vorher
;for_count:      REPT 16
;                move.b  (A0)+,D1        ; crclo = crct_lo[ndx = *p++ ^ crclo];
;                eor.b   D2,D1
;                movea.l D1,A2
;                move.b  (A2),D2
;                eor.b   D3,D2           ; crclo ^= crchi;
;                move.b  256(A2),D3      ; crchi = crct_hi[ndx];
;                ENDM

                move.b  (A0)+,D1        ; crclo = crct_lo[ndx = *p++ ^ crclo];

for_count:      REPT 8

                eor.b   D2,D1
                move.b  (A0)+,D5        ; crclo = crct_lo[ndx = *p++ ^ crclo];
                movea.l D1,A2
                move.b  (A2),D2
                eor.b   D3,D2           ; crclo ^= crchi;
                move.b  256(A2),D3      ; crchi = crct_hi[ndx];

                eor.b   D2,D5
                move.b  (A0)+,D1        ; crclo = crct_lo[ndx = *p++ ^ crclo];
                movea.l D5,A2
                move.b  (A2),D2
                eor.b   D3,D2           ; crclo ^= crchi;
                move.b  256(A2),D3      ; crchi = crct_hi[ndx];

              ENDM

next_count:     dbra    D0,for_count    ; for (++count; --count;)

;für >1MB
;                sub.l   #$10000,D0
;                bpl.s   for_count

                subq.l  #1,A0

                moveq   #15,D0
                and.w   D4,D0

end_crc:        subq.w  #1,D0
                bmi.s   crc_set

fwhile_crc:     move.b  (A0)+,D1        ; crclo = crct_lo[ndx = *p++ ^ crclo];
                eor.b   D2,D1
                movea.l D1,A2
                move.b  (A2),D2
                eor.b   D3,D2           ; crclo ^= crchi;
                move.b  256(A2),D3      ; crchi = crct_hi[ndx];
                dbra    D0,fwhile_crc

crc_set:        move.b  D2,(A1)         ; crc = ((crchi << 8) | crclo);
                move.b  D3,-(A1)

                movem.l (SP)+,D3-D5/A2
                rts


;*******************
;* int get_crc (crc_t *): Auslesen eines crc-Objektes
;* IN  A0.l: crc_t *crc: Zeiger auf crc-Objekt
;* OUT D0.w: int   crc : crc-Wert

get_crc:        move.l  A0,D0           ;Kein Objekt vorhanden?
                beq.s   get_end         ;Ja! =>

                moveq   #0,D0
                move.w  (A0),D0         ;crc-Ergebnis auslesen

get_end:        rts


;*******************
;* void destroy_crc (crc_t *):
;* IN  A0.l: crc_t *crc: Zeiger auf crc-Objekt

destroy_crc:    rts


;*******************
;* BSS:

                BSS

BSS:

align.w
object:
crc:            DS.W 1

align 4
crc_tables:     DS.L 1

crc_mem:        DS.B 2*256+256

align 4

                END
