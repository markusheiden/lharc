
;***************************************
;* LHarc 1.13 Decodierung

include "offset.s"

;*******************
;* Export: Funktionen

export Decode1                        ;-> lharc.c

export shipin1                       ;nur für Profiler...
export shipout1
export reconst


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
;* Konstanten:

N               EQU 4096        ;lhaconst.h
F               EQU 60
THRESHOLD       EQU 2
N_CHAR          EQU 256-THRESHOLD+F
T               EQU N_CHAR*2-1
R               EQU T-1

BLOCKSIZE       EQU N*2


                TEXT

;*******************
;* MACRO getc:
;* IN  A0.l: FILE *file1
;* OUT D0.b: ausgelesenes BYTE

MACRO getc

LOCAL getc1
LOCAL getc2

                subq.l  #1,(A0)+        ;!!! neu: + statt 4(a0) unten
                bpl.s   getc1

                bsr     shipin1
                bra.s   getc2

getc1:          movea.l (A0),A1         ;!!! neu: vorher 4(A0)
                moveq   #0,D0
                move.b  (A1)+,D0
                move.l  A1,(A0)         ;!!! neu: vorher 4(A0)
                subq.l  #4,A0           ;!!! neu

getc2:

ENDM


;*******************
;* MACRO getw:
;* IN  A0.l: FILE *file1
;* OUT D7.w: ausgelesenes WORD

MACRO getw

              getc
                move.b  D0,D7
                lsl.w   #8,D7
              getc
                move.b  D0,D7

ENDM


;*******************
;* void update(int c): (auch in ENCODE1.S)
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
;* DecodeChar: (mixed with GetBit !)
;* IN  D6.w: getlen (~ bitcount)
;*     D7.w: getbuf (~ bitbuf)
;*     A4.l: son
;*     A6.l: BSS
;* OUT D0.w:

MACRO   DecodeCh

LOCAL   GBit
LOCAL   GBit4
LOCAL   GBit5
LOCAL   DeC3
LOCAL   DeC2

                move.w  2*R(A4),D1      ; C = son[R]
                move.w  #2*T,D2         ;!!! neu: vorher .l

                cmp.w   D2,D1           ;  while c < T
                bcc.s   DeC3

GBit:           dbra    D6,GBit4        ; keine Bits mehr da ?

                movea.l file1-BSS(A6),A0 ;!!! optimieren auf align.w
              getw
                moveq   #15,D6

GBit4:          add.w   D7,D7           ; getbuf << 1 & if (getbuf>0)
                bge.s   GBit5
                addq.w  #2,D1           ; c+=getbit()
GBit5:                                  ; getlen--
                move.w  0(A4,D1.w),D1   ; c=son[c]

DeC2:           cmp.w   D2,D1           ;  while c < T
                bcs.s   GBit

DeC3:           move.w  D1,D0
                sub.w   D2,D1           ; C -= T
                swap    D1

              update

                swap    D1
                move.w  D1,D0
                lsr.w   #1,D0           ; Ausgleich für Arrays

ENDM


;*******************
;* DecodePosition:
;* IN  D6.w: getlen
;*     D7.w: getbuf
;*     A6.l: BSS
;* OUT D0.w:

MACRO   DecodePo

LOCAL   Dpos1
LOCAL   Dpos2
LOCAL   Dpos3
LOCAL   GetBit5
LOCAL   GetBit6
LOCAL   GetByte1
LOCAL   GetByte4

; while getlen<=8 {

                subq.b  #8,D6           ;!!! neu: vorher moveq #8,D4; cmp.b D4,D6
                bgt.s   GetByte4

;   i=rgetc(file1)

GetByte1:       movea.l file1-BSS(A6),A0
              getc

;   getbuf |= i << 8 - getlen

                moveq   #0,D1           ;!!! neu: vorher move.w D4,D1 (s.o.)
                sub.b   D6,D1
                lsl.w   D1,D0
                or.w    D0,D7

;   getlen+=8

                addq.b  #8,D6

; i=getbuf;

GetByte4:       and.l   #$0000FFFF,D7   ;!!! optimieren?
                lsl.l   #8,D7
                swap    D7

                lea     d_code,A0       ;!!! DATA
                moveq   #0,D4
                move.b  0(A0,D7.w),D4
                lea     d_len-d_code(A0),A0 ;!!! DATA
                moveq   #0,D2
                move.b  0(A0,D7.w),D2
                lsl.w   #6,D4
                swap    D7
                subq.w  #2,D2

Dpos1:          move.w  D6,D6           ; <8 bits availale?
                bgt.s   GetBit5         ; getlen = 0?

                movea.l file1-BSS(A6),A0
              getw
                moveq   #16,D6

GetBit5:        move.w  D2,D0
                cmp.w   D6,D0
                blt.s   GetBit6
                move.w  D6,D0

GetBit6:        lsl.l   D0,D7
                sub.w   D0,D6
                sub.w   D0,D2
Dpos2:          bne.s   Dpos1           ; nächstes bit

                swap    D7
                moveq   #$3F,D0
                and.w   D7,D0
                swap    D7

Dpos3:          or.w    D4,D0

ENDM


;*******************
;* MACRO ferror:

MACRO   ferror  file

                movea.l file,A0
                move.w  12(A0),D0
                btst    #14,D0

ENDM


;*******************
;* void Decode1 (ArcFile *decomp_file, ProcInd_t *ProcInd):
;* IN  A0.l: ArcFile   *decomp_file
;*     A1.l: ProcInd_t *ProcInd

Decode1:        movem.l D3-D7/A2-A6,-(SP)

                lea     BSS,A6

                movem.l A0-A1,parameter-BSS(A6) ;Parameter sichern

                movea.l decomp_file-BSS(A6),A5
                move.l  AF_size(A5),origsize-BSS(A6)
                move.l  AF_arc(A5),file1-BSS(A6)

                lea     outrec-BSS(A6),A0
                move.l  A0,AF_outrec(A5)
                movea.l buffer_3,A1     ;!!! BSS extern
                move.l  bsize,D0        ;!!! BSS extern
                bsr     OpenOut

                movea.l A5,A0
                bsr     init_shipin_dec

; if textsize == 0
;    return

                move.l  origsize-BSS(A6),D0
                beq     Dcode19

;void StartHuf (void)
;{
StartHuf:       lea     hfreq-BSS(A6),A0
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

                move.w  #$FFFF,hfreq+T*2-BSS(A6) ;hfreq[T]=0xffff !!! neu: war $04E6(A0)
                clr.w   prnt+R*2-BSS(A6) ; prnt[R]=0
;}

                lea     hfreq-BSS(A6),A2 ;A3 ist frei
                lea     son-BSS(A6),A4
                movea.l textbuf,A5      ;!!! BSS extern

                move.w  #N-F,D5         ; r = N-F; [#$0FC4]
                moveq   #0,D6           ; getlen = 0
                moveq   #0,D7           ; getbuf = 0

                movea.l A5,A0           ;for (i=0; i<N-F;i++)
                move.w  D5,D0
                moveq   #' ',D1
Dcode4:         move.b  D1,(A0)+        ;textbuf[i] = ' '
                subq.w  #1,D0           ;i++; i<N-F?
                bne.s   Dcode4          ;Ja! =>

; for (count = 0; count < textsize;) {

                move.l  #BLOCKSIZE,printcount-BSS(A6)

                clr.l   delen-BSS(A6)

; c=DecodeCh()

Dcode6:
              DecodeCh

; if (c<256) {

                cmp.w   #$0100,D0
                bge.s   Dcode8

                move.b  D0,0(A5,D5.w)   ; textbuf[r++]=c;
                addq.w  #1,D5
                and.w   #N-1,D5         ; r & = (N-1); [#$0FFF]

; putc(c)

                lea     outrec-BSS(A6),A0
                movea.l (A0),A1         ;ptr
                move.b  D0,(A1)+
                move.l  A1,(A0)+        ;ptr
                subq.l  #1,(A0)         ;cnt
                bpl.s   Dcode7

                bsr     shipout1

Dcode7:         addq.l  #1,delen-BSS(A6) ; count ++
                bra     Dcode12


; }
; else
; {
; i= (r-DecodePosition()-1) & (N-1)

Dcode8:         moveq   #0,D3           ;!!! neu statt ext.l weiter unten
                move.w  D0,D3

              DecodePo

                move.w  D5,D4
                sub.w   D0,D4
                subq.w  #1,D4

                move.w  #N-1,D2         ;[#$0FFF]
                and.w   D2,D4

                exg     D3,D4

                sub.w   #$00FD,D4       ; j = c - 255+THRESHOLD !!! neu: vorher add.w #$FF03-1,D4

; for (k=0; k<j; k++) {

                add.l   D4,delen-BSS(A6)

                subq.w  #1,D4           ;!!! neu: statt sub.w #$00FD+1,D4

                lea     outrec-BSS(A6),A0
                movea.l (A0)+,A1        ;ptr

Dcode9:         and.w   D2,D3           ; c=textbuf[(i+k) & (N-1)]
                move.b  0(A5,D3.w),D0

                move.b  D0,0(A5,D5.w)   ; textbuf[r++] = c;
                addq.w  #1,D5
                and.w   D2,D5           ; r &=(N-1)

; putc(c)

                move.b  D0,(A1)+
                subq.l  #1,(A0)
                bpl.s   Dcode10

; Hier shipout_decode

                move.l  A1,-(A0)        ;ptr

                bsr.s   shipout1

                lea     outrec-BSS(A6),A0
                movea.l (A0)+,A1        ;ptr

Dcode10:

;    count++;
;   }

                addq.w  #1,D3

Dcode11:        dbra    D4,Dcode9

                move.l  A1,outrec-BSS(A6)

;   if (count >= printcount) {

Dcode12:        move.l  delen-BSS(A6),D0
                cmp.l   origsize-BSS(A6),D0
                bhs.s   Dcode13

                cmp.l   printcount-BSS(A6),D0
                blo     Dcode6

;    printcount +=blocksize;

                move.l  #BLOCKSIZE,D0
                add.l   D0,printcount-BSS(A6)

                movea.l ProcInd-BSS(A6),A0
                jsr     do_ProcInd
                bra     Dcode6

Dcode13:        move.l  origsize-BSS(A6),D0 ;Rest = origsize-(printcount-BLOCKSIZE)
                add.l   #BLOCKSIZE,D0
                sub.l   delen-BSS(A6),D0

                movea.l ProcInd-BSS(A6),A0
                jsr     do_ProcInd

Dcode19:        bsr.s   shipout1

                movem.l (SP)+,D3-D7/A2-A6
                rts


;*******************
;* uchar shipin1 (void):

shipin1:        movem.l D1-D2/A0-A1,-(SP)

                movea.l decomp_file-BSS(A6),A0 ;gibt Zeichen in D0.w zurück
                bsr     shipin2_dec

                movem.l (SP)+,D1-D2/A0-A1
                rts


;*******************
;* shipout1:
;* IN  A6.l: BSS

shipout1:       movem.l D0-D2/A0-A1,-(SP)

                movea.l decomp_file-BSS(A6),A0
                bsr     shipout_dec

                movem.l (SP)+,D0-D2/A0-A1
                rts


;*******************
;* reconst: (auch in ENCODE1.S)
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

d_code:         DC.B $00,$00,$00,$00,$00,$00,$00,$00
                DC.B $00,$00,$00,$00,$00,$00,$00,$00
                DC.B $00,$00,$00,$00,$00,$00,$00,$00
                DC.B $00,$00,$00,$00,$00,$00,$00,$00
                DC.B $01,$01,$01,$01,$01,$01,$01,$01
                DC.B $01,$01,$01,$01,$01,$01,$01,$01
                DC.B $02,$02,$02,$02,$02,$02,$02,$02
                DC.B $02,$02,$02,$02,$02,$02,$02,$02
                DC.B $03,$03,$03,$03,$03,$03,$03,$03
                DC.B $03,$03,$03,$03,$03,$03,$03,$03
                DC.B $04,$04,$04,$04,$04,$04,$04,$04
                DC.B $05,$05,$05,$05,$05,$05,$05,$05
                DC.B $06,$06,$06,$06,$06,$06,$06,$06
                DC.B $07,$07,$07,$07,$07,$07,$07,$07
                DC.B $08,$08,$08,$08,$08,$08,$08,$08
                DC.B $09,$09,$09,$09,$09,$09,$09,$09
                DC.B $0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
                DC.B $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B
                DC.B $0C,$0C,$0C,$0C,$0D,$0D,$0D,$0D
                DC.B $0E,$0E,$0E,$0E,$0F,$0F,$0F,$0F
                DC.B $10,$10,$10,$10,$11,$11,$11,$11
                DC.B $12,$12,$12,$12,$13,$13,$13,$13
                DC.B $14,$14,$14,$14,$15,$15,$15,$15
                DC.B $16,$16,$16,$16,$17,$17,$17,$17
                DC.B $18,$18,$19,$19,$1A,$1A,$1B,$1B
                DC.B $1C,$1C,$1D,$1D,$1E,$1E,$1F,$1F
                DC.B $20,$20,$21,$21,$22,$22,$23,$23
                DC.B $24,$24,$25,$25,$26,$26,$27,$27
                DC.B $28,$28,$29,$29,$2A,$2A,$2B,$2B
                DC.B $2C,$2C,$2D,$2D,$2E,$2E,$2F,$2F
                DC.B $30,$31,$32,$33,$34,$35,$36,$37
                DC.B $38,$39,$3A,$3B,$3C,$3D,$3E,$3F

d_len:          DC.B $03,$03,$03,$03,$03,$03,$03,$03
                DC.B $03,$03,$03,$03,$03,$03,$03,$03
                DC.B $03,$03,$03,$03,$03,$03,$03,$03
                DC.B $03,$03,$03,$03,$03,$03,$03,$03
                DC.B $04,$04,$04,$04,$04,$04,$04,$04
                DC.B $04,$04,$04,$04,$04,$04,$04,$04
                DC.B $04,$04,$04,$04,$04,$04,$04,$04
                DC.B $04,$04,$04,$04,$04,$04,$04,$04
                DC.B $04,$04,$04,$04,$04,$04,$04,$04
                DC.B $04,$04,$04,$04,$04,$04,$04,$04
                DC.B $05,$05,$05,$05,$05,$05,$05,$05
                DC.B $05,$05,$05,$05,$05,$05,$05,$05
                DC.B $05,$05,$05,$05,$05,$05,$05,$05
                DC.B $05,$05,$05,$05,$05,$05,$05,$05
                DC.B $05,$05,$05,$05,$05,$05,$05,$05
                DC.B $05,$05,$05,$05,$05,$05,$05,$05
                DC.B $05,$05,$05,$05,$05,$05,$05,$05
                DC.B $05,$05,$05,$05,$05,$05,$05,$05
                DC.B $06,$06,$06,$06,$06,$06,$06,$06
                DC.B $06,$06,$06,$06,$06,$06,$06,$06
                DC.B $06,$06,$06,$06,$06,$06,$06,$06
                DC.B $06,$06,$06,$06,$06,$06,$06,$06
                DC.B $06,$06,$06,$06,$06,$06,$06,$06
                DC.B $06,$06,$06,$06,$06,$06,$06,$06
                DC.B $07,$07,$07,$07,$07,$07,$07,$07
                DC.B $07,$07,$07,$07,$07,$07,$07,$07
                DC.B $07,$07,$07,$07,$07,$07,$07,$07
                DC.B $07,$07,$07,$07,$07,$07,$07,$07
                DC.B $07,$07,$07,$07,$07,$07,$07,$07
                DC.B $07,$07,$07,$07,$07,$07,$07,$07
                DC.B $08,$08,$08,$08,$08,$08,$08,$08
                DC.B $08,$08,$08,$08,$08,$08,$08,$08


;*******************

                BSS

BSS:

align 4
delen:          DS.L 1
printcount:     DS.L 1
origsize:       DS.L 1          ;ulong origsize
file1:          DS.L 1          ;FILE * file1

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
                DS.B 1          ; 28: buffered

align 4
hfreq:          DS.W T+1        ;(628 Bytes) !!! auch in encode1.s
align 4
prnt:           DS.W T+N_CHAR   ;(941 Bytes) !!! auch in encode1.s
align 4
son:            DS.W T          ;(627 Bytes) !!! auch in encode1.s

align 4

                END
