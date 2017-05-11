
;*******************
;* Export: Funktionen

export test_afx
export afxonoff


;*******************
;* Import: Variablen

import buffer_gen
import obj


;*******************
;* Konstanten:

_onoff          EQU 8


;*******************
;* test_afx:
;* IN:  A0.l:

test_afx:       movem.l D3-D6/A2-A6,-(SP)

                movea.l A0,A4           ; path

                movea.l buffer_gen,A5

                clr.w   -(SP)
                pea     (A4)
                move.w  #$003D,-(SP)    ; Fopen
                trap    #1
                addq.w  #8,SP
                tst.l   D0
                bmi     _error

                move.l  D0,D3           ; handle

                pea     (A5)
                pea     2048.w
                move.w  D3,-(SP)
                move.w  #$003F,-(SP)    ; Fread
                trap    #1
                lea     12(SP),SP

                move.l  D0,D4           ; len

                move.w  D3,-(SP)
                move.w  #$003E,-(SP)    ; Fclose
                trap    #1
                addq.w  #4,SP

                tst.l   D4
                bmi     _error

                cmpi.w  #$601A,(A5)
                bne.s   no_prg

                tst.l   14(A5)          ; ph_slen
                beq     is_prg

                tst.l   22(A5)          ; ph_prgflags
                bne     is_prg

                tst.b   obj
                beq.s   is_prg
                bra.s   unpacked

no_prg:         movea.l A5,A1
                move.w  D4,D0
                subq.w  #1,D0
                moveq   #'-',D1
                moveq   #0,D3

search_header:  cmp.b   (A1)+,D1
                bne.s   cont_search
                cmp.b   3(A1),D1
                bne.s   cont_search

                cmpi.b  #'l',(A1)
                beq.s   test_lzh
                cmpi.b  #'L',(A1)
                beq.s   test_lzh

                cmpi.b  #'a',(A1)
                bne.s   cont_search
                cmpi.b  #'f',1(A1)
                bne.s   cont_search
                cmpi.b  #'x',2(A1)
                seq     D3
                beq.s   test_lzh

cont_search:    dbra    D0,search_header
                bra.s   unpacked

test_lzh:       subq.l  #3,A1

                cmpi.b  #2,20(A1)
                beq.s   is_lzh

                movea.l A1,A0
                moveq   #0,D0
                moveq   #0,D1
                moveq   #0,D2

                move.b  (A0)+,D1
                move.b  (A0)+,D2
                subq.w  #1,D1

get_chk:        add.b   (A0)+,D0
                dbra    D1,get_chk

                cmp.b   D0,D2
                seq     D0
                bne.s   unpacked

                tst.w   D3
                bne.s   is_afx

is_lzh:         moveq   #2,D0
                bra.s   testx

_error:         moveq   #-1,D0
                bra.s   testx

unpacked:       moveq   #0,D0
                bra.s   testx

is_afx:         moveq   #1,D0
                bra.s   testx

is_prg:         moveq   #3,D0

testx:          movem.l (SP)+,D3-D6/A2-A6
                rts


;*******************
;* afxonoff:

afxonoff:       movem.l D3-D6/A2-A6,-(SP)
                bsr.s   find_afx
                cmpa.l  #0,A4
                beq.s   onofX
                move.l  _onoff(A4),D1
                move.l  D0,_onoff(A4)
                move.l  D1,D0

onofX:          movem.l (SP)+,D3-D6/A2-A6
                rts


;*******************
;* find_afx:

find_afx:       move.l  D0,-(SP)

                clr.l   -(SP)
                move.w  #$0020,-(SP)    ; Super
                trap    #1
                addq.l  #6,SP
                move.l  D0,-(SP)
                move.w  #$0020,-(SP)

                movea.l $00000084.w,A4
find_afx1:      cmpi.l  #'XBRA',-12(A4)
                bne.s   no_afx
                cmpi.l  #'AFX ',-8(A4)
                beq.s   found_afx

                movea.l -4(A4),A4
                move.l  A4,D0
                bne.s   find_afx1

no_afx:         trap    #1              ; Super
                addq.l  #6,SP
                suba.l  A4,A4
                move.l  (SP)+,D0
                rts

found_afx:      subq.l  #8,A4
                subq.l  #8,A4
                move.l  (A4),D0
                adda.w  D0,A4
                cmpi.l  #'PARX',-4(A4)
                bne.s   no_afx
                trap    #1              ; Super
                addq.l  #6,SP

                move.l  (SP)+,D0
                rts


align 4

                END
