
;***************************************
;* Gemeinsame Routinen zum Dekodieren:

include "offset.s"

;*******************
;* Export: Funktionen

export init_shipin_dec                ;-> Decode
export shipin_dec                     ;-> Decode
export shipin2_dec                    ;-> Decode
export shipout_dec                    ;-> Decode
export OpenOut                        ;-> Decode, lharc.c


;*******************
;* Import: Funktionen

import _filbuf                        ;mintlib:
import ReadErrorDec
import WriteErrorDec
import block_crc
import decrypt
                IF __SHELL__
import copy_to_view
                ENDC


                TEXT

;*******************
;* ulong init_shipin_dec (ArcFile *)
;* IN  A0.l: ArcFile *decomp_file

init_shipin_dec:move.l  AF_crypt(A0),D1 ;File gecrypted?
                beq.s   init_exit       ;Nein! =>

                movea.l AF_arc(A0),A1   ;Puffer leer?
                move.l  (A1)+,D0
                ble.s   init_exit       ;Ja! =>

                movea.l (A1),A0         ;ab Pufferzeiger
                movea.l D1,A1           ;decomp_file.crypt
                bsr     decrypt         ;decrypten

init_exit:      rts


;*******************
;* void shipin_dec (ulong, ArcFile *)
;* IN  D0.l   : ulong min_bytes
;*     A0.l   : ArcFile *decomp_file

shipin_dec:     movem.l D3/A2-A5,-(SP)

                movea.l A0,A3
                movea.l AF_arc(A3),A4   ;decomp_file.arc

                move.l  (A4),D1         ;cnt
                cmp.l   D0,D1           ;genug Bytes da?
                bge.s   shipin_exit     ;Ja! =>

                moveq   #12,D0          ;_IOEOF?
                btst    D0,12(A4)
                bne.s   shipin_exit     ;Ja! =>

                movea.l 4(A4),A1        ;ptr
                movea.l 8(A4),A5        ;base

                subq.l  #1,D1           ;Was zum Kopieren da?
                bmi.s   shipin_2        ;Nein! =>

shipin_copy:    move.b  (A1)+,(A5)+     ;Daten an Pufferanfang kopieren !!! optimieren
                subq.l  #1,D1
                bpl.s   shipin_copy

shipin_2:       move.l  8(A4),4(A4)     ;ptr = base

                move.l  16(A4),D0       ;freien Platz im Puffer berechnen (bsize-cnt)
                sub.l   (A4),D0

                pea     (A5)            ;freier Bereich nach kopierten Daten
                move.l  D0,-(SP)        ;freier Platz
                move.w  14(A4),-(SP)    ;handle
                move.w  #$003F,-(SP)    ;Fread !!! _read benutzen?
                trap    #1
                lea     12(SP),SP

                tst.l   D0
                beq.s   shipin_eof
                bmi.s   shipin_error

                add.l   D0,(A4)         ;cnt erhöhen

                move.l  AF_crypt(A3),D1 ;crypted?
                beq.s   shipin_exit     ;Nein! =>

                movea.l A5,A0           ;neue Daten
                movea.l D1,A1           ;decomp_file.crypt
                bsr     decrypt         ;decrypten

shipin_exit:    movem.l (SP)+,D3/A2-A5
                rts

shipin_eof:     moveq   #12,D0          ;_IOEOF setzen
                bset    D0,12(A4)
                bra.s   shipin_exit

shipin_error:   moveq   #14,D0          ;_IOERR setzen
                bset    D0,12(A4)
                jmp     ReadErrorDec


;*******************
;* int shipin2_dec (ArcFile *):
;* IN  A0.l: ArcFile *decomp_file
;* OUT D0.w: ausgelesenes Byte

shipin2_dec:    movem.l D3-D4/A2-A3,-(SP)

                movea.l A0,A2

                movea.l AF_arc(A2),A0
                bsr     _filbuf         ;Puffer füllen

                move.w  D0,D3           ;gelesenes Byte sichern

                move.l  AF_crypt(A2),D1 ;crypted?
                beq.s   shipin2_exit    ;Nein! =>

                addq.w  #1,D0           ;EOF?
                beq.s   shipin2_exit    ;Ja! =>

                movea.l AF_arc(A2),A3

                move.l  (A3)+,D0        ;cnt
                addq.l  #1,D0

                movea.l (A3),A0         ;ptr
                subq.l  #1,A0
                movea.l D1,A1           ;decomp_file.crypt

                movea.l A0,A3           ;akt. Pufferposition merken    !!! neu
                bsr     decrypt
                move.b  (A3),D3         ;erstes dekodiertes Byte holen !!! neu

shipin2_exit:   move.w  D3,D0           ;gelesenes Byte zurückgeben
                movem.l (SP)+,D3-D4/A2-A3
                rts


;*******************
;* void shipout_dec (ArcFile *):
;* IN  A0.l: ArcFile *decomp_file

shipout_dec:    movem.l A2-A5,-(SP)

                movea.l A0,A3
                movea.l AF_outrec(A3),A4
                movea.l AF_file(A3),A5

                move.l  AF_crc(A3),D1
                beq.s   shipout1

                movea.l 8(A4),A0        ;Basispointer
                move.l  (A4),D0         ;Speicherzeiger
                sub.l   A0,D0           ;Länge berechnen
                beq.s   shipout_end     ;Nichts zu schreiben? Ja! =>
                movea.l D1,A1
                bsr     block_crc

shipout1:       IF __SHELL__
                movea.l 8(A4),A0        ;Basispointer
                move.l  (A4),D0         ;Speicherzeiger
                sub.l   A0,D0           ;Länge berechnen
                beq.s   shipout_end     ;Nichts zu schreiben? Ja! =>
                jsr     copy_to_view
                ENDC

                move.l  (A4),D1         ;Speicherzeiger
                sub.l   8(A4),D1        ;Basispointer
                beq.s   shipout_end     ;Nichts zu schreiben? Ja! =>

                move.l  A5,D0           ;file angegeben?
                beq.s   shipout_reset   ;Nein! =>

                move.l  8(A4),-(SP)     ;Basispointer
                move.l  D1,-(SP)        ;Länge
                move.w  14(A5),-(SP)    ; file3._file (=handle)
                move.w  #$0040,-(SP)    ; Fwrite !!! _write benutzen?
                trap    #1
                lea     12(SP),SP

                tst.l   D0
                bmi.s   shipout_error

                move.l  (A4),D1         ;Speicherzeiger
                sub.l   8(A4),D1        ;Basispointer

                cmp.l   D1,D0
                blt.s   shipout_error

shipout_reset:  move.l  12(A4),4(A4)    ;Länge=Basislänge
                move.l  8(A4),(A4)      ;Speicherzeiger=Basispointer

shipout_end:    movem.l (SP)+,A2-A5
                rts

shipout_error:  moveq   #14,D1          ;_IOERR setzen
                bset    D1,12(A5)
                jmp     WriteErrorDec


;*******************
;* void OpenOut (OutRec *, uchar *):
;* IN  D0.l: ulong  bsize   : Größe des Puffers
;*     A0.l: OutRec *outrec : Adresse des OutRec
;*     A1.l: uchar  *ptr    : Adresse des Puffers

OpenOut:        subq.l  #1,D0

                move.l  A1,(A0)+
                move.l  D0,(A0)+
                move.l  A1,(A0)+
                move.l  D0,(A0)+
                clr.b   (A0)+

                rts

align 4

                END
