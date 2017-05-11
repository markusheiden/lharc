
;***************************************
;* Gemeinsame Routinen zur Codierung:

include "offset.s"

;*******************
;* Export: Funktionen

export shipin_enc                     ;-> Encode
export shipin2_enc                    ;-> Encode
export shipout_enc                    ;-> Encode
export ShipOut                        ;-> Encode, lharc.c


;*******************
;* Import: Funktionen

import fread
import _filbuf
import ReadErrorEnc
import WriteErrorEnc
import block_crc
import encrypt


                TEXT

;*******************
;* ulong shipin_enc (uchar *p, ulong n, ArcFile *)
;* IN  D0.l: ulong n
;*     A0.l: uchar *p
;*     A1.l: ArcFile *comp_file
;* OUT D0.l: ulong n (Anzahl gelesener Bytes)

shipin_enc:     movem.l D3/A2-A4,-(SP)

                movea.l A0,A3           ;p sichern
                movea.l A1,A4

                move.l  D0,D1           ;n
                moveq   #1,D0
                movea.l AF_file(A4),A1
                jsr     fread           ;!!! fread, nicht GEMDOS direkt!

                move.l  D0,D3           ;n sichern
                beq.s   shipin_eof
                bmi.s   shipin_error

                move.l  AF_crc(A4),D1
                beq.s   shipin_exit

                movea.l A3,A0           ;p
                movea.l D1,A1
                bsr     block_crc       ;block_crc (n, p, crc)

shipin_exit:    move.l  D3,D0           ;n als Rückgabewert
                movem.l (SP)+,D3/A2-A4
                rts

shipin_eof:     movea.l AF_file(A4),A0
                moveq   #12,D0          ;_IOEOF
                bset    D0,12(A0)
                bra.s   shipin_exit

shipin_error:   movea.l AF_file(A4),A0
                moveq   #14,D0          ;_IOERR
                bset    D0,12(A0)
                jmp     ReadErrorEnc


;*******************
;* int shipin2_enc (ArcFile *)
;* IN  A0.l: ArcFile *
;* OUT D0.l: int n (gelesenes Byte)

shipin2_enc:    movem.l D3/A2,-(SP)

                movea.l A0,A2           ;comp_file sichern

                movea.l AF_file(A2),A0  ;file3
                jsr     _filbuf         ;Puffer füllen

                move.w  D0,D3           ;gelesenes Byte sichern

                addq.w  #1,D0           ;EOF?
                beq.s   shipin2_exit    ;Ja! =>

                move.l  AF_crc(A2),D1
                beq.s   shipin2_exit

                movea.l AF_file(A2),A1  ;file3

                move.l  (A1)+,D0        ;n
                addq.l  #1,D0
                movea.l (A1),A0         ;p
                subq.l  #1,A0
                movea.l D1,A1
                bsr     block_crc       ;block_crc (n, p, crc)

shipin2_exit:   move.w  D3,D0           ;gelesenes Byte zurückgeben
                movem.l (SP)+,D3/A2
                rts


;*******************
;* shipout_enc (ArcFile *, uchar):
;* IN  D0.b: uchar compress
;*     A0.l: ArcFile *comp_file

shipout_enc:    movem.l D3-D5/A2-A4,-(SP)

                move.b  D0,D5
                movea.l A0,A3
                movea.l AF_outrec(A3),A4

                moveq   #0,D4           ;Anzahl zu schreibender Bytes auf Null setzen

                movea.l 8(A4),A0        ;Basispointer als Zeiger laden
                move.l  (A4),D0         ;Speicherzeiger-Basispointer=Länge
                sub.l   A0,D0
                beq.s   shipout_exit    ;Was zu schreiben? Nein! =>

                move.b  OR_buffered(A4),D3 ;Was gepuffert?
                beq.s   shipout1        ;Nein! =>

                movea.l OR_buffer_last(A4),A0 ;Pufferende als Zeiger laden
                move.l  (A4),D0         ;Speicherzeiger-Pufferende=Länge
                sub.l   A0,D0

;Skip bei Überlauf (codesize > origsize)
shipout1:       move.l  D0,D4           ;Anzahl zu schreibender Bytes sichern

                tst.b   D5              ;compress?
                bne.s   shipout_crypt   ;Ja! =>

                move.l  AF_size(A3),D1
                sub.l   AF_compsize(A3),D1
                sub.l   D0,D1           ;Noch genügend freie Bytes im File?
                bpl.s   shipout_crypt   ;Ja! =>

                tst.b   D3              ;buffered?
                beq.s   shipout_reset   ;Nein! =>

                move.l  OR_buffer_last(A4),(A4) ;Pointer zurücksetzen auf Pufferende
                move.l  OR_buffer_cnt(A4),4(A4) ;cnt zurücksetzen
                bra.s   shipout_ship    ;und schreiben

shipout_crypt:  move.l  AF_crypt(A3),D1
                beq.s   shipout_nocrypt
                movea.l D1,A1
                bsr     encrypt

shipout_nocrypt:tst.b   D3              ;Was gepuffert?
                beq.s   shipout_ship    ;Nein! =>

                tst.l   4(A4)           ;Noch Platz im Puffer?
                bpl.s   shipout_exit    ;Ja! =>

shipout_ship:   movea.l AF_arc(A3),A0
                move.w  14(A0),D0
                movea.l A4,A0
                bsr.s   ShipOut

shipout_reset:  clr.b   OR_buffered(A4) ;buffered

                move.l  12(A4),4(A4)    ;len: Länge = cnt: Basislänge
                move.l  8(A4),(A4)      ;*ptr: Speicherzeiger = *base: Basispointer

shipout_exit:   add.l   D4,AF_compsize(A3) ;Anzahl geschriebener Bytes

                movem.l (SP)+,D3-D5/A2-A4
                rts


;*******************
;* void ShipOut (OutRec, int):
;* IN  D0.w: int outfile
;*     A0.l: OutRec *outrec

ShipOut:        movem.l A2/A5,-(SP)

                movea.l A0,A5           ;outrec sichern

                move.l  (A5),D1         ;Speicherzeiger-Basispointer=Länge
                sub.l   8(A5),D1        ;Was zu schreiben?
                beq.s   ShipOut_exit    ;Nein! =>

                move.l  8(A5),-(SP)     ;Basispointer
                move.l  D1,-(SP)
                move.w  D0,-(SP)        ;outfile (=handle)
                move.w  #$0040,-(SP)    ; Fwrite !!! _write benutzen?
                trap    #1
                lea     12(SP),SP

                tst.l   D0              ;Fehler?
                bmi.s   ShipOut_error   ;Ja! =>

                move.l  (A5),D1         ;Speicherzeiger-Basispointer=Länge
                sub.l   8(A5),D1

                cmp.l   D1,D0           ;Alles geschrieben?
                blt.s   ShipOut_error   ;Nein! =>

                clr.b   OR_buffered(A5) ;buffered

                move.l  12(A5),4(A5)    ;Länge=Basislänge
                move.l  8(A5),(A5)      ;Speicherzeiger=Basispointer

ShipOut_exit:   movem.l (SP)+,A2/A5
                rts

ShipOut_error:  jmp     WriteErrorEnc


align 4

                END
