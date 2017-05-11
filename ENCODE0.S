
;***************************************
;* Larc Codierung

include "offset.s"

;*******************
;* Export: Funktionen

export EncodeOld

;export shipinold                      ;nur für Profiler...
;export shipoutold
export DeleteONode
export InsertONode


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

FOLD            EQU 18
N               EQU 4096        ;lhaconst.h
F               EQU 18
THRESHOLD       EQU 2
NIL             EQU N

BLOCKSIZE       EQU N*2


                TEXT

;*******************
;* MACRO putc:
;* IN  D0.b: zu schreibendes Zeichen

MACRO putc

LOCAL putc1

                movea.l outrec-BSS(A6),A0

                movea.l (A0),A1         ;Speicherzeiger++={D0}
                move.b  D0,(A1)+
                move.l  A1,(A0)+
                subq.l  #1,(A0)         ;cnt--
                bpl.s   putc1

                bsr     shipoutold

putc1:

ENDM


;*******************
;* MACRO getc:
;* OUT D0.b: ausgelesenes Byte
;*     CCR : EOF: Zeroflag gesetzt

MACRO getc

LOCAL getc1
LOCAL getc2

                movea.l file3-BSS(A6),A0
                subq.l  #1,(A0)+        ; _cnt
                bpl.s   getc1

                bsr     shipinold
                bra.s   getc2

getc1:          moveq   #0,D0
                movea.l (A0),A1         ; _ptr
                move.b  (A1)+,D0
                move.l  A1,(A0)

getc2:

ENDM


;*******************
;* void EncodeOld (ArcFile *, ProcInd_t *, uchar)
;* IN  D0.b   : uchar     compress
;*     A0.l   : ArcFile   *comp_file
;*     A1.l   : ProcInd_t *ProcInd
;*
;* REGISTER:
;* D3.w: int r
;* D4.w: int s
;* D5.w: int m=N-1
;* D6.w: int len
;* D7.w: int match_len
;* A2.l: *code
;* A3.l: *tbuf
;* A4.l: code_buf

EncodeOld:      movem.l D3-D7/A2-A6,-(SP)

                lea     BSS,A6

                movem.l D0/A0-A1,parameter-BSS(A6) ;Parameter sichern

;void InitTree(void)
;{
InitTree:       movea.l dad,A0          ;p=dad
                move.w  #N-1,D0         ;for (i=N;--i>0;)
                move.w  #NIL<<1,D1      ;nil_2=NILL<<1
it1:            move.w  D1,(A0)+        ;*p++=nil_2
                subq.w  #1,D0           ;--i>=0?
                bpl.s   it1             ;Ja! =>


                movea.l rson,A0         ;p=&rson[N+1]
                lea     (N+1)*2(A0),A0
                move.w  #256-1,D0       ;for (i=256;--i>=0;)
it2:            move.w  D1,(A0)+        ;*p++=nil_2
                subq.w  #1,D0           ;--i>=0?
                bpl.s   it2             ;Ja! =>
;}

                movea.l comp_file-BSS(A6),A0
                move.l  AF_file(A0),file3-BSS(A6)
                move.l  AF_outrec(A0),outrec-BSS(A6)

                move.l  #BLOCKSIZE,printcount-BSS(A6)

                moveq   #0,D0
                move.l  D0,textsize-BSS(A6) ;textsize=0

                lea     code_buf-BSS(A6),A2 ;uchar *code=code_buf
                movea.l textbuf,A3      ;uchar *tbuf=textbuf !!! BSS extern
                movea.l A2,A4

                move.w  #N-F,D3         ;uchar r; r=N-F
                moveq   #0,D4           ;uchar s=0
                move.w  #N-1,D5         ;uchar m=N-1
                move.b  #1,mask-BSS(A6) ;uchar mask=1


                clr.b   (A2)+           ;*code++=0

                movea.l A3,A5           ;ptr=tbuf
                move.w  D3,D0           ;i=r (r=N-F)
                subq.w  #1,D0
                moveq   #' ',D1

Enc_for1:       move.b  D1,(A5)+        ;*ptr++=' '
                subq.w  #1,D0           ;--i>=0?
                bpl.s   Enc_for1        ;Ja! =>

                moveq   #0,D6           ;i=0

Enc_for2:
              getc                    ;c=crc_getc(file3)
                beq.s   Enc_endfor2     ;EOF? Ja! =>

                move.b  D0,(A5)+        ;*ptr++=c

                addq.w  #1,D6           ;i++
                cmp.w   #F,D6           ;i<F?
                blt.s   Enc_for2        ;Ja! =>

Enc_endfor2:    move.l  D6,textsize-BSS(A6) ;textsize=len=i

                tst.l   D6              ;if(!textsize)
                beq     Enc_exit

                move.w  #N-F-1,D0       ;i=1; r=N-F
Enc_for3:       bsr     InsertONode     ;InsertONode(r-i)
                subq.w  #1,D0           ;i<=F?; i++
                cmp.w   #N-F-F,D0
                bge.s   Enc_for3        ;Ja! =>

                move.w  D3,D0           ;InsertONode(r)
                bsr     InsertONode

Enc_do1:        move.w  match_length-BSS(A6),D2 ;D2=match_length
                cmp.w   D2,D6           ;if (match_length>len)
                bge.s   Enc_endif1

                move.w  D6,D2           ;match_length=len

Enc_endif1:     cmpi.w  #THRESHOLD,D2   ;if(match_length<=THRESHOLD)
                bgt.s   Enc_else2

                moveq   #1,D2           ;matchlength=1
                move.b  mask-BSS(A6),D0 ;code_buf[0]|=mask
                or.b    D0,(A4)
                move.b  0(A3,D3.w),(A2)+ ;*code++=tbuf[r]
                bra.s   Enc_endif2

Enc_else2:      move.w  match_position-BSS(A6),D0 ;*code++=(uchar) match_position
                move.b  D0,(A2)+
                lsr.w   #4,D0           ;*code++=(uchar) (((match_position>>4)&0xF0)|(match_length-(THRESHOLD+1)))
                and.w   #$00F0,D0
                moveq   #-(THRESHOLD+1),D1
                add.w   D2,D1
                or.w    D1,D0
                move.b  D0,(A2)+

Enc_endif2:     move.w  D2,match_length-BSS(A6)

                move.b  mask-BSS(A6),D0 ;if(!mask<<=1)
                add.b   D0,mask-BSS(A6)
                bne.s   Enc_endif3

                move.l  A2,D2           ;i=(int) (code-code_buf)
                sub.l   A4,D2

                movea.l A4,A2           ;ptr=(code=code_buf)
                movea.l A4,A5

                subq.w  #1,D2           ;--i>=0?
                bmi.s   Enc_wend1

Enc_while1:     move.b  (A5)+,D0        ;buf_putc(*ptr++) !!! optimieren
              putc

                subq.w  #1,D2           ;--i>=0?
                bpl.s   Enc_while1

Enc_wend1:      clr.b   (A2)+           ;*code++=0
                move.b  #1,mask-BSS(A6) ;mask=1

Enc_endif3:     move.w  match_length-BSS(A6),last_match_length-BSS(A6) ;!!! optimieren

                moveq   #0,D2           ;i=0

                cmp.w   last_match_length-BSS(A6),D2 ;i<last_match_length? !!! optimieren: tst.w, beq
                bge.s   Enc_endfor4

Enc_for4:
              getc
                beq.s   Enc_endfor4     ;EOF? Ja! =>

                move.b  D0,D1           ;c sichern

                move.w  D4,D0           ;DeleteONode(s)
                bsr     DeleteONode
                move.b  D1,0(A3,D4.w)   ;tbuf[s]=c

                cmp.w   #F-1,D4         ;if(s<F-1)
                bge.s   Enc_endif4

                lea     N(A3),A0        ;tbuf[s+N]=c
                move.b  D1,0(A0,D4.w)

Enc_endif4:     addq.w  #1,D4           ;s=(++s)&m
                and.w   D5,D4
                addq.w  #1,D3           ;r=(++r)&m
                and.w   D5,D3

                move.w  D3,D0
                bsr     InsertONode

                addq.w  #1,D2           ;i++
                cmp.w   last_match_length-BSS(A6),D2 ;i<last_match_length
                blt.s   Enc_for4

Enc_endfor4:    move.l  D2,-(SP)        ;!!! ändern

                move.l  textsize-BSS(A6),D0
                add.l   D2,D0
                move.l  D0,textsize-BSS(A6)

                cmp.l   printcount-BSS(A6),D0
                blo.s   Enc_endif5

                move.l  #BLOCKSIZE,D0
                add.l   D0,printcount-BSS(A6)

                movea.l ProcInd-BSS(A6),A0
                jsr     do_ProcInd

Enc_endif5:     move.l  (SP)+,D2

                cmp.w   last_match_length-BSS(A6),D2
                bge.s   Enc_wend2

Enc_while2:     move.w  D4,D0           ;DeleteONode(s)
                bsr.s   DeleteONode

                addq.w  #1,D4           ;s=(++s)&m
                and.w   D5,D4
                addq.w  #1,D3           ;r=(++r)&m
                and.w   D5,D3

                subq.l  #1,D6           ;if(--len)
                beq.s   Enc_endif6

                move.w  D3,D0           ;InsertONode(r)
                bsr     InsertONode

Enc_endif6:     addq.w  #1,D2
                cmp.w   last_match_length-BSS(A6),D2
                blt.s   Enc_while2

Enc_wend2:      tst.l   D6              ;while(len>0)
                bgt     Enc_do1

                move.l  D2,-(SP)

                move.l  textsize-BSS(A6),D0 ;Rest = textsize-(printcount-BLOCKSIZE)
                add.l   #BLOCKSIZE,D0
                sub.l   printcount-BSS(A6),D0

                movea.l ProcInd-BSS(A6),A0
                jsr     do_ProcInd

                move.l  (SP)+,D2

                move.l  A2,D2           ;if((i=(int) (code-code_buf))>1)
                sub.l   A4,D2
                cmp.w   #1,D2           ;!!! optimieren
                ble.s   Enc_endif7

                subq.w  #1,D2

Enc_while3:     move.b  (A4)+,D0        ;ptr=code_buf; buf_putc(*ptr++)
              putc
                subq.w  #1,D2
                bpl.s   Enc_while3

Enc_endif7:     bsr.s   shipoutold

Enc_exit:       movem.l (SP)+,D3-D7/A2-A6
                rts


;*******************
;* void shipoutold (void):

shipoutold:     movem.l D0-D2/A0-A1,-(SP)

                movea.l comp_file-BSS(A6),A0
                move.b  compress-BSS(A6),D0
                bsr     shipout_enc

                movem.l (SP)+,D0-D2/A0-A1
                rts


;*******************
;* DeleteONode:

DeleteONode:    movem.l D0-A5,-(SP)     ;!!! ändern

                movea.l lson,A2         ;!!! BSS extern
                movea.l rson,A3         ;!!! BSS extern
                move.w  D0,D5
                move.w  #2*NIL,D7
                movea.l dad,A0          ;!!! BSS extern
                add.w   D5,D5

; if dad[p] == NIL

                cmp.w   0(A0,D5.w),D7
                beq.s   DNode_9

; if rson[p] == NIL

                cmp.w   0(A3,D5.w),D7
                beq.s   DNodex1

; if lson[p] == NIL

DNode_1:        cmp.w   0(A2,D5.w),D7
                beq.s   DNodex2

DNode_2:        lea     0(A2,D5.w),A4   ; lson[p]
                lea     0(A3,D5.w),A5   ; rson[p]
                move.w  (A4),D1

                move.w  D1,D2
                cmp.w   0(A3,D2.w),D7
                beq.s   DNode_5

; do { q=rson[q] } while (rson[q] != NIL}

DNode_3:        move.w  0(A3,D2.w),D2
                cmp.w   D7,D2
                beq.s   DNode_4
                move.w  D2,D1
                bra.s   DNode_3

DNode_4:        move.w  D1,D2
                move.w  0(A0,D2.w),D3
                lea     0(A2,D2.w),A1   ; rson[q]
                move.w  (A1),0(A3,D3.w) ; lson[dad[q]] = rson[q]
                move.w  (A1),D3
                move.w  0(A0,D2.w),0(A0,D3.w) ; dad[rson[q]]=dad[q[
                move.w  (A4),D3
                move.w  D3,(A1)         ; rson[q]=rson[p]
                move.w  D1,0(A0,D3.w)
DNode_5:        move.w  (A5),D3
                move.w  D3,0(A3,D2.w)   ; rson[q] = rson[p]
                move.w  D1,0(A0,D3.w)   ; dad[rson[p]] = q
DNode_6:        move.w  0(A0,D5.w),0(A0,D1.w) ; dad[q]=dad[p]

                lea     0(A0,D5.w),A5   ; A5=*dad[p]
                move.w  (A5),D3         ; D3 = cardinal dad[p]
                cmp.w   0(A3,D3.w),D5
                bne.s   DNode_7         ; if rson[dad[p]]=p

; else ..

                move.w  D1,0(A3,D3.w)   ; rson[dad[p]]=q
                move.w  D7,(A5)

                movem.l (SP)+,D0-A5     ;!!! ändern
                rts

; if ..

DNode_7:        move.w  D1,0(A2,D3.w)   ; lson[dad[p]]=q

; endif ..

DNode_8:        move.w  D7,(A5)         ; dad[p]=NIL

DNode_9:        movem.l (SP)+,D0-A5     ;!!! ändern
                rts

DNodex2:        move.w  0(A3,D5.w),D1
                bra.s   DNode_6
DNodex1:        move.w  0(A2,D5.w),D1
                bra.s   DNode_6


;*******************
;* void InsertNode (int r):

; register int i,p,cmp;
; unsigned char *key;
; unigned c;

; register D1 = cmp
; register D2 = p
; register A1 = *key
; register A2 = rson
; register A3 = lson

; D0 = cardinal p

; Benötigt: A0 = textbuf
;           A2 = lson
;           A3 = rson
;           A4 = dad

InsertONode:    movem.l D0-A5,-(SP)     ;!!! ändern

                lea     BSS,A6

                movea.l lson,A2         ;!!! BSS extern
                movea.l rson,A3         ;!!! BSS extern
                movea.l dad,A4          ;!!! BSS extern
                movea.l textbuf,A5      ;!!! BSS extern

                move.w  D0,D6
                moveq   #1,D1           ; cmp=1

                lea     0(A5,D6.w),A1   ; key=&textbuf[r]
                add.w   D6,D6

                moveq   #0,D2
                move.b  (A1),D2         ; key[0]
                add.w   #N+1,D2         ; p= N+1+key[0] [#4097]
                add.w   D2,D2           ; cardinal

                move.w  #2*NIL,D7       ; NIL
                move.w  D7,0(A2,D6.w)   ; rson[r] = NIL
                move.w  D7,0(A3,D6.w)   ; lson[r] = NIL

                clr.w   match_length-BSS(A6) ; match_length=0

; for ...

I_Node1:        tst.w   D1              ; if (cmp > 0) {
                blt.s   I_Node4
                lea     0(A3,D2.w),A0   ; rson[p]           !!! ÄNDERN+
                cmp.w   (A0),D7         ; if rson[p] != NIL !!! ÄNDERN+
                bne.s   I_Node5         ; p=rson[p] else

                move.w  D6,(A0)         ; rson[p] = r       !!! ÄNDERN+
                move.w  D2,0(A4,D6.w)   ; dad[r] = p
                bra     I_Node11

I_Node3:        move.w  D6,(A0)         ; lson[p] = r       !!! ÄNDERN+
                move.w  D2,0(A4,D6.w)   ; dad[r] = p
                bra     I_Node11

I_Node4:        lea     0(A2,D2.w),A0   ; d7=lson[p]        !!! ÄNDERN+
                cmp.w   (A0),D7         ; if lson[p] != NIL !!! ÄNDERN+
                beq.s   I_Node3

; for (i=1; i<F; i++)

I_Node5:        move.w  (A0),D2         ;                   !!! ÄNDERN+
                moveq   #0,D1
                moveq   #FOLD-2,D5
                lea     1(A1),A0        ; key[1]

                move.l  A1,D0           ;A1 sichern

                lsr.w   #1,D2
                lea     1(A5,D2.w),A1   ; textbuf[p+1]     !!! ÄNDERN-
                add.w   D2,D2
I_Node6:        cmpm.b  (A0)+,(A1)+     ;                   !!! ÄNDERN-
                dbne    D5,I_Node6

I_Node7:        moveq   #FOLD-1,D3
                sub.w   D5,D3
                moveq   #0,D5
                move.b  -(A0),D1        ;!!! neu: war -1
                move.b  -(A1),D5        ;!!! neu: war -1    !!! ÄNDERN-
                sub.w   D5,D1           ; d1=key[i]-textbuf[p+i]

                movea.l D0,A1           ;A1 restaurieren

                cmp.w   match_length-BSS(A6),D3 ; if i>match_length
                ble.s   I_Node1

                move.w  D2,D4
                lsr.w   #1,D4
                move.w  D4,match_position-BSS(A6)

                move.w  D3,match_length-BSS(A6) ; match_length=i
                cmp.w   #FOLD,D3        ; if i>=F
                blt.s   I_Node1         ; break

I_Node8:        move.w  0(A4,D2.w),0(A4,D6.w) ; dad[r] = dad[p]
                move.w  0(A2,D2.w),0(A2,D6.w) ; lson[r] = lson[p]
                move.w  0(A3,D2.w),0(A3,D6.w) ; rson[r] = rson[p]

                move.w  0(A2,D2.w),D4
                move.w  D6,0(A4,D4.w)   ; dad[lson[p]]=r

                move.w  0(A3,D2.w),D4
                move.w  D6,0(A4,D4.w)   ; dad[rson[p]]=r

                lea     0(A4,D2.w),A0   ;                   !!! ÄNDERN+
                move.w  (A0),D4         ; a6 = *dat[p]      !!! ÄNDERN+
                cmp.w   0(A3,D4.w),D2
                beq.s   I_Node12

                move.w  (A0),D3         ;                   !!! ÄNDERN+
                move.w  D6,0(A2,D3.w)   ; lson[dad[p]] = r

                move.w  D7,(A0)         ; dad[p] = NIL      !!! ÄNDERN+

I_Node11:       movem.l (SP)+,D0-A5     ;!!! ändern
                rts

I_Node12:       move.w  D6,0(A3,D4.w)
                move.w  D7,(A0)         ; dad[p] = NIL      !!! ÄNDERN+

                movem.l (SP)+,D0-A5     ;!!! ändern
                rts


;*******************
;* uchar shipinold (void):
;* OUT D0.b: ausgelesenes Byte
;*     CCR : EOF: Zeroflag gesetzt

shipinold:      movem.l D1-D2/A0-A1,-(SP)

                movea.l comp_file-BSS(A6),A0
                bsr     shipin2_enc

                move.w  D0,D1
                addq.w  #1,D1

                movem.l (SP)+,D1-D2/A0-A1
                rts


;*******************
;* BSS:

                BSS

BSS:

mask:           DS.B 1          ;uchar mask

align 4
match_position: DS.W 1          ;int match_position
match_length:   DS.W 1          ;int match_length
last_match_length:DS.W 1        ;int last_match_length

align 4
textsize:       DS.L 1          ;ulong textsize
printcount:     DS.L 1
file3:          DS.L 1          ;FILE *file3
outrec:         DS.L 1          ;OutRec *outrec

align 4
parameter:
                DS.B 3          ;even
compress:       DS.B 1          ;uchar compress
comp_file:      DS.L 1          ;ArcFile *comp_file
ProcInd:        DS.L 1          ;ProcInd_t *ProcInd

align 4
code_buf:       DS.B 34         ;(34 Bytes) uchar code_buf[34]

align 4

                END
