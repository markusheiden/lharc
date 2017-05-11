
;***************************************
;* LHA5-Dekodierung

include "offset.s"

;*******************
;* Export: Funktionen

export Decode5                        ;-> lharc.c

export getbits                        ;nur für Profiler...
export fillbuf
export align
export decode_block
export read_pt_len
export read_c_len
export make_table


;*******************
;* Import: Funktionen

import init_shipin_dec
import shipin_dec
import shipout_dec
import OpenOut
import do_ProcInd                        ;util.s:

;*******************
;* Import: Variablen

import lson                           ;ushort left [2*NC-1]
import rson                           ;ushort right [2*NC-1]
import dad                            ;dad

import textbuf                        ;für make_table


;*******************
;* Konstanten:

NC              EQU 510
NT              EQU 19
NPT             EQU 19
CBIT            EQU 9

;*******************

TEXTBUF         EQU 16384               ;lhaconst.h

FAULT           EQU 0                   ;lhaconst.h
SUCCS           EQU -1                  ;lhaconst.h

N               EQU 4096                ;lhaconst.h
BLOCKSIZE       EQU N*2


                TEXT

                IF __030__
;*******************
;* MACRO readbits16:
;* IN  A6.l: BSS
;* OUT D0.w: Bits

MACRO readbits16

                movea.l infile-BSS(A6),A0
                movea.l 4(A0),A0        ;ptr

                move.l  offset-BSS(A6),D0
              bfextu  (A0){D0:16},D0

ENDM


;*******************
;* uint getbits (int):
;* IN  D0.b: Anzahl gewünschter Bits <> 0 !
;*     A6.l: BSS
;* OUT D0.w: Bits

getbits:        movea.l infile-BSS(A6),A0
                movea.l 4(A0),A0        ;ptr

                move.l  offset-BSS(A6),D1
              extb.l  D0
              bfextu  (A0){D1:D0},D2
                add.l   D0,D1

                move.l  D1,offset-BSS(A6)
                move.w  D2,D0
                rts


;*******************
;* void fillbuf (int):
;* IN  D0.b: Anzahl zu überspringender Bits
;*     A6.l: BSS

fillbuf:
              extb.l  D0
                add.l   D0,offset-BSS(A6)

                rts


;*******************
;* void align (void):

align:          movea.l infile-BSS(A6),A0

                move.l  offset-BSS(A6),D0
                moveq   #$07,D1
                and.l   D0,D1
                move.l  D1,offset-BSS(A6)

                lsr.l   #3,D0
                sub.l   D0,(A0)+        ;cnt
                add.l   D0,(A0)         ;ptr

                rts


;*******************
;* MACRO fillbuf:
;* IN  reg.l: Register mit Anzahl zu überspringender Bits
;*     D2.l : offset
;*     A2.l : Zeiger auf Puffer

MACRO fillbuf reg

;              extb.l  reg
                add.l   reg,D2

ENDM

;*******************
;* MACRO fillbuf16:
;* IN  D2.l: offset
;*     A2.l: Zeiger auf Puffer

MACRO fillbuf16

                moveq   #16,D0
                add.l   D0,D2

ENDM


;*******************
;* MACRO readbits:
;* IN  offset: Konstante mit Bit-Offset
;*     nreg.b: Register mit Anzahl gewünschter Bits
;*     D2.l  : offset
;*     A2.l  : Zeiger auf Puffer
;* OUT reg   : Bits

MACRO readbits offset,nreg,reg

                IF offset<>0
              moveq   #offset,reg
                add.l   D2,reg
              bfextu  (A2){reg:nreg},reg

                ELSE
              bfextu  (A2){D2:nreg},reg
                ENDC

ENDM


;*******************
;* MACRO readbitsi:
;* IN  offset: Konstante mit Bit-Offset
;*     n     : Konstante mit Anzahl gewünschter Bits
;*     D2.l  : offset
;*     A2.l  : Zeiger auf Puffer
;* OUT reg   : Bits

MACRO readbitsi offset,n,reg

                IF offset<>0
              moveq   #offset,reg
                add.l   D2,reg
              bfextu  (A2){reg:n},reg

                ELSE
              bfextu  (A2){D2:n},reg
                ENDC

ENDM


                ELSE
;*******************
;* MACRO readbits16:
;* IN  A6.l: BSS
;* OUT D0.w: Bits

MACRO readbits16

                move.w  bitbuf-BSS(A6),D0

ENDM


;*******************
;* uint getbits (int):
;* IN  D0.w: Anzahl gewünschter Bits
;*     A6.l: BSS
;* OUT D0.w: Bits

getbits:        move.w  D3,-(SP)

                moveq   #0,D1
                move.w  bitbuf-BSS(A6),D1
                move.w  subbitbuf-BSS(A6),D2

                lsl.l   D0,D1           ;Gewünschte Bits rausshiften (ins Highword)

                neg.w   D0
                add.w   bitcount-BSS(A6),D0 ;Noch genug Bits in subbitbuf?
                bpl.s   gb_end          ;Ja! =>

                neg.w   D0              ;Anzahl noch zu holender Bits berechnen

                movea.l infile-BSS(A6),A0 ;Speicherzeiger laden
                movea.l 4(A0),A1

gb_get_again:   lsl.w   D0,D2           ;aktuellen Wert entsprechend hoch shiften
                or.w    D2,D1           ;und in bitbuf rein

                subq.l  #2,(A0)+        ;Puffer-Länge aktualisieren
;                bmi.s   xxx

                move.w  (A1)+,D2        ;nächstes Word aus Puffer holen
                sub.w   #16,D0          ;noch Bytes zu holen?
;                bhs.s   gb_get_again    ;Ja! =>

                move.l  A1,(A0)         ;Speicherzeiger schreiben

                neg.w   D0              ;Anzahl restlicher Bits berechnen

gb_end:         move.w  D2,D3
                lsr.w   D0,D3           ;und rausschieben
                or.w    D3,D1           ;und nach bitbuf

                movem.w D0-D2,bitcount-BSS(A6)

                swap    D1              ;Ergebnis zurückholen
                move.w  D1,D0

                move.w  (SP)+,D3
                rts


;*******************
;* void fillbuf (int):
;* IN  D0.w: Anzahl zu überspringender Bits
;*     A6.l: BSS

fillbuf:        move.w  D3,-(SP)

                move.w  D0,D3           ;Eingabe sichern

                movem.w bitcount-BSS(A6),D0-D2

                lsl.w   D3,D1           ;alte Bits rausschieben

                sub.w   D3,D0           ;Noch genug Bits in subbitbuf?
                bpl.s   fb_end          ;Ja! =>

                neg.w   D0              ;Anzahl noch zu holender Bits berechnen

                movea.l infile-BSS(A6),A0 ;Speicherzeiger laden
                movea.l 4(A0),A1

fb_get_again:   lsl.w   D0,D2           ;aktuellen Wert entsprechend hoch shiften
                or.w    D2,D1           ;und in bitbuf rein

                subq.l  #2,(A0)+        ;Puffer-Länge aktualisieren
;                bmi.s   xxx

                move.w  (A1)+,D2        ;nächstes Word aus Puffer holen
                sub.w   #16,D0          ;noch Bytes zu holen?
;                bhs.s   fb_get_again    ;Ja! =>

fb_get_end:     move.l  A1,(A0)         ;Speicherzeiger schreiben

                neg.w   D0              ;Anzahl restlicher Bits berechnen

fb_end:         move.w  D2,D3
                lsr.w   D0,D3           ;und rausschieben
                or.w    D3,D1           ;und nach bitbuf

                movem.w D0-D2,bitcount-BSS(A6)

                move.w  (SP)+,D3
                rts


;*******************
;* void align (void):

align:          movea.l infile-BSS(A6),A0
                movea.l 4(A0),A1

                move.l  A1,D0
                btst    #0,D0
                beq.s   align_end

                subq.l  #1,(A0)+
;                bmi.s   xxx

                move.w  subbitbuf-BSS(A6),D0
                lsl.w   #8,D0
                move.b  (A1)+,D0
                move.w  D0,subbitbuf-BSS(A6)

                addq.w  #8,bitcount-BSS(A6) ;!!! assert (bitcount <= 16) nötig?

                move.l  A1,(A0)

align_end:      rts


;*******************
;* MACRO fillbuf:
;* IN  reg.b: Register mit Anzahl zu überspringender Bits
;*     D2.w : bitcount
;*     D5.w : bitbuf
;*     D7.w : subbitbuf
;*     A2.l : Zeiger auf Puffer

MACRO fillbuf reg

LOCAL fb_get_again
LOCAL fb_end

              lsl.w   reg,D5         ;alte Bits rausschieben

                sub.b   reg,D2          ;Noch genug Bits da?
                bpl.s   fb_end          ;Ja! =>

                neg.b   D2              ;Anzahl noch zu holender Bits berechnen

fb_get_again:   lsl.w   D2,D7           ;aktuellen Wert entsprechend hoch shiften
                or.w    D7,D5           ;und in bitbuf rein

                move.w  (A2)+,D7        ;nächstes Word holen !!! auf Long optimieren?
                sub.b   #16,D2          ;noch Bytes zu holen?
;                bhs.s   fb_get_again    ;Ja! =>

                neg.b   D2              ;Anzahl restlicher Bits berechnen

fb_end:         move.w  D7,D0
                lsr.w   D2,D0           ;und rausschieben
                or.w    D0,D5           ;und nach bitbuf

ENDM


;*******************
;* MACRO fillbuf16:
;* IN  D2.w: bitcount
;*     D5.w: bitbuf
;*     D7.w: subbitbuf
;*     A2.l: Zeiger auf Puffer

MACRO fillbuf16

LOCAL fb_get_again
LOCAL fb_end

                moveq   #16,D0

                moveq   #0,D5           ;bitbuf löschen

                sub.w   D0,D2           ;Noch genug Bits da?
                bpl.s   fb_end          ;Ja! =>

                neg.w   D2              ;Anzahl noch zu holender Bits berechnen

fb_get_again:   lsl.w   D2,D7           ;aktuellen Wert entsprechend hoch shiften
                or.w    D7,D5           ;und in bitbuf rein

                move.w  (A2)+,D7        ;nächstes Word holen !!! auf Long optimieren?
                sub.w   D0,D2           ;noch Bytes zu holen?
;                bhs.s   fb_get_again    ;Ja! =>

                neg.w   D2              ;Anzahl restlicher Bits berechnen

fb_end:         move.w  D7,D0
                lsr.w   D2,D0           ;und rausschieben
                or.w    D0,D5           ;und nach bitbuf

ENDM


;*******************
;* MACRO readbits:
;* IN  offset: Konstante mit Bit-Offset
;*     nreg.b: Register mit Anzahl gewünschter Bits
;*     D5.w  : bitbuf
;* OUT reg   : Bits

MACRO readbits offset,nreg,reg

                move.w  D5,reg

                moveq   #16-offset,D0
                sub.b   nreg,D0
              lsr.w   D0,reg

ENDM


;*******************
;* MACRO readbitsi:
;* IN  offset: Konstante mit Bit-Offset
;*     n     : Konstante mit Anzahl gewünschter Bits
;*     D5.w  : bitbuf
;* OUT reg   : Bits

MACRO readbitsi offset,n,reg

                move.w  D5,reg

                IF (offset+n)<>16
                IF (offset+n)>=8
              lsr.w   #16-(offset+n),reg
                ELSE
                moveq   #16-(offset+n),D0
              lsr.w   D0,reg
                ENDC
                ENDC

ENDM

                ENDC


;*******************
;* int Decode5 (ArcFile *, ProcInd_t *):
;* IN  A0.l: ArcFile   *decomp_file
;*     A1.l: ProcInd_t *ProcInd

Decode5:        movem.l D3-D7/A2-A6,-(SP)

                lea     BSS,A6

                movem.l A0-A1,parameter-BSS(A6)

                movea.l decomp_file-BSS(A6),A5
                move.l  AF_arc(A5),infile-BSS(A6)
                move.l  AF_size(A5),D7

                movea.l lson,A0
                move.l  A0,left-BSS(A6)
                movea.l rson,A0
                move.l  A0,right-BSS(A6)

                movea.l A5,A0
                bsr     init_shipin_dec

                lea     outrec-BSS(A6),A0 ;!!! ändern?
                move.l  A0,AF_outrec(A5) ;outrec in decomp_file eintragen
                movea.l textbuf,A1      ;!!! BSS extern
                move.l  #TEXTBUF,D0
                bsr     OpenOut

                lea     outrec-BSS(A6),A3
                movea.l textbuf,A4      ;!!! BSS extern

                moveq   #0,D3           ;Highword löschen
                move.l  #$00003000,D4   ;für shipin_dec
                move.l  #BLOCKSIZE,D5
                moveq   #0,D6           ;printcount?

                move.w  D6,bsize-BSS(A6)
                move.w  D6,dec_j-BSS(A6)
                IF __030__
                move.l  D6,offset-BSS(A6)
                ELSE
                move.w  D6,bitcount-BSS(A6)
                ENDC

                movea.l A5,A0
                move.l  D4,D0
                bsr     shipin_dec

                IFEQ __030__
                bsr     align           ;Filepointer auf Wordgrenze

                moveq   #16,D0          ;bitbuf füllen
                bsr     fillbuf
                ENDC

while_orig:     tst.l   D7              ;textsize == 0?
                beq.s   dec_succs       ;Ja! =>

                move.w  #$2000,D3       ; n (DICSIZ ?)
                cmp.l   D3,D7
                bhs.s   dic_size

                move.w  D7,D3

dic_size:       IF __030__
                bsr     align
                ENDC

                movea.l A5,A0           ;decomp_file
                move.l  D4,D0           ;#$00003000
                bsr     shipin_dec

                IFEQ __030__
                bsr     align           ;Filepointer auf Wordgrenze
                ENDC

                bsr.s   decode_block

                tst.w   D0              ;Fehler?
                beq.s   dec_end         ;Ja! =>

                movea.l A4,A1           ;force write
                adda.l  D3,A1
                move.l  A1,(A3)         ;outrec.ptr
                move.l  D3,4(A3)        ;outrec.cnt

                movea.l A5,A0           ;decomp_file
                bsr     shipout_dec

                add.l   D3,D6
                sub.l   D3,D7

proc_ind:       cmp.l   D5,D6
                blt.s   while_orig

                sub.l   D5,D6

                movea.l ProcInd-BSS(A6),A0
                move.l  D5,D0
                jsr     do_ProcInd

                bra.s   proc_ind

dec_succs:      movea.l ProcInd-BSS(A6),A0
                move.l  D6,D0
                jsr     do_ProcInd

                moveq   #-1,D0          ;SUCCS

dec_end:        movem.l (SP)+,D3-D7/A2-A6
                rts


;*******************
;* void decode_block (uint, char*):
;* IN  D3.w: uint count
;*     A4.l: char *textbuf
;*     A6.l: BSS
;*
;* REGISTER:
;* A2.l: file->_ptr
;* A3.l: dad
;* A4.l: textbuf
;* A5.l: textbuf (Ausgabe)

decode_block:   movem.l D3-D7/A2-A5,-(SP) ;!!! original: D3-7/A2/A4

                subq.w  #1,D3           ; count

                move.w  bsize-BSS(A6),D6

                movea.l infile-BSS(A6),A0
                movea.l 4(A0),A2        ;infile->_ptr

                movea.l dad,A3          ;!!! BSS extern
                movea.l A4,A5           ;textbuf

                IF __030__
                move.l  offset-BSS(A6),D2
                ELSE
                movem.w bitcount-BSS(A6),D2/D5/D7 ;!!! xxx
                ENDC

                move.w  dec_j-BSS(A6),D1
                ble.s   for             ;!!! neu: vorher subq.w #1,D1

                subq.w  #1,D1           ;!!!             bmi.s  for

                move.w  #$1FFF,D0       ; DICSIZ - 1
                move.w  i-BSS(A6),D4

while_loop1:    and.w   D0,D4           ;Rest kopieren
                move.b  0(A4,D4.w),(A5)+ ;!!! optimieren auf D4.l?
                addq.w  #1,D4
                subq.w  #1,D3
                dbmi    D1,while_loop1
                bpl.s   for             ;Alles kopiert? Ja! =>

_dc_return:     bra     dc_return

;Sprünge zu ausgelagerten, weil selten benutzen Routinen
_read_bsize:    bra     read_bsize
_loop1:         bra     loop1
_loop2:         bra     loop2

c_lo_ucmax:     moveq   #0,D1           ;dec_j = 0, falls return

                move.b  D3,(A5)+        ;dekodiertes Zeichen ausgeben

                swap    D3

                subq.w  #1,D3
                bmi.s   _dc_return

for:            subq.w  #1,D6
                bmi.s   _read_bsize

dont_read_bsize:
              readbitsi 0,12,D1

                swap    D3

                add.w   D1,D1
                move.w  0(A3,D1.w),D3   ;!!! optimieren auf D1.l?

                cmp.w   #NC,D3          ;[#510]
                bcc.s   _loop1

no_do1:         IF __030__
                moveq   #0,D0
                ENDC
                move.b  c_len-BSS(A6,D3.w),D0
              fillbuf D0

                cmpi.w  #256,D3         ;UCHAR_MAX
                blo.s   c_lo_ucmax

c_gt_ucmax:     swap    D3

              readbitsi 0,8,D1

                lea     pt_table-BSS(A6),A0 ;!!! optimieren
                add.w   D1,D1
                move.w  0(A0,D1.w),D4

                moveq   #14,D0
                cmp.w   D0,D4
                bcc.s   _loop2

no_do2:         IF __030__
                moveq   #0,D0
                ENDC
                move.b  pt_len-BSS(A6,D4.w),D0 ;!!! optimieren auf D4.l?
              fillbuf D0

                subq.w  #1,D4           ;!!! optimiert
                bmi.s   while_loop2

i_plus:         IF __030__
                moveq   #0,D1
                move.w  D4,D1           ;Keine Bits lesen?
                beq.s   _i_plus         ;Ja! => Ergebnis D4 = 0! !!! Muß für 030 !!!
                ELSE
                move.w  D4,D1
                ENDC

              readbits 0,D1,D4
              fillbuf D1

_i_plus:        moveq   #-1,D0
                bclr    D1,D0

                sub.w   D0,D4
                neg.w   D4

while_loop2:    move.l  A5,D0
                sub.l   A4,D0
                add.w   D0,D4

                move.l  D3,D1           ;!!! neu: war vorher ...swap...
                swap    D1

                move.w  #$1FFF,D0       ; DICSIZ - 1

                subi.w  #254,D1
                sub.w   D1,D3
                bls.s   d1_gt_d3

                and.w   D0,D4
                movea.w D4,A0
                adda.w  D1,A0

                subq.w  #2,D1

                cmp.w   A0,D0
                blt.s   w_loop2c

                lea     0(A4,D4.w),A0   ;!!! optimieren auf D4.l?
                move.b  (A0)+,(A5)+
                move.b  (A0)+,(A5)+

w_loop2a:       move.b  (A0)+,(A5)+     ;!!! OPTIMIEREN
                dbra    D1,w_loop2a
                dbra    D3,for          ;verzweigt immer
;---

w_loop2c:       move.b  0(A4,D4.w),(A5)+ ;!!! optimieren auf D4.l?
                addq.w  #1,D4
                and.w   D0,D4
                move.b  0(A4,D4.w),(A5)+
                addq.w  #1,D4
                and.w   D0,D4
w_loop2d:       move.b  0(A4,D4.w),(A5)+
                addq.w  #1,D4
                and.w   D0,D4
                dbra    D1,w_loop2d
                dbra    D3,for          ;verzweigt immer
;---

d1_gt_d3:       add.w   D1,D3
                sub.w   D3,D1

w_loop2b:       and.w   D0,D4
                move.b  0(A4,D4.w),(A5)+ ;!!! optimieren auf D4.l?
                addq.w  #1,D4
                dbra    D3,w_loop2b

dc_return:      movem.w D1/D4/D6,dec_j-BSS(A6) ;dec_j, i, bsize

                IF __030__
                move.l  D2,offset-BSS(A6)
                ELSE
                movem.w D2/D5/D7,bitcount-BSS(A6)
                ENDC

                movea.l infile-BSS(A6),A0 ;!!! BSS extern
                move.l  A2,D1           ;file->_ptr
                sub.l   4(A0),D1
                sub.l   D1,(A0)+
                move.l  A2,(A0)         ;file->_ptr

                moveq   #SUCCS,D0

                movem.l (SP)+,D3-D7/A2-A5
                rts

;ausgelagert
loop1:          movea.l right-BSS(A6),A0
                movea.l left-BSS(A6),A1

                swap    D7

              readbitsi 12,4,D7

                moveq   #3,D1
                move.w  #510,D0         ;NC

                lsl.b   #4,D7

do1:            add.w   D3,D3
                add.b   D7,D7
                bcc.s   do_else1

                move.w  0(A0,D3.w),D3

                cmp.w   D0,D3
                dblt    D1,do1
                swap    D7
                bra     no_do1

do_else1:       move.w  0(A1,D3.w),D3

                cmp.w   D0,D3
                dblt    D1,do1
                swap    D7
                bra     no_do1

;ausgelagert
loop2:          movea.l right-BSS(A6),A0
                movea.l left-BSS(A6),A1

                swap    D7

              readbitsi 8,8,D7

                moveq   #7,D1
                moveq   #14,D0

do2:            add.w   D4,D4
                add.b   D7,D7
                bcc.s   do_else2

                move.w  0(A0,D4.w),D4

                cmp.w   D0,D4
                dblt    D1,do2
                swap    D7
                bra     no_do2

do_else2:       move.w  0(A1,D4.w),D4

                cmp.w   D0,D4
                dblt    D1,do2
                swap    D7
                bra     no_do2

;ausgelagert
read_bsize:
              readbitsi 0,16,D6
              fillbuf16

                subq.w  #1,D6

                IF __030__
                move.l  D2,offset-BSS(A6)
                ELSE
                movem.w D2/D5/D7,bitcount-BSS(A6) ;!!! xxx
                ENDC

                movea.l infile-BSS(A6),A0 ;!!! BSS extern
                move.l  A2,D0           ;Länge berechnen (file->_ptr)
                sub.l   4(A0),D0
                sub.l   D0,(A0)+        ;und subtrahieren
                move.l  A2,(A0)         ;Zeiger schreiben (file->_ptr)

                moveq   #19,D0          ;nn
                moveq   #5,D1           ;nbit
                moveq   #3,D2           ;i_special
                bsr.s   read_pt_len     ;int read_pt_len (19, 5, 3)
                tst.w   D0
                beq.s   dc_err

                bsr     read_c_len      ;int read_c_len (void)
                tst.w   D0
                beq.s   dc_err

                moveq   #14,D0          ;nn
                moveq   #4,D1           ;nbit
                moveq   #-1,D2          ;i_special
                bsr.s   read_pt_len     ;int read_pt_len (14, 4, -1)
                tst.w   D0
                beq.s   dc_err

                movea.l infile-BSS(A6),A0
                movea.l 4(A0),A2        ; file->_ptr

                IF __030__
                move.l  offset-BSS(A6),D2
                ELSE
                movem.w bitcount-BSS(A6),D2/D5/D7 ;!!! xxx
                ENDC

                bra     dont_read_bsize

dc_err:         moveq   #FAULT,D0

                movem.l (SP)+,D3-D7/A2-A5
                rts


;*******************
;* int read_pt_len (int nn, int nbit, int i_special)
;* IN  D0.w: nn
;*     D1.w: nbit
;*     D2.w: i_special
;*     A6.l: BSS
;* OUT D0.w: result
;*
;* REGISTER:
;* D4.w: nn
;* D5.w: nbit
;* D6.w: i_special
;* D7.w: n
;* A2.l: ptlen

read_pt_len:    movem.l D4-D7/A2,-(SP)

                move.w  D0,D4           ;nn
                move.w  D1,D6           ;nbit
                move.w  D2,D5           ;i_special

                move.w  D6,D0           ;nbit
                bsr     getbits         ;n=getbits(nbit)
                move.w  D0,D7           ;n
                bne.s   rptl_else1

rptl_if1:       lea     pt_len-BSS(A6),A0 ;uchar *ptlen=pt_len

                subq.w  #1,D4           ;n=nn; --n>=0?
                bmi.s   rptl_if1a       ;Nein! =>

                moveq   #0,D0           ;c=0
rptl_for1:      move.b  D0,(A0)+        ;*ptlen++=c
                subq.w  #1,D4           ;--n>=0?
                bpl.s   rptl_for1       ;Ja! =>

rptl_if1a:      move.w  D6,D0           ;nbit
                bsr     getbits         ;c=getbits(nbit)
                move.w  D0,D1           ;c in Low- und Highword
                swap    D1
                move.w  D0,D1
                move.l  D1,D4           ;!!! neu
                move.l  D1,D5
                move.l  D1,D6

                moveq   #256*2/128-1,D0 ;n=256

                lea     pt_table+256*2-BSS(A6),A0 ;ushort *table=pt_table

rptl_for2:      REPT 8                  ;n=256
                movem.l D1/D4-D6,-(A0)  ;*table++=c
              ENDM
                subq.w  #1,D0           ;--n>=0?
                bpl.s   rptl_for2

rptl_succs:     movem.l (SP)+,D4-D7/A2
                moveq   #SUCCS,D0       ;return(SUCCS)
                rts

rptl_else1:     lea     pt_len-BSS(A6),A2 ;uchar *ptlen=pt_len

                moveq   #0,D6           ;int i=0;

rptl_while1:    cmp.w   D7,D6           ;while(i<n)
                bge.s   rptl_else1a

              readbits16              ;bibu=readbits (0,16)

                moveq   #13,D2          ;c=bibu>>13
                move.w  D0,D1
                lsr.w   D2,D1
                cmp.w   #7,D1           ;c==7?
                bne.s   rptl_endif2

                IF __030__
rptl_if2:       not.w   D0              ;Nullen suchen
              bfffo   D0{16+3:13},D0
                sub.w   #16+3,D0
                add.w   D0,D1

                ELSE
rptl_if2:       lsl.w   #4,D0           ;mask=1U<<12; while(mask&bibu)
                bcc.s   rptl_endif2     ;(wend2)

rptl_while2:    addq.w  #1,D1           ;c++
                add.w   D0,D0           ;mask>>=1 !!! neu: war lsl
                bcs.s   rptl_while2
                ENDC

rptl_endif2:    move.b  D1,(A2)+        ;!!! neu: war nach bsr fillbuf

                moveq   #3,D0           ;(c<7) ? 3 : c-3
                subq.w  #7,D1           ;c-7
                bmi.s   rptl_while1a
                addq.w  #4,D1           ;c-3
                move.w  D1,D0
rptl_while1a:   bsr     fillbuf

                addq.w  #1,D6           ;i++
                cmp.w   D5,D6           ;i==i_special?
                bne.s   rptl_while1

rptl_if3:       moveq   #2,D0
                bsr     getbits         ;i+=(c=getbits(2))
                add.w   D0,D6

                subq.w  #1,D0           ;while(--c>=0)
                bmi.s   rptl_while1

                moveq   #0,D1           ;mask=0
rptl_while3:    move.b  D1,(A2)+        ;*ptlen++=mask
                subq.w  #1,D0
                bpl.s   rptl_while3
                bra.s   rptl_while1

rptl_else1a:    move.w  D4,D0           ;für make_table (unten)

                sub.w   D6,D4           ;n=nn; while(i<n)
                ble.s   rptl_else1b

                moveq   #0,D1           ;c=0
rptl_while4:    move.b  D1,(A2)+        ;*ptlen++=c
                subq.w  #1,D4           ;i++
                bne.s   rptl_while4

rptl_else1b:    lea     pt_len-BSS(A6),A0
                moveq   #8,D1
                lea     pt_table-BSS(A6),A1
                bsr     make_table      ;make_table(n, pt_len, 8, pt_table)
;                tst.w   D0
;                bne     rptl_succs

rptl_fault:     movem.l (SP)+,D4-D7/A2
;                moveq   #FAULT,D0       ;return(FAULT)
                rts


;*******************
;* int read_c_len (void):
;* IN  A6.l: BSS
;* OUT D0.w: result
;*
;* REGISTER:
;* D4.w: n
;* D5.w: i
;* D6.w: c
;* A2.l: clen

read_c_len:     movem.l D4-D6/A2,-(SP)

                moveq   #CBIT,D0        ;CBIT
                bsr     getbits         ;n=getbits(CBIT)
                move.w  D0,D4           ;n==0?
                bne.s   rcl_else1

;c_len[] (uchar c_len[NC]) löschen (=0)
rcl_if1:        lea     c_len+((NC+63)/64)*64-BSS(A6),A2 ;uchar *clen=c_len auf 64 Bytes runden

                moveq   #0,D1           ;k=0
                moveq   #0,D4           ;!!! neu
                moveq   #0,D5
                moveq   #0,D6

rcl_for1:       REPT (NC+63)/64
                movem.l D1/D4-D6,-(A2)  ;*((int *) clen)++=(int) k
              ENDM

                moveq   #CBIT,D0        ;CBIT
                bsr     getbits         ;k=getbits(CBIT)
                move.w  D0,D1           ;k=(k<<16)|k
                swap    D1
                move.w  D0,D1
                move.l  D1,D4           ;!!! neu
                move.l  D1,D5
                move.l  D1,D6

                movea.l dad,A0          ;ulong *daddy=(ulong *) dad !!! BSS extern
                adda.l  #2048*4,A0      ;!!! optimieren auf suba.w?
                moveq   #2048*4/128-1,D0 ;i=2048
rcl_for2:       REPT 8
                movem.l D1/D4-D6,-(A0)  ;*daddy++=k
              ENDM
                subq.w  #1,D0           ;--i>0?
                bpl.s   rcl_for2

rcl_succs:      movem.l (SP)+,D4-D6/A2
                moveq   #SUCCS,D0       ;return(SUCCS)
                rts

rcl_else1:      lea     c_len-BSS(A6),A2 ;uchar *clen=c_len

                moveq   #0,D5           ;i=0

rcl_while1:     cmp.w   D4,D5           ;while(i<n)
                bge     rcl_wend1

              readbits16              ;readbits (0,16)

                lea     pt_table-BSS(A6),A0 ;c=pttable[bibu>>8]
                move.w  D0,D1
                lsr.w   #8,D1           ;!!! -1 statt add.w D1,D1 geht nicht!
                add.w   D1,D1
                move.w  0(A0,D1.w),D6

                moveq   #NT,D1

                cmp.w   D1,D6           ;NT !!! Reihenfolge optimieren
                blt.s   rcl_endif2

rcl_if2:        movea.l right-BSS(A6),A0
                movea.l left-BSS(A6),A1

rcl_do1:        add.w   D6,D6           ;!!! 030

                add.b   D0,D0           ;if(bibu&mask) !!! neu: war lsl
                bcc.s   rcl_else3

rcl_if3:        move.w  0(A0,D6.w),D6   ;c=right[c]
                bra.s   rcl_endif3

rcl_else3:      move.w  0(A1,D6.w),D6   ;c=left[c]

rcl_endif3:     cmp.w   D1,D6           ;NT
                bge.s   rcl_do1

rcl_endif2:     lea     pt_len-BSS(A6),A0 ;pt_len[c]
                moveq   #0,D0
                move.b  0(A0,D6.w),D0
                bsr     fillbuf         ;fillbuf(pt_len[c])

                subq.w  #2,D6           ;c>2? !!! hier sub; sub unten zu add
                ble.s   rcl_elseif4

rcl_if4:        move.b  D6,(A2)+        ;*clen++=(c-2)
                addq.w  #1,D5           ;i++
                bra.s   rcl_while1      ;(endif4)

rcl_elseif4:    addq.w  #2,D6           ;c==0?
                beq.s   rcl_else4       ;Ja! =>

                subq.w  #1,D6
                bne.s   rcl_else5

rcl_if5:        moveq   #4,D0           ;4
                bsr     getbits         ;c=getbits(4)
                addq.w  #3,D0           ;c=getbits(4)+3
                bra.s   rcl_endif5

rcl_else5:      moveq   #CBIT,D0        ;CBIT
                bsr     getbits         ;c=getbits(CBIT)
                add.w   #20,D0          ;c=getbits(CBIT)+20

rcl_endif5:     add.w   D0,D5           ;i+=c

                subq.w  #1,D0
                bmi.s   rcl_while1      ;(endif4)

                moveq   #0,D1
rcl_while2:     move.b  D1,(A2)+
                subq.w  #1,D0
                bpl.s   rcl_while2
                bra     rcl_while1      ;(endif4) !!! optimieren?

rcl_else4:      move.b  D6,(A2)+
                addq.w  #1,D5
                bra     rcl_while1      ;(endif4)

rcl_wend1:      move.w  #NC,D0          ;bibu=NC
                move.w  D0,D2

                sub.w   D5,D2           ;while(i<bibu)
                ble.s   rcl_wend3

                moveq   #0,D1           ;mask=0
rcl_while3:     move.b  D1,(A2)+        ;*clen++=mask
                subq.w  #1,D2           ;i++
                bne.s   rcl_while3

rcl_wend3:      lea     c_len-BSS(A6),A0 ;c_len
                moveq   #12,D1          ;12
                movea.l dad,A1          ;dad !!! BSS extern
                bsr.s   make_table      ;make_table(NC, c_len, 12, dad)
;                tst.w   D0
;                bne.s   rcl_succs

rcl_fault:      movem.l (SP)+,D4-D6/A2
;                moveq   #FAULT,D0       ;return(FAULT)
                rts


;*******************
;* int make_table (int nchar, uchar* bitlen, int tablebits, ushort* table):
;* IN  D0.w: nchar
;*     D1.w: tablebits
;*     A0.l: bitlen
;*     A1.l: table
;*     A6.l: BSS
;* OUT D0.w: result
;*
;* REGISTER:
;* D6.w: tablebits
;* A3.l: table
;* A4.l: &start[1]
;* A5.l: count

make_table:     movem.l D3-D7/A2-A5,-(SP)

                move.w  D0,mt_nchar-BSS(A6) ; nchar
                move.w  D1,D6           ; tablebits
                move.l  A0,mt_bitlen-BSS(A6) ; bitlen
                movea.l A1,A3           ; table
                lea     mt_start+1*2-BSS(A6),A4 ; &start[1]
                lea     mt_count-BSS(A6),A5 ; count

                lea     1*2(A5),A1      ;count[1..16] = 0
                moveq   #0,D1
                REPT 8
                move.l  D1,(A1)+
              ENDM

                subq.w  #1,D0           ;nchar == 0?
                bmi.s   no_init         ;Ja! =>

;                moveq   #0,D1
init_count:     move.b  (A0)+,D1        ;bitlen (<= 16)
                add.b   D1,D1           ;!!! 030
                addq.w  #1,0(A5,D1.l)   ;count[bitlen]++
                dbra    D0,init_count   ;--nchar

no_init:        movea.l A4,A0           ; &start[1]
                lea     2(A5),A1        ; &count[1]
                moveq   #0,D5           ; k=0
                move.w  D5,(A0)+        ; start[1]=0
                moveq   #15,D2

init_start:     REPT 4
                move.w  (A1)+,D1        ;count[1..16]
                lsl.w   D2,D1
                add.w   D1,D5
                move.w  D5,(A0)+        ;start[2..17] =
                subq.w  #1,D2
              ENDM
                bpl.s   init_start

                moveq   #FAULT,D0       ;return-Wert

                tst.w   D5              ; k==0
                bne     make_exit

table_ok:       moveq   #16,D2          ;jutbits = 16 - tablebits
                sub.w   D6,D2
                move.w  D2,mt_jutbits-BSS(A6) ;jutbits

                moveq   #1,D3
                lea     mt_weight+1*2-BSS(A6),A0 ; &weight[1]

                move.w  D6,D7
                subq.w  #1,D7
                bmi.s   no_start_weight

                movea.l A4,A1           ; &start[1]
                add.w   D6,D3

                moveq   #1,D1           ;1<<tablebits !!! neu
                lsl.w   D7,D1

start_weight:   move.w  (A1),D0         ;start[i] >>= jutbits
                lsr.w   D2,D0
                move.w  D0,(A1)+

                move.w  D1,(A0)+        ;weight[i++] = 1<<tablebits !!! neu
                lsr.w   #1,D1           ;tablebits--
                bne.s   start_weight

no_start_weight:moveq   #16,D1          ;!!! optimieren
                sub.w   D3,D1
                bmi.s   no_while_weight

                moveq   #0,D0
                bset    D1,D0

while_weight:   move.w  D0,(A0)+
                lsr.l   #1,D0
                dbra    D1,while_weight

no_while_weight:move.w  D6,D0           ;!!! 030
                add.w   D0,D0
                move.w  0(A4,D0.w),D3   ;start[1+tablebits]
                lsr.w   D2,D3
                beq.s   i_equal

                moveq   #1,D5
                lsl.w   D6,D5

                cmp.w   D3,D5
                beq.s   i_equal

                moveq   #0,D0
                movea.l A3,A1           ; table
                adda.w  D3,A1
                adda.w  D3,A1

                sub.w   D5,D3
                not.w   D3

while_i:        move.w  D0,(A1)+        ;start
                dbra    D3,while_i

i_equal:        moveq   #1,D1
                moveq   #15,D2
                sub.w   D6,D2
                lsl.w   D2,D1
                move.w  D1,mt_mask-BSS(A6) ; mask

                move.w  mt_nchar-BSS(A6),D1 ; avail=nchar
                lea     mt_weight-BSS(A6),A0 ; weight
                movea.l mt_bitlen-BSS(A6),A1 ; bitlen
                movea.l right-BSS(A6),A5

                moveq   #0,D0           ; ch
                cmp.w   mt_nchar-BSS(A6),D0 ; ch<nchar?
                bhs     make_end        ;Nein! => fertig

while_ch:       moveq   #0,D4
                move.b  (A1)+,D4        ; len=bitlen[ch]
                beq     next_ch         ;!!! war .s

                move.w  D4,D7
                add.w   D7,D7
                move.w  -2(A4,D7.w),D2  ;start[len]
                move.w  D2,D5           ; k=start[len]
                add.w   0(A0,D7.w),D2   ;weight[len]
                move.w  D2,mt_nextcode-BSS(A6) ; nextcode
                movea.l A3,A2           ; table

                cmp.w   D6,D4           ; len<=tablebits
                bgt.s   len_gt_tablebits

                cmp.w   D2,D5
                bge.s   endif

                adda.w  D5,A2
                adda.w  D5,A2

                sub.w   D5,D2           ;weight[len]-k-1
                subq.w  #1,D2

for_j:          move.w  D0,(A2)+        ;table[] !!! OPTIMIEREN
                dbra    D2,for_j
                bra.s   endif

len_gt_tablebits:
                move.w  mt_jutbits-BSS(A6),D2 ; jutbits
                move.w  D5,D7
                lsr.w   D2,D7           ;k>>=weight[len]
                add.w   D7,D7           ;!!! 030
                adda.w  D7,A2

                move.w  D4,D3
                sub.w   D6,D3
                subq.w  #1,D3
                bmi.s   i_endif

while_i_else:   move.w  (A2),D7         ;table[k]
                add.w   D7,D7           ;!!! 030
                bne.s   table_ne

                moveq   #0,D2
                move.w  D1,D7

                move.w  D1,(A2)         ;!!! war vorher weiter unten
                addq.w  #1,D1

                add.w   D7,D7           ;!!! 030
                movea.l left-BSS(A6),A2 ;!!! optimieren
                move.w  D2,0(A2,D7.w)
                move.w  D2,0(A5,D7.w)

table_ne:       move.w  D5,D2
                and.w   mt_mask-BSS(A6),D2 ;mask
                beq.s   no_mask

                lea     0(A5,D7.w),A2
                bra.s   mask

no_mask:        movea.l left-BSS(A6),A2 ;!!! optimieren
                adda.w  D7,A2           ;!!! neu
mask:           add.w   D5,D5

                dbra    D3,while_i_else
i_endif:        move.w  D0,(A2)

endif:          add.w   D4,D4
                move.w  mt_nextcode-BSS(A6),-2(A4,D4.w) ; start[len]=nextcode

next_ch:        addq.w  #1,D0
                cmp.w   mt_nchar-BSS(A6),D0 ; ch<nchar
                blt     while_ch

make_end:       moveq   #SUCCS,D0

make_exit:      movem.l (SP)+,D3-D7/A2-A5
                rts


;*******************

                BSS

BSS:

align 4
pt_len:         DS.B NPT                ;(  19 Bytes) uchar pt_len[NPT]
align 4
c_len:          DS.B NC                 ;( 510 Bytes) uchar c_len[NC]
align 4                               ;wegen Löschroutine !!!

                IF __030__
align 4
offset:         DS.L 1

                ELSE
align 4
bitcount:       DS.W 1                  ;struct
bitbuf:         DS.W 1                  ; "
subbitbuf:      DS.W 1                  ; "
                ENDC

align 4
dec_j:          DS.W 1                  ;struct
i:              DS.W 1                  ; "
bsize:          DS.W 1                  ; "

mt_nchar:       DS.W 1                  ;nchar
mt_mask:        DS.W 1                  ;mask
mt_nextcode:    DS.W 1                  ;nextcode
mt_jutbits:     DS.W 1                  ;jutbits

align 4
infile:         DS.L 1                  ;FILE  *infile
mt_bitlen:      DS.L 1                  ;&bitlen[].b

left:           DS.L 1                  ;ushort *left
right:          DS.L 1                  ;ushort *right

align 4
parameter:
decomp_file:    DS.L 1                  ;ArcFile *decomp_file
ProcInd:        DS.L 1                  ;ProcInd_t *ProcInd

align 4
outrec:         DS.L 1                  ;  0: Speicherzeiger
                DS.L 1                  ;  4: Länge
                DS.L 1                  ;  8: Basispointer
                DS.L 1                  ; 12: Basislänge
                DS.L 1                  ; 16: buffer_start
                DS.L 1                  ; 20: buffer_last
                DS.L 1                  ; 24: buffer_cnt
                DS.B 1                  ; 28: buffered

align 4
mt_start:       DS.W 18                 ;(  18 Bytes) start[0-17].w
align 4
mt_weight:      DS.W 17                 ;(  17 Bytes) weight[0-16].w
align 4
mt_count:       DS.W 17                 ;(  17 Bytes) count[0-16].w ;!!! neu: original: DS.W 19

align 4
pt_table:       DS.W 256                ;( 512 Bytes) ushort pt_table[256]

align 4

                END
