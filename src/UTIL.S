
;*******************
;* Export: Funktionen

export FTimeToULong
export ilong
export itime

export mksum

export stpcpy
export strcpy
export strchr
export strcmp
export strncmp
export strlen
export stricmp

export get_fname
export backpath

;*******************
;* Export: Variablen

export blkcnt
export RotInd
;export rot
export star
export upper


;***************************************
;*

;*******************
;* ilong:

ilong:          move.l  (A0),D0
                ror.w   #8,D0
                swap    D0
                ror.w   #8,D0
                move.l  D0,(A0)
                rts


;*******************
;* itime:

itime:          move.l  (A0),D0
                ror.w   #8,D0
                swap    D0
                ror.w   #8,D0
                swap    D0
                move.l  D0,(A0)
                rts


;*******************
;* FTimeToULong:

FTimeToULong:   move.l  (A0),D0
                swap    D0
                rts


;*******************
;* stpcpy:

stpcpy:         move.l  A1,D0
                beq.s   _no_source

_stpcpy:        REPT 23
                move.b  (A1)+,(A0)+
                beq.s   _stp_back
              ENDM

                move.b  (A1)+,(A0)+
                bne.s   _stpcpy

_stp_back:      subq.w  #1,A0
                rts

_no_source:     clr.b   (A0)
                rts


;*******************
;* strcpy:

strcpy:         move.l  A1,D0
                beq.s   _no_source

                move.l  A0,D0

_strcpy:        REPT 23
                move.b  (A1)+,(A0)+
                beq.s   _str_exit
              ENDM

                move.b  (A1)+,(A0)+
                bne.s   _strcpy

_str_exit:      movea.l D0,A0
                rts


;*******************
;* strncmp:

strncmp:        subq.w  #1,D0
                bmi.s   _str_eq

_strn_lp:       move.b  (A0)+,D1
                beq.s   _strcend
                cmp.b   (A1)+,D1
                dbne    D0,_strn_lp

                tst.w   D0
                bmi.s   _str_eq

                cmp.b   -(A1),D1
                bcs.s   _str_lt
                moveq   #1,D0
                rts

_str_eq:        moveq   #0,D0
                rts

_strcend:       tst.b   (A1)
                bne.s   _str_lt

                moveq   #0,D0
                rts

_str_lt:        moveq   #-1,D0
                rts


;*******************
;* strcmp:

strcmp:         REPT 13
                move.b  (A0)+,D0
                beq.s   _strcend
                cmp.b   (A1)+,D0
                bne.s   _str_ne
              ENDM

                move.b  (A0)+,D0
                beq.s   _strcend
                cmp.b   (A1)+,D0
                beq.s   strcmp

_str_ne:        bcs.s   _str_lt
                moveq   #1,D0
                rts


;*******************
;* stricmp:

stricmp:        move.l  A2,D2
                lea     upper,A2
                moveq   #0,D0
                moveq   #0,D1

_stri_lp:       move.b  (A0)+,D0
                beq.s   _stri_cend

                move.b  0(A2,D0.w),D0
                move.b  (A1)+,D1
                cmp.b   0(A2,D1.w),D0
                beq.s   _stri_lp
                bcs.s   _stri_lt

                movea.l D2,A2
                moveq   #1,D0
                rts

_stri_cend:     tst.b   (A1)
                bne.s   _stri_lt

                movea.l D2,A2
                moveq   #0,D0
                rts

_stri_lt:       movea.l D2,A2
                moveq   #-1,D0
                rts


;*******************
;* strlen:

strlen:         movea.l A0,A1

_strlen:        REPT 15
                tst.b   (A0)+
                beq.s   _strlend
              ENDM

                tst.b   (A0)+
                bne.s   _strlen

_strlend:       move.l  A0,D0
                sub.l   A1,D0
                subq.l  #1,D0
                rts


;*******************
;* strchr:

strchr:         move.b  (A0)+,D1
                beq.s   _sch_exit

                cmp.b   D1,D0
                bne.s   strchr

                subq.w  #1,A0
                rts

_sch_exit:      suba.l  A0,A0
                rts


;*******************
;* get_fname:

get_fname:      movea.l A0,A1

                move.b  #'\',D1
                move.b  #'/',D2

_gf_loop:       move.b  (A1)+,D0
                beq.s   _gf_exit

                cmp.b   D1,D0
                beq.s   _gf_set

                cmp.b   D2,D0
                beq.s   _gf_set

                cmp.b   #':',D0
                bne.s   _gf_loop

_gf_set:        movea.l A1,A0
                bra.s   _gf_loop

_gf_exit:       rts


;*******************
;* backpath:

backpath:       bsr.s   get_fname
                clr.b   (A0)
                rts


;*******************
;* mksum: Header-Checksumme berechnen

mksum:          subq.w  #1,D0
                moveq   #0,D1
                addq.w  #2,A0

_sum:           add.b   (A0)+,D1
                dbra    D0,_sum
                move.w  D1,D0
                rts


;*******************
;* BSS:

                BSS

BSS:

align 4
upper:          DS.B 256

align 4

                END
