;/*-------------------------------------------------------------------------*/
;/* InqMagX()                                                               */
;/*                                                                         */
;/* Liefert                                                                 */
;/*  -1:   Kein Mag!X vorhanden                                             */
;/*  -2:   Mag!X installiert, aber Mag!X-AES inaktiv; d.h. Mag!X wird nur   */
;/*        als schnelles Filesystem benutzt!                                */
;/*  >0:   Mag!X vorhanden und Mag!X-AES aktiv. Der Rückgabewert enthält    */
;/*        die BCD-codierte Versionsnummer (z.B: 0x0200)                    */
;/*-------------------------------------------------------------------------*/

export    InqMagX

import    get_cookie

                TEXT

InqMagX:        move.l  #'MagX',D0
                lea     xadr,A0
                jsr     get_cookie
                tst.w   D0
                beq.s   no_magx
                movea.l xadr,A0
                movea.l 8(A0),A0
                move.l  A0,D0
                beq.s   not_running
                move.w  48(A0),D0
                bra.s   bye
no_magx:        moveq   #-1,D0
                bra.s   bye
not_running:    moveq   #-2,D0
bye:            rts

                BSS

align 4
xadr:           DS.L 1

align 4

                END
