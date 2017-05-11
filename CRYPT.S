
;***************************************
;* Codierung (z.Z. nur ein Objekt möglich)

;*******************
;* Export: Funktionen

export init_crypt
export create_crypt
export encrypt
export decrypt
export destroy_crypt


;*******************
;* Konstanten:

KEYBUF          EQU 256


                TEXT

;*******************
;* void init_crypt (uchar *): Initialisieren der Verschlüsselung
;* IN  A0.l: uchar *key: Zeiger auf das Schlüsselwort

init_crypt:     movem.l A2-A3,-(SP)

                tst.b   (A0)            ;key leer?
                beq.s   set_end         ;Ja! =>

                move.w  #KEYBUF,D0
                lea     keyword,A2
                bra.s   set_2

set_1:          subq.l  #1,A2           ;Nullbyte überschreiben

set_2:          movea.l A2,A3           ;letzte erfolgreich kopierte Position sichern
                movea.l A0,A1           ;key sichern

set_3:          move.b  (A1)+,(A2)+     ;kopieren
                beq.s   set_1           ;key zu Ende? Ja! =>
                subq.w  #1,D0           ;keyword voll?
                bne.s   set_3           ;Nein! =>

                clr.b   (A3)            ;keyword terminieren

set_end:        movem.l (SP)+,A2-A3
                rts


;*******************
;* crypt_t *init_crypt (ulong): Erzeugen eines crypt-Objektes
;* IN  D0.l: ulong   cryptsize: Max. Anzahl zu cryptender Bytes (-1 = unendlich)
;* OUT A0.l: crypt_t *crypt   : Zeiger auf crypt-Objekt

create_crypt:   lea     object,A0
                move.l  D0,(A0)         ;crypt.cryptsize
                lea     keyword,A1
                move.l  A1,4(A0)        ;crypt.key
                move.l  A1,8(A0)        ;crypt.keyinit
                rts


;*******************
;* void encrypt/decrypt (uchar *, ulong, crypt_t *):
;* IN  D0.l: ulong   len   : Anzahl zu kodierender Bytes
;*     A0.l: uchar   *ptr  : Pufferadresse
;*     A1.l: crypt_t *crypt: Zeiger auf crypt-Objekt

encrypt:
decrypt:

                movem.l A2-A3,-(SP)

                move.l  (A1)+,D1        ;crypt.cryptsize
                bmi.s   code_2          ;Unendlich viele Bytes crypten? Ja! =>

                cmp.l   D1,D0
                ble.s   code_1

                move.l  D1,D0

code_1:         sub.l   D0,-4(A1)       ;crypt.cryptsize

code_2:         subq.l  #1,D0
                bmi.s   code_end        ;was zu kodieren? Nein! =>

                movea.l (A1)+,A3        ;crypt.key
                movea.l (A1),A2         ;crypt.keyinit
                bra.s   code_loop

code_reset:     movea.l A2,A3
                move.b  (A3)+,D1
                eor.b   D1,(A0)+
                subq.l  #1,D0
                bmi.s   code_exit

code_loop:      REPT 7
                move.b  (A3)+,D1
                beq.s   code_reset
                eor.b   D1,(A0)+
                subq.l  #1,D0
                bmi.s   code_exit
              ENDM

                move.b  (A3)+,D1
                beq.s   code_reset
                eor.b   D1,(A0)+
                subq.l  #1,D0
                bpl.s   code_loop

code_exit:      move.l  A3,-(A1)        ;crypt.key

code_end:       movem.l (SP)+,A2-A3
                rts


;*******************
;* void destroy_crypt (crypt_t *):
;* IN  A0.l: crypt_t *crypt: Zeiger auf crypt-Objekt

destroy_crypt:  rts


;*******************
;* BSS:

                BSS

BSS:

align 4
object:
cryptsize:      DS.L 1
key:            DS.L 1
keyinit:        DS.L 1

align 4
keyword:        DS.B KEYBUF

align 4

                END
