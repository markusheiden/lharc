
;***************************************
;* LHarc 1.13 Codierung

include "offset.s"

;*******************
;* Export: Funktionen

export Encode1                        ;-> lharc.c

;export shipin1                        ;Nur für Profiler...
;export shipout1
;export reconst


;*******************
;* Import: Funktionen

import shipin2_enc
import shipout_enc
import do_ProcInd

;*******************
;* Import: Variablen

import lson
import rson
import dad

import textbuf


;*******************
;* Konstanten:

DICBIT          EQU 13
DICSIZ          EQU (1<<DICBIT)
TEXTBUF         EQU 16384

N               EQU 4096        ;lhaconst.h
F               EQU 60
THRESHOLD       EQU 2
N_CHAR          EQU 256-THRESHOLD+F
T               EQU N_CHAR*2-1
FOLD            EQU 18
R               EQU T-1
NIL             EQU N

BLOCKSIZE       EQU N*2


;*******************
;* MACRO putc

MACRO putc reg

LOCAL putc1

                movea.l outrec-BSS(A6),A0

                movea.l (A0),A1         ;Speicherzeiger++=reg
                move.b  reg,(A1)+
                move.l  A1,(A0)+
                subq.l  #1,(A0)         ;Länge--
                bpl.s   putc1

                bsr     shipout1

putc1:

ENDM


;*******************
;* MACRO getc:
;* OUT D0.b: gelesenes BYTE
;*     CCR : EOF: Zeroflag gesetzt

MACRO   getc

LOCAL   getc1
LOCAL   getc2

                movea.l file3-BSS(A6),A0
                subq.l  #1,(A0)+
                bpl.s   getc1

                bsr     shipin1         ;Puffer füllen
                bra.s   getc2           ;EOF? Ja! =>

getc1:          moveq   #0,D0           ;Zeichen holen
                movea.l (A0),A1
                move.b  (A1)+,D0
                move.l  A1,(A0)         ;Zeroflag ist gelöscht, da A1<>0

getc2:

ENDM


;*******************
;* MACRO putcode:
;* IN  D0.w:
;*     D1.w:
;*     D6.w:
;*     D7.b:
;*     A6.l: BSS

MACRO   putcode

LOCAL   putcode1
LOCAL   putcode2

                movem.l D3-D4,-(SP)

                move.w  D0,D4
                move.w  D1,D3
                move.b  D7,D2
                lsr.w   D2,D1
                or.w    D1,D6

                add.b   D0,D7
                cmpi.b  #8,D7
                bcs.s   putcode2

                move.w  D6,D0
                lsr.w   #8,D0
              putc    d0

                subq.b  #8,D7
                cmpi.b  #8,D7
                bcs.s   putcode1

              putc    d6

                subq.b  #8,D7

                move.w  D3,D0
                move.b  D4,D1
                sub.b   D7,D1
                lsl.w   D1,D0
                move.w  D0,D6
                bra.s   putcode2

putcode1:       move.w  D6,D0
                lsl.w   #8,D0
                move.w  D0,D6

putcode2:       movem.l (SP)+,D3-D4

ENDM


;*******************
;* void update(int c): (auch in DECODE1.S)
;* IN  D0.w:
;*     D2.w: 2*T
;*     A2.l: hfreq
;*     A4.l: son
;*     A6.l: BSS

; register int i,j,k,l;
; register D3 = c
; register D1 = k
; register D2 = l
; register A1 = son

; register D5 = cardinal c
; a4 = hfreq[c]

;uses: d0,d1,d2,d5
;      a0,a1,a2,a3,a4

MACRO   update

LOCAL   upd_1
LOCAL   upd_2
LOCAL   upd_2a
LOCAL   upd_2b
LOCAL   upd_3
LOCAL   upd_4
LOCAL   upd_5
LOCAL   upd_6
LOCAL   upd_end
LOCAL   upd_reconst

                tst.w   R*2(A2)         ; if hfreq[R] == MAX_FREQ
                bmi.s   upd_reconst

upd_1:          lea     prnt-BSS(A6),A0 ; A0 = prnt

                move.w  0(A0,D0.w),D0

; do {

                lea     0(A2,D0.w),A1   ; A1 = hfreq[c]
                addq.w  #1,(A1)         ; hfreq[c]++

; Ab hier: l=d5
; if the order is disturbed, exchange nodes

                cmpm.w  (A1)+,(A1)+     ; if k>hfreq[l=c+1])
                bcs.s   upd_2b

upd_2a:         move.w  0(A0,D0.w),D0
                beq.s   upd_end

; do {

upd_2:          lea     0(A2,D0.w),A1   ; A1 = hfreq[c]
                addq.w  #1,(A1)         ; hfreq[c]++

; Ab hier: l=d5
; if the order is disturbed, exchange nodes

                cmpm.w  (A1)+,(A1)+     ; if k>hfreq[l=c+1])
                bcc.s   upd_2a

; while k > hfreq[++l]

upd_2b:         subq.w  #1,-4(A1)
                move.w  -4(A1),D1
upd_3:          cmp.w   (A1)+,D1
                beq.s   upd_3           ; while (k>hfreq[++l]);
                subq.l  #4,A1
                addq.w  #1,(A1)

                suba.l  A2,A1

                move.w  0(A4,D0.w),D4   ; i=son[c]
                move.w  A1,0(A0,D4.w)   ;prnt[i]=l

                cmp.w   D2,D4           ; if i<T
                bge.s   upd_4
                move.w  A1,2(A0,D4.w)   ; prnt[i+1]=l

upd_4:          move.w  0(A4,A1.w),D1   ; j=son[l]
                move.w  D4,0(A4,A1.w)   ; son[l]=j

                move.w  D0,0(A0,D1.w)   ; prnt[j] = c

                cmp.w   D2,D1           ; if j<T
                bge.s   upd_5
                move.w  D0,2(A0,D1.w)   ; prnt[j+1]=c

upd_5:          move.w  D1,0(A4,D0.w)   ; son[c]=j
                move.w  A1,D0
upd_6:          move.w  0(A0,D0.w),D0
                beq.s   upd_end

; do {

                lea     0(A2,D0.w),A1   ; A1 = hfreq[c]
                addq.w  #1,(A1)         ; hfreq[c]++
;               move.w  (A1)+,D1        ; k=hfreq[c]

; Ab hier: l=d5
; if the order is disturbed, exchange nodes

                cmpm.w  (A1)+,(A1)+     ; if k>hfreq[l=c+1])
                bcc.s   upd_6
                bra.s   upd_2b

; while k > hfreq[++l]

upd_reconst:    bsr     reconst
                bra.s   upd_1

upd_end:

ENDM


;*******************
;* void EncodeChar(unsigned c):
;* IN  D0.w:
;*     A6.l: BSS

; register unsigned i;
; register int j,k;
; D5 = c
; D3 = i
; d4 = j
; d0 = k

MACRO   EncodeCh

LOCAL   Enchar1
LOCAL   Enchar2
LOCAL   Enchar5

                move.w  D5,-(SP)

                move.w  #2*R,D2
                move.w  D0,D5           ; c
                moveq   #0,D1           ;i=0
                movea.l D1,A1           ;j=0
                moveq   #0,D4           ;shift=0
                lea     prnt-BSS(A6),A0
                add.w   #T,D0           ; T
                add.w   D0,D0
                move.w  0(A0,D0.w),D0   ; k=prnt[c+T]

; while
; if (k & 1) i +=0x8000

Enchar1:        addq.w  #1,D4
                btst    #1,D0
                beq.s   Enchar2
                lsr.w   D4,D1
                adda.w  D4,A1
                moveq   #0,D4
                add.w   #$8000,D1
Enchar2:        move.w  0(A0,D0.w),D0   ; k=prnt[k]
                cmp.w   D2,D0           ; R
                bne.s   Enchar1

; putcode(j,i)

Enchar5:        adda.w  D4,A1
                move.w  A1,D0
                lsr.w   D4,D1
                lea     hfreq-BSS(A6),A2
              putcode

; update(c)

                move.w  D5,D0
                add.w   D0,D0
                lea     hfreq-BSS(A6),A2
                lea     son-BSS(A6),A4
                move.w  #2*T,D2
                add.w   D2,D0
              update

                move.w  (SP)+,D5

ENDM


;*******************
;* void EncodePosition(unsigned c):

; register unsigned i;

MACRO   EncodePo

                move.w  D0,D4

                lsr.w   #6,D0
                move.w  D0,D2           ; i = c >> 6

                lea     p_code,A0
                moveq   #0,D1
                move.b  0(A0,D2.w),D1
                lsl.w   #8,D1           ; p_code[i] << 8

                moveq   #0,D0
                move.b  p_len-p_code(A0,D2.w),D0 ; p_len[i]
              putcode                 ; putcode(p_len[i],p_code[i] <<8)

                moveq   #$3F,D1
                and.w   D4,D1
                moveq   #$0A,D0
                lsl.w   D0,D1
                moveq   #6,D0
              putcode

ENDM


;*******************
;* void DeleteNode(int p):
;* IN  A2.l: lson
;*     A3.l: rson
;*     A4.l: dad
;*     A5.l: textbuf
;*     A6.l: BSS

; register int q;

; register D5 = p   ; D4 = cardinal p
; register D1 = q   ; D2 = cardinal q
; register D3 = temp

; register A0 = dad
; register A2 = rson
; register A3 = lson
; register A4 = *rson[p]
; register A5 = *lson[p]

MACRO   DeleteNo

LOCAL   DNode_2
LOCAL   DNode_3
LOCAL   DNode_4
LOCAL   DNode_5
LOCAL   DNode_6
LOCAL   DNode_7
LOCAL   DNode_8
LOCAL   DNode_9
LOCAL   DNodex1
LOCAL   DNodex2

                move.w  #2*NIL,D7
                cmp.w   0(A4,D5.w),D7   ; if dad[p] == NIL
                beq.s   DNode_9         ;    return
                cmp.w   0(A3,D5.w),D7   ; if rson[p] == NIL
                beq.s   DNodex1
                move.w  0(A2,D5.w),D2
                cmp.w   D2,D7           ; if lson[p] == NIL
                beq.s   DNodex2

DNode_2:        move.w  0(A3,D2.w),D1
                cmp.w   D1,D7
                beq.s   DNode_5

; do { q=rson[q] } while (rson[q] != NIL}

DNode_3:        move.w  D2,D1
                move.w  0(A3,D2.w),D2
                cmp.w   D7,D2
                bne.s   DNode_3
                move.w  D1,D2

; d2 = q    |  d5 = p    |  d1/d0 = temp |
; a2 = lson |  a3 = rson |  a4    = dad  |

DNode_4:        move.w  0(A2,D2.w),D0   ; lson[q]
                move.w  0(A4,D2.w),D1   ; dad[q]
                move.w  D0,0(A3,D1.w)   ; rson[dad[q]]=lson[q]
                move.w  D1,0(A4,D0.w)   ; dad[lson[q]]=dad[q]
                move.w  0(A2,D5.w),D1   ; lson[p]
                move.w  D1,0(A2,D2.w)   ; lson[q]=lson[p]
                move.w  D2,0(A4,D1.w)   ; dad[lson[p]]=q

DNode_5:        move.w  0(A3,D5.w),D0
                move.w  D0,0(A3,D2.w)   ; rson[q] = rson[p]
                move.w  D2,0(A4,D0.w)   ; dad[rson[p]] = q

DNode_6:        move.w  0(A4,D5.w),D0   ; dad[p]
                move.w  D0,0(A4,D2.w)   ; dad[q]=dad[p]

                cmp.w   0(A3,D0.w),D5
                bne.s   DNode_7         ; if rson[dad[p]]=p

; else ..

                move.w  D2,0(A3,D0.w)   ; rson[dad[p]]=q
                bra.s   DNode_8

DNodex1:        move.w  0(A2,D5.w),D2   ; q=lson[p]
                bra.s   DNode_6

DNodex2:        move.w  0(A3,D5.w),D2   ; q=rson[p]
                bra.s   DNode_6

DNode_7:        move.w  D2,0(A2,D0.w)   ; lson[dad[p]]=q

DNode_8:        move.w  D7,0(A4,D5.w)

DNode_9:

ENDM


;*******************
;* void InsertNode(int r):
;* IN  D6.w: r*2
;*     A2.l: lson
;*     A3.l: rson
;*     A4.l: dad
;*     A5.l: textbuf
;*     A6.l: BSS

; rester int i,p,cmp;
; unsigned char *key;
; unigned c;

; register D1 = cmp
; register D2 = p
; register A1 = *key
; register A2 = rson
; register A3 = lson

MACRO   InsertNo

LOCAL   INode_1a
LOCAL   INode_2
LOCAL   INode_3
LOCAL   INode_3a
LOCAL   INode_4
LOCAL   INode_6
LOCAL   INode_7
LOCAL   INode_8
LOCAL   INode_10
LOCAL   INode_end
LOCAL   Encode_L1

                movem.l D3-D4/A6,-(SP)  ;!!! ändern

                lea     0(A5,D6.w),A6   ; key=&textbuf[r]

                move.w  (A6)+,D2        ; key[0]
                add.w   #N+1,D2         ; p= N+1+key[0]
                add.w   D2,D2           ; cardinal

                move.w  #2*NIL,D3
                move.w  D3,0(A2,D6.w)   ; rson[r] = NIL
                move.w  D3,0(A3,D6.w)   ; lson[r] = NIL

; for ...

INode_1a:       move.w  D2,D0           ;                   !!! ÄNDERN+
                move.w  0(A3,D2.w),D2   ; rson[p]
                cmp.w   D3,D2           ; if rson[p] != NIL
                bne.s   INode_6         ; p=rson[p] else

                move.w  D0,D2           ;                   !!! ÄNDERN+
                move.w  D6,0(A3,D2.w)   ; rson[p] = r
                move.w  D2,0(A4,D6.w)   ; dad[r] = p
                bra     INode_end

INode_4:        move.w  D0,D2           ;                   !!! ÄNDERN+
                move.w  D6,0(A2,D2.w)   ; lson[p] = r
                move.w  D2,0(A4,D6.w)   ; dad[r] = p
                bra     INode_end

INode_3a:       bge.s   INode_1a
INode_3:        move.w  D2,D0           ;                   !!! ÄNDERN+
                move.w  0(A2,D2.w),D2   ; d2=lson[p]
                cmp.w   D3,D2           ; if lson[p] != NIL
                beq.s   INode_4

; for (i=1; i<F; i++)

INode_6:        movea.l A6,A0           ; key[1] (Siehe oben (a6)+)
                lea     2(A5,D2.w),A1   ; textbuf[p+1]     !!! ÄNDERN-
                cmpm.w  (A0)+,(A1)+     ; this saves MUCH time !!! ÄNDERN-
                bne.s   INode_3a        ; and also (why?) some bytes
                cmpm.l  (A0)+,(A1)+     ;                   !!! ÄNDERN-
                bne.s   INode_3a

                REPT 20
                cmpm.l  (A0)+,(A1)+     ;                   !!! ÄNDERN-
                bne.s   INode_8
              ENDM

                moveq   #7,D0           ;!!! optimieren (REPT 28 oben?)
INode_7:        cmpm.l  (A0)+,(A1)+     ;                   !!! ÄNDERN-
                dbne    D0,INode_7

INode_8:        bhi.s   INode_3         ;!!! neu: bhi und beq vertauscht
                beq.s   INode_10

                move.w  D2,D0           ;                   !!! ÄNDERN+
                move.w  0(A3,D2.w),D2   ; rson[p]
                cmp.w   D3,D2           ; if rson[p] != NIL
                bne.s   INode_6         ; p=rson[p] else

                move.w  D0,D2           ;                   !!! ÄNDERN+
                move.w  D6,0(A3,D2.w)   ; rson[p] = r
                move.w  D2,0(A4,D6.w)   ; dad[r] = p
                bra.s   INode_end

Encode_L1:      move.w  D6,0(A3,D0.w)
                move.w  D3,0(A4,D2.w)   ; dad[p] = NIL
                bra.s   INode_end

;  break
; d2 = p     a2 = lson   a4 = dad
; d1 = r     a3 = rson

INode_10:       move.w  0(A2,D2.w),D0   ; d0 = lson[p]
                move.w  D6,0(A4,D0.w)   ;   dad[lson[p]]=r
                move.w  D0,0(A2,D6.w)   ;   lson[r]=lson[p]
                move.w  0(A3,D2.w),D0   ; d0=rson[p]
                move.w  D6,0(A4,D0.w)   ;   dad[rson[p]]=r
                move.w  D0,0(A3,D6.w)   ;   rson[r]=rson[p]
                move.w  0(A4,D2.w),D0   ; dad[r]=dad[p]
                move.w  D0,0(A4,D6.w)
                cmp.w   0(A3,D0.w),D2
                beq.s   Encode_L1

                move.w  D6,0(A2,D0.w)   ; lson[dad[p]] = r
                move.w  D3,0(A4,D2.w)   ; dad[p] = NIL

INode_end:      movem.l (SP)+,D3-D4/A6  ;!!! ändern

ENDM


;*******************
;* MatchInsertNo:
;* IN  D6.w: r*2
;*     A2.l: rson
;*     A3.l: lson
;*     A4.l: dad
;*     A5.l: textbuf

MACRO   MatchInsertNo

LOCAL   INode_1
LOCAL   INode_1a
LOCAL   INode_2
LOCAL   INode_3
LOCAL   INode_3a
LOCAL   INode_4
LOCAL   INode_6
LOCAL   INode_7
LOCAL   INode_9
LOCAL   INode_9a
LOCAL   INode_10
LOCAL   INode_end
LOCAL   Encode_L1

                movem.l D3-D5/A6,-(SP)  ;!!! ändern

                moveq   #1,D1           ; cmp=1

                lea     0(A5,D6.w),A6   ; key=&textbuf[r]

                move.w  (A6)+,D2        ; key[0]
                add.w   #N+1,D2         ; p= N+1+key[0]
                add.w   D2,D2           ; cardinal

                move.w  #2*NIL,D3
                move.w  D3,0(A2,D6.w)   ; rson[r] = NIL
                move.w  D3,0(A3,D6.w)   ; lson[r] = NIL

; match_position=d7
; match_length=d0

                moveq   #0,D0           ; match_length=0

; for ...

INode_1:        tst.b   D1              ; if (cmp > 0) {
                blt.s   INode_3

INode_1a:       move.w  D2,D5           ;                   !!! ÄNDERN+
                move.w  0(A3,D2.w),D2   ; rson[p]
                cmp.w   D3,D2           ; if rson[p] != NIL
                bne.s   INode_6         ; p=rson[p] else

INode_2:        move.w  D5,D2           ;                   !!! ÄNDERN+
                move.w  D6,0(A3,D2.w)   ; rson[p] = r
                move.w  D2,0(A4,D6.w)   ; dad[r] = p
                bra     INode_end

INode_4:        move.w  D5,D2           ;                   !!! ÄNDERN+
                move.w  D6,0(A2,D2.w)   ; lson[p] = r
                move.w  D2,0(A4,D6.w)   ; dad[r] = p
                bra     INode_end

INode_3a:       bge.s   INode_1a
INode_3:        move.w  D2,D5           ;                   !!! ÄNDERN+
                move.w  0(A2,D2.w),D2   ; d7=lson[p]
                cmp.w   D3,D2           ; if lson[p] != NIL
                beq.s   INode_4

; for (i=1; i<F; i++)

INode_6:        movea.l A6,A0           ; key[1] (Siehe oben (a6)+)
                lea     2(A5,D2.w),A1   ; textbuf[p+1]     !!! ÄNDERN-
                cmpm.l  (A0)+,(A1)+     ; this saves MUCH time !!! ÄNDERN-
                bne.s   INode_3a        ; and also (why?) some bytes
                cmpm.w  (A0)+,(A1)+     ;                   !!! ÄNDERN-
                bne.s   INode_3a

                moveq   #F-5,D5
INode_7:        cmpm.w  (A0)+,(A1)+     ;                   !!! ÄNDERN-
                dbne    D5,INode_7

                beq.s   INode_9a
                shi     D1              ; cmp=key[i]-textbuf[p+1]
                not.w   D5
                add.w   #F,D5

                cmp.w   D0,D5           ; if i>match_length
                ble.s   INode_1

                move.w  D6,D7
                sub.w   D2,D7           ; r-p
                and.w   #2*(N-1),D7     ; (r-p) & (N-1) [2*$0FFF]
                subq.w  #2,D7           ; ((r-p) & (N-1)) -1 = match_pos

                move.w  D5,D0           ; match_length=i
                tst.b   D1              ; if (cmp > 0) {
                blt.s   INode_3

                move.w  D2,D5           ;                   !!! ÄNDERN+
                move.w  0(A3,D2.w),D2   ; rson[p]
                cmp.w   D3,D2           ; if rson[p] != NIL
                bne.s   INode_6         ; p=rson[p] else

                move.w  D5,D2           ;                   !!! ÄNDERN+
                move.w  D6,0(A3,D2.w)   ; rson[p] = r
                move.w  D2,0(A4,D6.w)   ; dad[r] = p
                bra.s   INode_end

INode_9a:       not.w   D5
                add.w   #F,D5
                move.w  D6,D7
                sub.w   D2,D7           ; r-p
                and.w   #2*(N-1),D7     ; (r-p) & (N-1) [2*$0FFF]
                subq.w  #2,D7           ; ((r-p) & (N-1)) -1 = match_pos

                move.w  D5,D0           ; match_length=i

;  break

INode_10:       move.w  0(A2,D2.w),D4   ; d4 = lson[p]
                move.w  D6,0(A4,D4.w)   ;   dad[lson[p]]=r
                move.w  D4,0(A2,D6.w)   ;   lson[r]=lson[p]
                move.w  0(A3,D2.w),D4   ; d4=rson[p]
                move.w  D6,0(A4,D4.w)   ;   dad[rson[p]]=r
                move.w  D4,0(A3,D6.w)   ;   rson[r]=rson[p]
                move.w  0(A4,D2.w),D4
                move.w  D4,0(A4,D6.w)   ; dad[r]=dad[p]

                cmp.w   0(A3,D4.w),D2
                beq.s   Encode_L1

                move.w  D6,0(A2,D4.w)   ; lson[dad[p]] = r
                move.w  D3,0(A4,D2.w)   ; dad[p] = NIL
                bra.s   INode_end

Encode_L1:      move.w  D6,0(A3,D4.w)
                move.w  D3,0(A4,D2.w)   ; dad[p] = NIL

INode_end:      movem.l (SP)+,D3-D5/A6  ;!!! ändern

                move.w  D0,match_length-BSS(A6)
                move.w  D7,match_position-BSS(A6)


ENDM


;*******************
;* void Encode1 (ArcFile *, ProcInd_t *, uchar):
;* IN  D0.b   : uchar     compress
;*     A0.l   : ArcFile   *comp_file
;*     A1.l   : ProcInd_t *ProcInd
;*
; register int i,r,s,c;
; register int len,last_match_length
; long printcount,printsize;

; register D4 = c
; register D5 = s
; register D6 = r
; register A2 = *textsize

Encode1:        movem.l D3-D7/A2-A6,-(SP)

                lea     BSS,A6

;Übergabeparameter sichern
                movem.l D0/A0-A1,parameter-BSS(A6)

;memset (hfreq, 0, (long) (&textbuf[16384] - (uchar *) hfreq))
                lea     hfreq-BSS(A6),A0
                move.w  #(T+1-1)>>1,D0
                moveq   #0,D1
enc1:           move.l  D1,(A0)+
                subq.w  #1,D0
                bpl.s   enc1

                lea     prnt-BSS(A6),A0
                move.w  #(T+N_CHAR-1)>>1,D0
                moveq   #0,D1
enc2:           move.l  D1,(A0)+
                subq.w  #1,D0
                bpl.s   enc2

                lea     son-BSS(A6),A0
                move.w  #(T-1)>>1,D0
                moveq   #0,D1
enc3:           move.l  D1,(A0)+
                subq.w  #1,D0
                bpl.s   enc3

                movea.l textbuf,A0      ;!!! optimieren
                move.w  #(TEXTBUF-1)>>2,D0 ;[(16384-1)>>2]
                moveq   #0,D1
enc4:           move.l  D1,(A0)+
                subq.w  #1,D0
                bpl.s   enc4

                movea.l comp_file-BSS(A6),A0
                move.l  AF_file(A0),file3-BSS(A6)
                move.l  AF_outrec(A0),outrec-BSS(A6)
                move.l  AF_size(A0),textsize-BSS(A6) ;!!! neu

                moveq   #0,D0
                move.b  D0,putlen-BSS(A6) ; putlen=0
                move.w  D0,putbuf-BSS(A6) ; putbuf=0
                move.w  D0,match_position-BSS(A6)
                move.w  D0,match_length-BSS(A6)

                movea.l lson,A2         ;!!! BSS extern
                movea.l rson,A3         ;!!! BSS extern
                movea.l dad,A4          ;!!! BSS extern
                movea.l textbuf,A5      ;!!! BSS extern

                move.l  textsize-BSS(A6),D0
                beq     enc_23          ; if (textsize==0) return

                move.l  D0,printsize-BSS(A6)

                move.l  #BLOCKSIZE,printcount-BSS(A6)

;                clr.l   textsize-BSS(A6) ; textsize=0


;void StartHuf (void)
;{
StartHuf:       movem.l D3-D4/A2-A3,-(SP)

                lea     hfreq-BSS(A6),A0
                movea.l A0,A1           ; freqp=hfreq
                lea     son-BSS(A6),A2  ; sonp=son
                lea     prnt+T*2-BSS(A6),A3 ; prnpt=&prntp[T]

; for(i=0; i<N_CHAR; i++) {

                move.w  #2*T,D1         ; iT=T
                moveq   #0,D4
                moveq   #0,D0           ; i=0
                bra.s   SHuff2
SHuff1:         move.w  #1,(A1)+        ; *hfreq++=1
                move.w  D1,(A2)+        ; *sonp++=iT++
                addq.w  #2,D1
                move.w  D4,(A3)+        ; *prntp++=i;
                addq.w  #1,D0
                addq.w  #2,D4
SHuff2:         cmp.w   #$013A,D0
                blt.s   SHuff1

; }

                moveq   #0,D0           ; i=0
                move.w  #N_CHAR*2,D4
                move.w  #N_CHAR,D1      ; j=N_CHAR
                movea.l A0,A1           ;freqp=hfreq
                lea     son+N_CHAR*2-BSS(A6),A2 ; sonp=&son[N_CHAR]
                lea     prnt-BSS(A6),A3 ; prntp=prnt

; while (j<=R) {

                bra.s   SHuff4
SHuff3:         move.w  (A1)+,D2
                add.w   (A1)+,D2
                move.w  D1,D3
                add.w   D3,D3
                move.w  D2,0(A0,D3.w)   ; hfreq[j] = *freqp++ + *freqp++
                move.w  D0,(A2)+        ; *sonp++=i
                move.w  D4,(A3)+        ; *prntp++=j
                move.w  D4,(A3)+        ; *prntp++=j
                addq.w  #4,D0           ; i+=2
                addq.w  #1,D1           ; j+=1
                addq.w  #2,D4
SHuff4:         cmp.w   #R,D1
                ble.s   SHuff3

; }

                move.w  #$FFFF,hfreq+T*2-BSS(A6) ;hfreq[T]=0xffff !!! war $04E6(A0)
                clr.w   prnt+R*2-BSS(A6) ; prnt[R]=0

                movem.l (SP)+,D3-D4/A2-A3
;}


;void InitTree (void)
;{
InitTree:       movea.l A4,A0           ;p=dad
                move.w  #N-1,D0         ;for (i=N;--i>0;)
                move.w  #NIL<<1,D1      ;nil_2=NILL<<1
it1:            move.w  D1,(A0)+        ;*p++=nil_2
                subq.w  #1,D0           ;--i>=0?
                bpl.s   it1             ;Ja! =>

                lea     (N+1)*2(A3),A0  ;p=&rson[N+1]
                move.w  #256-1,D0       ;for (i=256;--i>=0;)
it2:            move.w  D1,(A0)+        ;*p++=nil_2
                subq.w  #1,D0           ;--i>=0?
                bpl.s   it2             ;Ja! =>
;}


                moveq   #0,D5           ; s=0
                move.w  #N-F,D6         ; r=N-F

; for(i=s; i<r;i++)

                move.w  D5,D7

                movem.l D0/A5,-(SP)

                add.w   D7,D7
                lea     0(A5,D7.w),A5
                lsr.w   #1,D7
                move.w  D6,D0
                sub.w   D7,D0
                sub.w   #1,D0
                moveq   #' ',D1         ;[#$0020] !!! neu
enc_4:          move.w  D1,(A5)+        ; textbuf[i]=' '
                dbra    D0,enc_4

                movem.l (SP)+,D0/A5

; for(len=0;len<F && (c=crc_getc(file3)) != EOF; len++)

                moveq   #0,D3

                pea     (A5)

                add.w   D6,D6
                lea     0(A5,D6.w),A5
                lsr.w   #1,D6
                bra.s   enc_6
enc_5:          addq.l  #1,A5
                move.b  D4,(A5)+        ; textbuf[r+len]=c
                addq.w  #1,D3           ; len++
enc_6:          cmp.w   #F,D3
                bge.s   enc_7
              getc
                beq.s   enc_7           ; EOF? Ja! =>
                move.w  D0,D4
                bra.s   enc_5

; end for

enc_7:          movea.l (SP)+,A5

                move.w  D3,D0           ;!!! optimieren?
                ext.l   D0
                move.l  D0,textsize-BSS(A6) ; textsize=len

; for(i=1; i<=F; i++)

                moveq   #F-1,D7

                add.w   D6,D6           ;!!! neu: vorher weiter unten

                move.w  D6,-(SP)

                subq.w  #2,D6           ;!!! neu: vorher #1 (s.o.)
enc_8:
              InsertNo                ; InsertNode(r-i)         ***
                subq.w  #2,D6           ;!!! neu: vorher add.w D6,D6; ...; lsr.w #1,D6; subq.w #1,D6
enc_9:          dbra    D7,enc_8

                move.w  (SP)+,D6

              MatchInsertNo           ; InsertNode(r)          ***
                add.w   D5,D5

enc_10:         cmp.w   match_length-BSS(A6),D3 ;!!! vorher (A6) !!! optimieren
                bge.s   enc_11          ; if (match_length > len)
                move.w  D3,match_length-BSS(A6) ;   match_length=len
enc_11:         move.b  putlen-BSS(A6),D7
                move.w  D6,D1

                move.w  D6,-(SP)

                move.w  putbuf-BSS(A6),D6
                cmpi.w  #THRESHOLD,match_length-BSS(A6) ;[#2]
                bgt     enc_12          ; if match_length <=THRESHOLD
                move.w  #1,match_length-BSS(A6) ;   match_length=1 !!! vorher (A6)
                moveq   #0,D0
                move.w  0(A5,D1.w),D0
              EncodeCh                ; EncodeChar(textbuf[r])
                bra     enc_13

enc_12:         move.w  match_length-BSS(A6),D0 ;!!! vorher (A6)
                add.w   #$00FD,D0
              EncodeCh                ; EncodeChar(255-THRESHOLD+match_length)
                move.w  match_position-BSS(A6),D0
                lsr.w   #1,D0
              EncodePo                ; EncodePosition(match_position)

enc_13:         move.b  D7,putlen-BSS(A6)
                move.w  D6,putbuf-BSS(A6)

                move.w  (SP)+,D6

                movea.l lson,A2         ;!!! optimieren?
                movea.l dad,A4

; for(i=0;i<last_match_length && (c=crc_getc(file3))!= EOF;i++)

                move.w  match_length-BSS(A6),D0 ;

                moveq   #0,D4
                move.w  D0,D4
                add.l   D4,textsize-BSS(A6)
                dbra    D4,enc_14
enc_14a:        subq.w  #1,D3
                bra     enc_15

enc_14b:      InsertNo
enc_14:       DeleteNo                ; DeleteNode(s)

                move.w  #2*(N-1),D7     ;[#2*$0FFF] !!! neu: vorher siehe []
              getc
                beq     enc_14a         ; EOF? Ja! =>
                move.w  D0,0(A5,D5.w)   ; textbuf[s]=c;
                cmp.w   #2*(F-1),D5
                bge.s   enc_15          ; if (s<F-1)
                lea     2*N(A5),A0      ;!!! ändern, vorher ,A6
                move.w  D0,0(A0,D5.w)   ; textbuf[s+N]=c; !!! ändern, vorher (A6,...

enc_15:         addq.w  #2,D5
                and.w   D7,D5
                addq.w  #2,D6
                and.w   D7,D6
enc_16:         dbra    D4,enc_14b
              MatchInsertNo

; end for
; if ((textsize +=i) >= printcount && i>0)

enc_17:         tst.w   D3              ;fertig?
                beq.s   enc_18          ;Ja! =>

                move.l  textsize-BSS(A6),D1
                cmp.l   printcount-BSS(A6),D1
                blt     enc_10

                move.l  #BLOCKSIZE,D0
                add.l   D0,printcount-BSS(A6)

                movea.l ProcInd-BSS(A6),A0
                jsr     do_ProcInd
                bra     enc_10

enc_18:         move.l  textsize-BSS(A6),D0 ;Rest = textsize-(printcount-BLOCKSIZE)
                add.l   #BLOCKSIZE,D0
                sub.l   printcount-BSS(A6),D0

                movea.l ProcInd-BSS(A6),A0
                jsr     do_ProcInd

enc_22:         move.b  putlen-BSS(A6),D0
                beq.s   enc_23

                move.w  putbuf-BSS(A6),D0
                lsr.w   #8,D0
              putc    d0

enc_23:         bsr.s   shipout1

                movem.l (SP)+,D3-D7/A2-A6
                rts


;*******************
;* uchar shipin1 (void):
;* OUT D0.b: gelesenes Zeichen
;*     CCR : EOF: Zeroflag gesetzt

shipin1:        movem.l D1-D2/A0-A1,-(SP)

                movea.l comp_file-BSS(A6),A0
                bsr     shipin2_enc

                move.w  D0,D1
                addq.w  #1,D1           ;Was gelesen? -> EOF: Zeroflag gesetzt

                movem.l (SP)+,D1-D2/A0-A1
                rts


;*******************
;* void shipout1 (void):

shipout1:       movem.l D0-D2/A0-A1,-(SP)

                movea.l comp_file-BSS(A6),A0
                move.b  compress-BSS(A6),D0 ;compress
                bsr     shipout_enc

                movem.l (SP)+,D0-D2/A0-A1
                rts


;*******************
;* reconst: (auch in DECODE1.S)
;* IN  A6.l: BSS

reconst:        movem.l D0-A5,-(SP)     ;!!! ändern

                lea     hfreq-BSS(A6),A0
                lea     prnt-BSS(A6),A1
                lea     son-BSS(A6),A2

                moveq   #0,D0
                moveq   #0,D1

; Collect leaf nodes in the first half of the table
; and replace the hfreq by (hfreq+1)/2

rcon1:          cmpi.w  #2*T,0(A2,D1.w) ; if son[i] >= T
                blt.s   rcon2

                moveq   #1,D2
                add.w   0(A0,D1.w),D2
                lsr.w   #1,D2
                move.w  D2,0(A0,D0.w)   ; hfreq[j] = (hfreq[i]+1)/2
                move.w  0(A2,D1.w),0(A2,D0.w) ; son[j]=son[i]
                addq.w  #2,D0           ; j++

rcon2:          addq.w  #2,D1           ; i++
                cmp.w   #2*T,D1         ; i < T
                blo.s   rcon1

; begin constructing tree by connecting sons
; for (i=0; j=N_CHAR; j < T; i+=2; j++) {

                move.w  #N_CHAR*2,D3
                moveq   #0,D4
rcon3:          moveq   #2,D0
                add.w   D4,D0           ; k=i+2
                move.w  0(A0,D4.w),D6
                add.w   0(A0,D0.w),D6   ; f=hfreq[i]+hfreq[k]
                move.w  D6,0(A0,D3.w)   ; hfreq[j]=f

; for (k=j-1; f < hfreq[k]; k--);

                move.w  D3,D5           ;!!! neu

rcon4:          subq.w  #2,D5

                cmp.w   0(A0,D5.w),D6
                blo.s   rcon4

                addq.w  #2,D5
                move.w  D3,D7
                sub.w   D5,D7           ; l=(j-k) * 2

                lea     0(A0,D5.w),A3   ;nach oben schieben
movemem_a:      adda.w  D7,A3
                lea     2(A3),A4
                move.w  D7,D0
                beq.s   movemem_a2

movemem_a1:     move.w  -(A3),-(A4)
                subq.w  #2,D0
                bne.s   movemem_a1
movemem_a2:

                move.w  D6,0(A0,D5.w)   ; hfreq[k]= f

                lea     0(A2,D5.w),A3   ;nach oben schieben
movemem_b:      adda.w  D7,A3
                lea     2(A3),A4
                move.w  D7,D0
                beq.s   movemem_b2

movemem_b1:     move.w  -(A3),-(A4)
                subq.w  #2,D0
                bne.s   movemem_b1
movemem_b2:

                move.w  D4,0(A2,D5.w)   ; son[k] = i

                addq.w  #4,D4           ; i+=2
                addq.w  #2,D3           ; j++
                cmp.w   #2*T,D3
                blo.s   rcon3

; connect prnt
; for (i=0; i<T; i++) {

                moveq   #0,D0
rcon6:          move.w  0(A2,D0.w),D1
                move.w  D0,0(A1,D1.w)
                cmp.w   #2*T,D1
                blt.s   rcon7           ; if ((k=son[j]) >= T) {
                move.w  D0,0(A1,D1.w)   ; prnt[k] = i
                bra.s   rcon8
rcon7:          move.w  D0,0(A1,D1.w)   ; prnt[k] = i
                move.w  D0,2(A1,D1.w)   ; prnt[k+1] = i;
rcon8:          addq.w  #2,D0
                cmp.w   #2*T,D0
                blo.s   rcon6

                movem.l (SP)+,D0-A5     ;!!! ändern
                rts


;*******************

                DATA

DATA:

p_code:         DC.B $00,$20,$30,$40,$50,$58,$60,$68
                DC.B $70,$78,$80,$88,$90,$94,$98,$9C
                DC.B $A0,$A4,$A8,$AC,$B0,$B4,$B8,$BC
                DC.B $C0,$C2,$C4,$C6,$C8,$CA,$CC,$CE
                DC.B $D0,$D2,$D4,$D6,$D8,$DA,$DC,$DE
                DC.B $E0,$E2,$E4,$E6,$E8,$EA,$EC,$EE
                DC.B $F0,$F1,$F2,$F3,$F4,$F5,$F6,$F7
                DC.B $F8,$F9,$FA,$FB,$FC,$FD,$FE,$FF

p_len:          DC.B $03,$04,$04,$04,$05,$05,$05,$05
                DC.B $05,$05,$05,$05,$06,$06,$06,$06
                DC.B $06,$06,$06,$06,$06,$06,$06,$06
                DC.B $07,$07,$07,$07,$07,$07,$07,$07
                DC.B $07,$07,$07,$07,$07,$07,$07,$07
                DC.B $07,$07,$07,$07,$07,$07,$07,$07
                DC.B $08,$08,$08,$08,$08,$08,$08,$08
                DC.B $08,$08,$08,$08,$08,$08,$08,$08


;*******************

                BSS

BSS:

align 4
putbuf:         DS.W 1
putlen:         DS.B 1

align 4
match_position: DS.W 1
match_length:   DS.W 1

align 4
textsize:       DS.L 1          ;ulong textsize
printcount:     DS.L 1
printsize:      DS.L 1
file3:          DS.L 1          ;FILE file3
outrec:         DS.L 1          ;OutRec* outrec

align 4
parameter:
                DS.B 3          ;even
compress:       DS.B 1          ;uchar compress
comp_file:      DS.L 1          ;ArcFile *comp_file
ProcInd:        DS.L 1          ;ProcInd_t *ProcInd

align 4
hfreq:          DS.W T+1        ;(628 Bytes) !!! auch in decode1.s
align 4
prnt:           DS.W T+N_CHAR   ;(941 Bytes) !!! auch in decode1.s
align 4
son:            DS.W T          ;(627 Bytes) !!! auch in decode1.s

align 4

                END
