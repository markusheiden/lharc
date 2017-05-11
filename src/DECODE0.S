
;***************************************
;* Larc-Dekodierung

include "offset.s"

;*******************
;* Export: Funktionen

export DecodeOld                      ;-> lharc.c

export shipinold                      ;nur für Profiler...
export shipoutold


;*******************
;* Import: Funktionen

import init_shipin_dec
import shipin2_dec
import shipout_dec
import OpenOut
import do_ProcInd

;*******************
;* Import: Variablen

import buffer_3
import bsize

import textbuf


;*******************
;* Konstanten

N               EQU 4096        ;lharconst.h
F               EQU 18
THRESHOLD       EQU 2

BLOCKSIZE       EQU N*2


                TEXT

;*******************
;* void DecodeOld (ArcFile *, ProcInd_t *ProcInd):
;* IN  A0.l: ArcFILE   *decomp_file
;*     A1.l: ProcInd_t *ProcInd

DecodeOld:      movem.l D3-D7/A2-A6,-(SP)

                lea     BSS,A6

                movem.l A0-A1,parameter-BSS(A6) ;Parameter sichern

                movea.l decomp_file-BSS(A6),A5
                move.l  AF_size(A5),origsize-BSS(A6)
                move.l  AF_compsize(A5),codesize-BSS(A6)
                move.l  AF_arc(A5),file1-BSS(A6)

                lea     outrec-BSS(A6),A0
                move.l  A0,AF_outrec(A5)
                movea.l buffer_3,A1     ;!!! BSS extern
                move.l  bsize,D0        ;!!! BSS extern
                bsr     OpenOut

                movea.l A5,A0
                bsr     init_shipin_dec

                lea     outrec-BSS(A6),A1
                movea.l (A1)+,A4        ;ptr
                move.l  (A1),D7         ;cnt

                movea.w #N-1,A2

;   register int r=N-F,*tbuf=(int *) textbuf;

                move.w  #N-F,D4
                movea.l textbuf,A3

;       long todo=codesize,done=blocksize;

                move.w  #BLOCKSIZE,D6
                move.l  codesize-BSS(A6),D5

;   uint flags=0;

                moveq   #0,D3

;   for (c=0x2020,k=(N-F)>>1;--k>=0;)

                move.w  #$2020,D0       ;!!! optimieren auf .l?
                move.w  #((N-F)>>1)-1,D1
                movea.l A3,A0

tbuf_init:      move.w  D0,(A0)+        ;*tbuf++=c
                dbra    D1,tbuf_init

;   for (;;)

                movea.l file1-BSS(A6),A0
                move.l  (A0)+,D2        ; file1->_cnt
                movea.l (A0),A5         ; file1->_ptr

;   if (!((flags>>=1) & 256))

for:            lsr.w   #1,D3
                btst    #8,D3
                bne.s   no_flags

                move.w  #$FF00,D3

;   flags=getc(file1)|0xff00;

                subq.l  #1,D2
                bmi     _empty_1        ;!!! optimieren

_get_1:         move.b  (A5)+,D3        ; *_ptr++

;   if (--todo<0) break;

_got_1:         subq.l  #2,D5           ;!!! optimieren
                bpl.s   cont_0
                bra     break

;   if (--todo<0) break;

no_flags:       subq.l  #1,D5
                bmi     break           ;!!! optimieren

;   if (flags & 1)

cont_0:         moveq   #1,D0
                and.w   D3,D0
                beq.s   flag_bit_0_eq

;   c=getc(file1);

                subq.l  #1,D2           ;_cnt
                bmi     _empty_2        ;!!! optimieren

_get_2:         move.b  (A5)+,D0        ; *_ptr++

;   textbuf[r++]=c;

_got_2:         move.b  D0,0(A3,D4.w)
                addq.w  #1,D4

;   r&=m;

                and.w   #N-1,D4

;   putc(c);

                move.b  D0,(A4)+

                subq.l  #1,D7
                bmi     _buf_exit1

;   if (--done>0)

_buf_cont1:     dbra    D6,for

                move.w  #BLOCKSIZE,D6   ;done=blocksize

;   ProcInd();

                move.l  D2,-(SP)

                movea.l ProcInd-BSS(A6),A0
                moveq   #0,D0
                move.w  D6,D0
                jsr     do_ProcInd

                move.l  (SP)+,D2
                bra.s   for

;   else

;   i=getc(file1);

flag_bit_0_eq:  subq.l  #1,D2           ;_cnt
                bmi     _empty_3        ;!!! optimieren

_get_3:         moveq   #0,D1
                move.b  (A5)+,D1        ; *_ptr++

;   if (--todo<0) break;

_got_3:         subq.l  #1,D5
                bmi.s   break

;   i|=(((k=getc(file1)) & 0xf0)<<4);

cont_1:         subq.l  #1,D2           ;_cnt
                bmi     _empty_4        ;!!! optimieren

_get_4:         move.b  (A5)+,D0        ; *_ptr++

_got_4:         exg     A2,D2
                swap    D3
                move.w  D0,D3
                and.w   #$000F,D3
                eor.w   D3,D0
                lsl.w   #4,D0
                or.w    D0,D1

;   k=(k & 0x0f) + THRESHOLD;

                addq.w  #THRESHOLD,D3

;   c=textbuf[i & m];

for_k:          and.w   D2,D1
                move.b  0(A3,D1.w),D0

;   textbuf[r++]=c;

                move.b  D0,0(A3,D4.w)
                addq.w  #1,D4

;   r&=m;

                and.w   D2,D4

;   putc(c);

                move.b  D0,(A4)+

                subq.l  #1,D7
                bmi.s   _buf_exit2

;   if (--done<0)

_buf_cont2:     dbra    D6,not_done

                move.w  #BLOCKSIZE,D6   ;done=blocksize

;   ProcInd();

                move.w  D1,-(SP)

                movea.l ProcInd-BSS(A6),A0
                moveq   #0,D0
                move.w  D6,D0
                jsr     do_ProcInd

                move.w  (SP)+,D1

                move.w  #N-1,D2


;   for (;--k>=0;i++)

not_done:       addq.w  #1,D1
                dbra    D3,for_k
                exg     A2,D2
                swap    D3
                bra     for

break:          move.l  D2,-(SP)

                movea.l ProcInd-BSS(A6),A0
                moveq   #0,D0
                move.w  #BLOCKSIZE,D0   ;Rest = BLOCKSIZE-done
                sub.w   D6,D0
                jsr     do_ProcInd

                move.l  (SP)+,D2


                movea.l file1-BSS(A6),A0
                move.l  D2,(A0)+        ; file1->_cnt
                move.l  A5,(A0)         ; file1->_ptr

;   shipout_decode();

                bsr.s   _shipout

;}

                movem.l (SP)+,D3-D7/A2-A6
                rts


;*******************
;* DecodeOld (ausgelagert):

_buf_exit1:     bsr.s   _shipout
                bra     _buf_cont1

_buf_exit2:     bsr.s   _shipout
                bra.s   _buf_cont2

_empty_1:       bsr.s   _shipin
                move.b  D0,D3
                bra     _got_1

_empty_2:       bsr.s   _shipin
                bra     _got_2

_empty_3:       bsr.s   _shipin
                move.w  D0,D1
                bra     _got_3

_empty_4:       bsr.s   _shipin
                bra     _got_4

_shipout:       lea     outrec-BSS(A6),A1
                move.l  A4,(A1)+
                move.l  D7,(A1)

                bsr.s   shipoutold

                lea     outrec-BSS(A6),A1
                movea.l (A1)+,A4
                move.l  (A1),D7
                rts

_shipin:        movea.l file1-BSS(A6),A0
                move.l  D2,(A0)+
                move.l  A5,(A0)

                bsr.s   shipinold       ;fill_buf (file1)

                movea.l file1-BSS(A6),A0
                move.l  (A0)+,D2
                movea.l (A0),A5
                rts


;*******************
;* void shipoutold (void):
;* IN  A6.l: BSS

shipoutold:     movem.l D0-D2/A0-A1,-(SP)

                movea.l decomp_file-BSS(A6),A0
                bsr     shipout_dec

                movem.l (SP)+,D0-D2/A0-A1
                rts


;*******************
;* int shipinold (void):

shipinold:      movem.l D1-D2/A0-A1,-(SP)

                movea.l decomp_file-BSS(A6),A0
                bsr     shipin2_dec     ;gibt Zeichen in D0.w zurück

                movem.l (SP)+,D1-D2/A0-A1
                rts


;*******************
;* BSS:

                BSS

BSS:

align 4
origsize:       DS.L 1          ;ulong origsize
codesize:       DS.L 1          ;ulong codesize
file1:          DS.L 1          ;FILE *file1

align 4
parameter:
decomp_file:    DS.L 1          ;ArcFile *decomp_file
ProcInd:        DS.L 1          ;ProcInd_t *ProcInd

align 4
outrec:         DS.L 1          ;  0: Speicherzeiger
                DS.L 1          ;  4: Länge
                DS.L 1          ;  8: Basispointer
                DS.L 1          ; 12: Basislänge
                DS.L 1          ; 16: buffer_start
                DS.L 1          ; 20: buffer_last
                DS.L 1          ; 24: buffer_cnt
                DS.B 1          ; 28: buferred

align 4

                END
