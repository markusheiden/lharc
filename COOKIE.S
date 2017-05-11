; Cookie-Routinen, (PD) 1993, Dirk Haun @ WI2

export get_cookie, set_cookie, put_cookie

import Super, Malloc, Supexec

module        get_p_cookies
                move.l  $000005A0.w,D0
                rts
endmod

; int get_cookie(long cookie[D0],long *cval[A0]);

module        get_cookie
                movem.l D4/A2-A3,-(SP)
                move.l  D0,D4
                movea.l A0,A3
                lea     get_p_cookies,A0
                jsr     Supexec
                tst.l   D0
                beq.s   c_ende
                movea.l D0,A0
                moveq   #0,D0
c_loop:         move.l  (A0)+,D1
                beq.s   c_ende
                move.l  (A0)+,D2
                cmp.l   D4,D1
                bne.s   c_loop
c_found:        move.l  D2,(A3)
                moveq   #1,D0
c_ende:         movem.l (SP)+,D4/A2-A3
                rts
endmod


; int set_cookie(long cookie[D0],long newval[D1]);

module        set_cookie

RESMAGIC        EQU $31415926

_p_cookies      EQU $000005A0
_resvalid       EQU $00000426
_resvector      EQU $0000042A


                movem.l D3-D4/A2-A4,-(SP)
                move.l  D0,D4
                movea.l D1,A4
                suba.l  A0,A0
                jsr     Super
                movea.l D0,A3
                moveq   #0,D3
                moveq   #0,D1
                move.l  $000005A0.w,D0
                beq.s   s_alloc
                movea.l D0,A0
s_loop:         addq.l  #1,D1
                move.l  (A0)+,D0
                beq.s   s_null
                cmp.l   D0,D4
                beq.s   s_found
                addq.l  #4,A0
                bra.s   s_loop

s_null:         cmp.l   (A0),D1
                bmi.s   s_insert

s_alloc:        moveq   #8,D0
                add.l   D1,D0
                asl.l   #3,D0
                jsr     Malloc
                move.l  A0,D1
                beq.s   s_ende
                move.l  $000005A0.w,D0
                beq.s   s_newjar
                movea.l D0,A1
s_copy:         move.l  (A1)+,(A0)+
                beq.s   s_nullcp
                move.l  (A1)+,(A0)+
                bra.s   s_copy
s_nullcp:       movea.l (A1)+,A2
                addq.l  #8,A2
                move.l  A2,(A0)
                move.l  D1,$000005A0.w
                bra.s   s_install

s_newjar:       move.l  D1,$000005A0.w
                clr.l   (A0)+

s_install:      bsr.s   _instReset

s_insert:       clr.l   4(A0)
                move.l  (A0),8(A0)
                subq.l  #4,A0
                move.l  D4,(A0)+

s_found:        move.l  A4,(A0)+
s_ok:           moveq   #1,D3
s_ende:         movea.l A3,A0
                jsr     Super
                move.l  D3,D0
                movem.l (SP)+,D3-D4/A2-A4
                rts

_instReset:     move.l  D4,xbraId
                move.l  _resvalid.w,oldResValid
                move.l  #RESMAGIC,_resvalid.w
                move.l  _resvector.w,oldReset
                move.l  #newReset,_resvector.w
                rts

oldResValid:    DC.L 0
                DC.B "XBRA"
xbraId:         DC.B "ck01"     ; XBRA-structure
oldReset:       DC.L 0
newReset:       clr.l   _p_cookies.w    ; clear the cookie jar
                move.l  oldReset,_resvector.w
                move.l  oldResValid,_resvalid.w
                jmp     (A6)
endmod


; int put_cookie(long cookie[D0],long newval[D1]);

module        put_cookie
                movem.l D3-D4/A2-A4,-(SP)
                move.l  D0,D4
                movea.l D1,A4
                suba.l  A0,A0
                jsr     Super
                movea.l D0,A3
                moveq   #0,D3
                move.l  $000005A0.w,D0
                beq.s   p_ende
                movea.l D0,A0
                moveq   #0,D0
p_loop:         move.l  (A0)+,D1
                bne.s   p_other
                move.l  (A0)+,D2
                cmp.l   D0,D2
                bls.s   p_ende
                move.l  D4,-8(A0)
                move.l  A4,-4(A0)
                clr.l   (A0)+
                move.l  D2,(A0)
                bra.s   p_ok
p_other:        addq.l  #1,D0
                move.l  (A0)+,D2
                cmp.l   D4,D1
                bne.s   p_loop
p_found:        move.l  A4,-(A0)
p_ok:           moveq   #1,D3
p_ende:         movea.l A3,A0
                jsr     Super
                move.l  D3,D0
                movem.l (SP)+,D3-D4/A2-A4
                rts
endmod

                END
