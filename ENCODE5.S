
;***************************************
;* LHA5-Codierung:

include "offset.s"

;*******************
;* Export: Funktionen

export Encode5                        ;-> lharc.c

export get_next_match                 ;Nur für Profiler...
export insert_node
export delete_node
export get_next
export putbits
export shipout5
export send_block
export make_tree
export make_len
export count_len
export count_t_freq
export write_pt_len
export write_c_len


;*******************
;* Import: Funktionen

import shipin_enc
import shipout_enc
import do_ProcInd

;*******************
;* Import: Variablen

import text                           ;Pufferaddressen...
import level                          ;werden in lharc.c zugewiesen
import position
import parent
import prev
import next

import textbuf                        ;für output5, send_block


;*******************
;* Konstanten:

NC              EQU 510                 ;lhaconst.h
NT              EQU 19                  ;lhaconst.h
NP              EQU 14                  ;lhaconst.h
NPT             EQU 19                  ;lhaconst.h

CBIT            EQU 9

DICSIZ          EQU 8192                ;lhaconst.h
MAXMATCH        EQU 256                 ;lharconst.h

CHAR_BIT        EQU 8                   ;limits.h

TEXTBUF         EQU 32768               ;lhaconst.h

OUTPUT_POOL     EQU (TEXTBUF/2)-2       ;muß <= (TEXTBUF/2)-2 und < 64kB
OUTPUT_CHAR     EQU 1                   ;1-8
OUTPUT_PTR      EQU 8                   ;2-8


                TEXT

;*******************
;* void Encode5 (ArcFile *, ProcInd_t *, uchar):
;* IN  D0.b   : uchar     compress
;*     A0.l   : ArcFile   *comp_file
;*     A1.l   : ProcInd_t *ProcInd

Encode5:        movem.l D3-D7/A2-A6,-(SP)

                lea     BSS,A6

;Übergabeparameter sichern
                movem.l D0/A0-A1,parameter-BSS(A6)

                move.l  text,_text-BSS(A6)
                move.l  position,_position-BSS(A6)
                movea.l comp_file-BSS(A6),A0
                move.l  AF_outrec(A0),outrec-BSS(A6)

;original init_encode5:

                move.l  textbuf,output_pos-BSS(A6) ;Für out_char, out_ptr
                move.w  #OUTPUT_POOL,output_pool-BSS(A6)

                move.w  #2,avail-BSS(A6) ;Erster freier Knoten

                moveq   #0,D0
                moveq   #0,D1
                moveq   #0,D2
                moveq   #0,D3
                moveq   #0,D4
                moveq   #0,D5
                moveq   #0,D6
                moveq   #0,D7
                movea.l D7,A0
                movea.l A0,A1
                movea.l A1,A2
                movea.l A2,A3
                movea.l A3,A4
                movea.l A4,A5

                movea.l position,A6     ;(position)+$4000 bis !!! BSS extern
                lea     $2100*2(A6),A6  ;(position)+$4200 löschen
                REPT 9                  ;$200 Bytes löschen
                movem.l D0-A5,-(A6)
              ENDM
                movem.l D0-D1,-(A6)

                movea.l parent,A6       ;(parent)+$4000 bis !!! BSS extern
                adda.l  #(($2000*2)*2),A6 ;(parent)+$8000 löschen !!! ändern: suba.w #(($2000*2)*2),A6?
                moveq   #39-1,D7        ;$4000 Bytes löschen !!! neu: vorher move.w
qdel_1:         REPT 8
                movem.l D0-D6/A0-A5,-(A6)
              ENDM
                dbra    D7,qdel_1
                REPT 3
                movem.l D0-D6/A0-A5,-(A6)
              ENDM
                move.l  D0,-(A6)

                movea.l next,A6         ;(next)+$8000 bis !!! BSS extern
                adda.l  #$70F0*2,A6     ;(next)+$E1E0 löschen
                moveq   #60-1,D7        ;$61E0 Bytes löschen !!! neu: vorher move.w
qdel_2:         REPT 8
                movem.l D0-D6/A0-A5,-(A6)
              ENDM
                dbra    D7,qdel_2
                movem.l D0-D6/A0-A5,-(A6)
                movem.l D0-D6/A0-A3,-(A6)

                movea.l next,A0         ;Folge: 0,4,6,8,10,12,14,16,...,$3FFC,$3FFE,0 !!! BSS extern
                moveq   #$04,D0         ;-> 0,4,
                move.l  D0,(A0)+
                move.l  #$00060008,D0   ;-> 6,8,
                move.l  #$00040004,D1   ;-> 10,12,...
                move.w  #1023-1,D2
islide6:        REPT 4
                move.l  D0,(A0)+
                add.l   D1,D0
              ENDM
                dbra    D2,islide6
                REPT 2
                move.l  D0,(A0)+
                add.l   D1,D0
              ENDM
                clr.w   D0
                move.l  D0,(A0)+        ;-> $3FFE,0

                move.l  #$01000100,D0   ;childcount = 1, level = 0
                move.l  D0,D1
                move.l  D1,D2
                move.l  D2,D3
                move.l  D3,D4
                move.l  D4,D5
                move.l  D5,D6
                move.l  D6,D7
                movea.l D7,A0
                movea.l A0,A1
                movea.l A1,A2
                movea.l A2,A3
                movea.l A3,A4
                movea.l A4,A5

                movea.l level,A6        ;(level)+$4000 bis !!! BSS extern
                clr.l   (A6)            ;!!! reicht .w?
                lea     $2100*2(A6),A6  ;(level)+$4200 löschen und (level) = 0
                movem.l D0-A5,-(A6)     ;$200 Bytes löschen
                movem.l D0-A5,-(A6)
                movem.l D0-A5,-(A6)
                movem.l D0-A5,-(A6)
                movem.l D0-A5,-(A6)
                movem.l D0-A5,-(A6)
                movem.l D0-A5,-(A6)
                movem.l D0-A5,-(A6)
                movem.l D0-D7,-(A6)
                movem.l D0-D7,-(A6)


;void start_huf(void):
                lea     BSS,A6

start_huf:      moveq   #0,D1           ;v=0
                movea.l textbuf,A0      ;!!! BSS extern
                move.b  D1,(A0)         ;textbuf[0]=v

                lea     c_freq-BSS(A6),A0 ;for (i=NC, p=c_freq; --i>0;)
                move.w  #(NC-1)>>1,D0
shuf_for1:      move.l  D1,(A0)+        ;*p++=v
                subq.w  #1,D0
                bpl.s   shuf_for1

                lea     p_freq-BSS(A6),A0 ;for (i=NP, p=p_freq; --i>0;)
                moveq   #(NP-1)>>1,D0
shuf_for2:      move.l  D1,(A0)+        ;*p++=v
                subq.w  #1,D0
                bpl.s   shuf_for2

                IF __030__              ;putbits init
                movea.l outrec-BSS(A6),A1
                move.l  (A1)+,D0        ;Pufferaddresse holen
                move.l  (A1),D1         ;Puffergröße holen
                addq.l  #1,D1           ;und
                lsl.l   #3,D1           ;auf Bits umrechnen
                lea     bitcount-BSS(A6),A0
                move.l  D1,(A0)+        ;bitcount
                move.l  D0,(A0)+        ;bufadr
                move.l  D1,(A0)         ;bufsiz

                ELSE
                moveq   #16,D2          ;bitcount=2*CHAR_BIT
                moveq   #0,D3           ;subbitbuf=0

                movea.l outrec-BSS(A6),A1
                move.l  (A1)+,D0        ;Pufferaddresse holen
                move.l  (A1),D1         ;Puffergröße holen
                bclr    #0,D0           ;Adresse begradigen, war sie gerade?
                beq.s   shuf1           ;Ja! =>

                addq.l  #1,D1           ;Länge anpassen
                moveq   #8,D2           ;bitcount entsprechend setzen
                movea.l D0,A0           ;subbitbuf entsprechend füllen
                move.w  (A0),D3
                clr.b   D3

shuf1:          lea     bitcount-BSS(A6),A0
                move.w  D2,(A0)+        ;bitcount
                move.w  D3,(A0)+        ;subbitbuf
                move.l  D0,(A0)+        ;bufadr
                move.l  D1,(A0)         ;bufptr
                ENDC


;original encode5:

;$2100 Bytes nach text+$2000 lesen
                movea.l _text-BSS(A6),A0 ;p
                lea     DICSIZ(A0),A0   ;[$2000]
                move.l  #DICSIZ+MAXMATCH,D0 ;n [$2100]
                movea.l comp_file-BSS(A6),A1
                bsr     shipin_enc

                move.w  D0,remainder-BSS(A6) ;!!! beq ende?

                movea.l ProcInd-BSS(A6),A0
                jsr     do_ProcInd

                moveq   #0,D0           ;Highwords löschen
                moveq   #0,D1
                moveq   #0,D2
                moveq   #0,D3
                moveq   #0,D4
                moveq   #0,D5
                moveq   #0,D6
                moveq   #0,D7

                movea.l parent,A2       ;!!! BSS extern
                movea.l prev,A3         ;!!! BSS extern
                movea.l next,A4         ;!!! BSS extern
                movea.l level,A5        ;!!! BSS extern

                move.w  #DICSIZ,D6      ;[$2000] position setzen: text+$2000 s.o.

                bsr     insert_node     ;ersten Knoten einfügen

                subq.w  #1,remainder-BSS(A6)
                bmi     end_huf

encod1:         move.w  D5,last_matchpos-BSS(A6) ;letzten match merken

                move.w  D7,(A6)         ;in temporäre Variable !!! neu: vorher move.w D7,D4
                bsr     get_next_match
                move.w  (A6),D4

                cmp.w   remainder-BSS(A6),D7 ;level auf Rest begrenzen
                bhi.s   encod_min1      ;(D7 = min(level, remainder))

encod2:         movea.l output_pos-BSS(A6),A1

                cmp.w   D7,D4           ;alter level (D7) größer (besser) als jetziger (D4)?
                bcs.s   encod3          ;Nein! =>
                subq.w  #3,D4           ;match >= 3? !!! neu: vorher cmp
                bcc.s   encod4          ;Ja! =>

encod3:         movea.l _text-BSS(A6),A0 ;!!! optimieren
                moveq   #0,D0
                move.b  -1(A0,D6.w),D0  ;vorheriges Zeichen

out_char:       lea     c_freq-BSS(A6),A0

                subq.w  #OUTPUT_CHAR,output_pool-BSS(A6)
                bmi.s   out_char_send

                move.w  D0,(A1)+        ;Zeichen (Länge) schreiben

                add.w   D0,D0           ;Häufigkeit aktualisieren
                addq.w  #1,0(A0,D0.w)

                move.l  A1,output_pos-BSS(A6)

                subq.w  #1,remainder-BSS(A6)
                bpl.s   encod1
                bra     end_huf

out_char_send:  bsr     send_block
                movea.l textbuf,A1      ;!!! neu: war buf !!! BSS extern
                move.w  #OUTPUT_POOL,output_pool-BSS(A6)
                bra.s   out_char

encod_min1:     move.w  remainder-BSS(A6),D7
                bra.s   encod2

out_ptr_send:   bsr     send_block
                movea.l textbuf,A1      ;!!! neu: war buf !!! BSS extern
                move.w  #OUTPUT_POOL,output_pool-BSS(A6)
                bra.s   out_ptr

encod4:         move.w  D6,D1           ;Offset berechnen (match position)
                sub.w   last_matchpos-BSS(A6),D1
                subq.w  #3-1,D1
                and.w   #$1FFF,D1

                move.w  D4,D0           ;Länge (level)
                add.w   #256,D0         ;!!! neu: vorher 256-3

out_ptr:        lea     c_freq-BSS(A6),A0

                subq.w  #OUTPUT_PTR,output_pool-BSS(A6)
                bmi.s   out_ptr_send

                move.w  D0,(A1)+        ;Pointer-Länge schreiben

                add.w   D0,D0           ;Häufigkeit aktualisieren
                addq.w  #1,0(A0,D0.w)

                move.w  D1,(A1)+        ;Position (Offset) schreiben

                IF __030__
                lea     p_freq-BSS(A6),A0

              bfffo   D1{16:16},D1
                moveq   #32+1,D0
                sub.w   D1,D0

                move.b  D0,-4(A1)       ;Länge(+1) der Position (Offset) in Bit merken
                add.w   D0,D0
                addq.w  #1,-1*2(A0,D0.w)

                ELSE
                lea     p_freq-BSS(A6),A0

                move.w  D1,D0           ;Ist Position (Offset) 0?
                beq.s   out_ptr2        ;Ja! =>
                lsr.w   #8,D0           ;Highbyte isolieren, ist es 0?
                beq.s   out_ptr3        ;Nein! =>

                lsl.w   #3,D1           ;obersten 3 unbenutzen Bits rausschieben

                moveq   #(16-3)+1,D0    ;Offset > 255
out_ptr1:       add.w   D1,D1
                dbcs    D0,out_ptr1
                bra.s   out_ptr_end

out_ptr2:       moveq   #0+1,D0         ;Offset = 0
                bra.s   out_ptr_end

out_ptr3:       moveq   #8+1,D0         ;Offset < 256
out_ptr4:       add.b   D1,D1
                dbcs    D0,out_ptr4

out_ptr_end:    move.b  D0,-4(A1)       ;Länge(+1) der Position (Offset) in Bit merken
                add.w   D0,D0
                addq.w  #1,-1*2(A0,D0.w)
                ENDC

                move.l  A1,output_pos-BSS(A6)

                addq.w  #3-1,D4         ;kompletten match überspringen !!! neu: vorher subq.w #1,D4
;                ble.s   encod6          ;!!! nicht nötig, da D4 >= (3-1)

                move.w  D4,(A6)         ;in temporäre Variable
                sub.w   D4,remainder-BSS(A6) ;!!! neu

encod5:         REPT 3
                bsr.s   get_next_match
                subq.w  #1,(A6)         ;D4
                ble.s   encod6
              ENDM

                bsr.s   get_next_match
                subq.w  #1,(A6)         ;D4
                bgt.s   encod5

encod6:         cmp.w   remainder-BSS(A6),D7 ;level auf Rest begrenzen
                bhi.s   encod_min2      ;(D7 = min(level, remainder))

encod7:         subq.w  #1,remainder-BSS(A6) ;!!! neu
                bpl     encod1


;void end_huf(void):
;{
end_huf:        bsr     send_block

                moveq   #CHAR_BIT-1,D0  ;letztes Zeichen mit Nullen auffüllen
                moveq   #0,D1
                bsr     putbits
;}

                IF __030__
                movea.l outrec-BSS(A6),A1 ;Pufferfüllung in outrec aktualisieren
                move.l  bufsiz-BSS(A6),D0
                sub.l   bitcount-BSS(A6),D0
                lsr.l   #3,D0
                add.l   D0,(A1)+
                sub.l   D0,(A1)

                ELSE
                lea     bitcount-BSS(A6),A0
                cmpi.w  #8,(A0)+        ;CHAR_BIT
                bhi.s   end_huf1

                move.w  (A0)+,D0        ;subbitbuf
                lsr.w   #8,D0
                movea.l (A0),A1         ;bufadr
                move.b  D0,(A1)+
                move.l  A1,(A0)+        ;bufadr
                subq.l  #1,(A0)         ;bufptr

end_huf1:       movea.l outrec-BSS(A6),A1 ;Pufferfüllung in outrec aktualisieren
                move.l  (A1)+,D0
                move.l  (A1)+,D1
                move.l  bufptr-BSS(A6),D2
                sub.l   D2,D1
                add.l   D1,D0
                move.l  D2,-(A1)
                move.l  D0,-(A1)
                ENDC

                bsr     shipout5

                movem.l (SP)+,D3-D7/A2-A6
                rts

encod_min2:     move.w  remainder-BSS(A6),D7
                bra.s   encod7


;*******************
;* get_next_match:
;* IN  D5.w: position?
;*     D6.w: position
;*     D7.w: level
;*     A2.l: parent
;*     A3.l: prev
;*     A4.l: next
;*     A5.l: level (childcount.b, level.b)
;*     A6.l: BSS

align 4

;ausgelagert
_get_next:      bra     get_next

align 4

;Einsprung
get_next_match: addq.w  #1,D6           ;position erhöhen

gnext1:         move.w  D6,D1           ;Positionsknoten (D1) berechnen !!! neu: vorher cmpi.w  #$3FFF,D6 ;2*DICSIZ-1
                add.w   D1,D1           ;(aktuelle Position)            !!!             beq.s   get_next
                bmi.s   _get_next       ;                               !!!             ...

                move.w  0(A2,D1.l),D3   ;parent (D3) des Positionsknoten (D1) holen (Zeichen)
                beq.s   insert_node     ;vorhanden? Nein! =>

;Positionsknoten (D1, aktuelle Position) komplett aushängen
                move.w  0(A3,D1.l),D2   ;vorherigen Knoten des Positionsknoten (D1) als D2 merken
                move.w  0(A4,D1.l),D4   ;nächsten Knoten des Positionsknoten (D1) als D4 merken
                clr.w   0(A2,D1.l)      ;parent des Postionsknoten (D1) löschen
                move.w  D4,0(A4,D2.l)   ;nächster Knoten von D2 ist D4
                move.w  D2,0(A3,D4.l)   ;vorheriger Knoten von D4 ist D2


                cmp.w   #$4000,D3       ;ist parent (D3) des Positionsknoten (D1) wieder ein Positionsknoten?
                bcc.s   insert_node     ;Ja! =>

                subq.b  #1,1(A5,D3.l)   ;childcount des parents (D3) dekrementieren
                cmpi.b  #1,1(A5,D3.l)   ;hat parent (D3) mehr als ein child?
                bls     delete_node     ;Nein! => parent (D3) löschen


;*******************
;* insert_node: (wird von get_next_match direkt angesprungen!)
;* IN  D5.w: position?
;*     D6.w: position
;*     D7.w: level
;*     A2.l: parent
;*     A3.l: prev
;*     A4.l: next
;*     A5.l: level (childcount.b, level.b)
;*     A6.l: BSS

insert_node:    subq.w  #4,D7           ;vorgegebener level < 4?
                bmi.s   inode7          ;Ja! =>

                addq.w  #4-1,D7         ;level = level - 1

                movea.l _position-BSS(A6),A1 ;!!! BSS extern !!! optimieren

                moveq   #1,D4           ;Positionsknoten berechen
                add.w   D5,D4           ;(alte Position + 1)
                or.w    #$4000>>1,D4
                add.w   D4,D4

;ab Positionsknoten (D4) nach Knoten mit parent (Zeichen) suchen
                move.w  0(A2,D4.l),D3   ;parent vorhanden?
                bne.s   inode2          ;Ja! =>
inode1:         move.w  0(A4,D4.l),D4   ;nächsten Knoten holen
                move.w  0(A2,D4.l),D3   ;parent vorhanden?
                beq.s   inode1          ;Nein! =>

;level suchen
inode2:         cmp.b   0(A5,D3.l),D7   ;level größer als vorgegebener?
                bhi.s   inode4          ;Ja! =>
inode3:         move.w  D3,D4           ;parent als aktuellen Knoten sichern
                move.w  0(A2,D3.l),D3   ;neuen parent holen
                cmp.b   0(A5,D3.l),D7   ;dessen level größer als vorgegebener?
                bls.s   inode3          ;Nein! =>


;unmarkierte Position suchen und Weg dahin aktualisieren
inode4:         move.w  D3,D0           ;parent sichern
                move.w  0(A1,D0.l),D1   ;position des parents
                bpl.s   inode6          ;markiert? Nein! =>
inode5:         move.w  D6,0(A1,D0.l)   ;position des parents auf aktuelle position setzen
                move.w  0(A2,D0.l),D0   ;parent des parent holen
                move.w  0(A1,D0.l),D1   ;dessen position holen
                bmi.s   inode5          ;markiert? Ja! =>


inode6:         cmp.w   #$4000,D0       ;Positionsknoten?
                bhs.s   inode9          ;Nein! =>

                move.w  #$8000,D2       ;Markierten Positionsknoten berechnen
                or.w    D6,D2           ;(aktuelle Position)
                move.w  D2,0(A1,D0.l)   ;und setzen
                bra.s   inode9


;level < 4: Neuen Inhaltsknoten einhängen
inode7:         movea.w D6,A0           ;!!! neu
                adda.l  _text-BSS(A6),A0 ;!!! BSS extern !!! optimieren

                move.w  #$4000>>1,D3    ;Inhaltsknoten 1 (Zeichen) berechnen !!! neu: vorher moveq #0,D3; add.w #$2000,D3
                move.b  (A0)+,D3        ;Zeichen holen (text) !!! neu: s.o.
                add.w   D3,D3

                move.w  D3,(A2)         ;aktuellen parent setzen (Abbruchbedingung)

                move.w  #$8000>>5,D4    ;Inhaltsknoten 2 (2 Zeichen) berechnen !!! neu: vorher moveq #0,D4; add.w #$8000,D4
                move.b  (A0),D4         ;nächstes Zeichen holen (text) !!! neu: s.o.
                lsl.w   #4+1,D4         ;*32
                add.w   D3,D4           ;Inhaltsknoten 1 dazu

                move.w  D4,D7           ;Berechneten Inhaltsknoten 2 sichern

;Knoten mit Inhaltsknoten 1 (D3) als parent ab Inhaltsknoten 2 (D4) suchen
nchild1:        move.w  0(A4,D4.l),D4   ;nächsten Knoten holen
                cmp.w   0(A2,D4.l),D3   ;dessen parent holen
                bne.s   nchild1         ;vorhanden? Ja! =>

                tst.w   D4              ;was gefunden?
                bne.s   inode8          ;Ja! =>

;Positionsknoten (später D4, parent D3: $4000+ Zeichen) nach Inhaltsknoten 2 (D7: $C000+ 2 Zeichen) einhängen
                move.w  0(A4,D7.l),D0   ;Folgeknoten (D0) des Inhaltsknoten 2 holen

                move.w  D6,D4           ;Positionsknoten (D4) berechnen
                add.w   D4,D4           ;(aktuelle Position)

                move.w  D4,0(A4,D7.l)   ;nächster Knoten des Inhaltsknoten 2 (D7) ist Positionsknoten (D4)
                move.w  D0,0(A4,D4.l)   ;nächster Knoten des Positionsknoten (D4) ist Folgeknoten (D0)
                move.w  D4,0(A3,D0.l)   ;vorheriger Knoten des Folgeknoten (D0) ist Positionsknoten (D4)
                move.w  D7,0(A3,D4.l)   ;vorheriger Knoten des Positionsknotens (D4) ist Inhaltsknoten 2 (D7)
                move.w  D3,0(A2,D4.l)   ;parent des Positionsknoten (D4) auf Inhaltsknoten 1 (D3) setzen
                addq.b  #1,1(A5,D3.l)   ;childcount des parents (Inhaltsknoten 1 (D3)) erhöhen

                moveq   #1,D7           ;aktuellen level auf 1 setzen
                rts

align 4

inode8:         movea.l _position-BSS(A6),A1 ;!!! BSS extern

                moveq   #2-1,D7         ;level = 2         !!! neu: s.u.


inode16:        addq.w  #1,D7           ;level = level + 1 !!! neu: vorher unten

inode9:         cmp.w   #$2000<<1,D4    ;Positionsknoten in aktueller page?
                blo.s   inode10         ;Ja! =>

                move.w  #$0100,D2       ;level auf Maximum (256) setzen
;                lsr.w   #1,D4
;                move.w  D4,D5           ;position extrahieren
;                add.w   D4,D4
                move.w  D4,D5           ;position extrahieren !!! neu: vorher s.o.
                lsr.w   #1,D5           ;                     !!! rückgängig machen?
                bra.s   inode11

inode10:        moveq   #0,D2
                move.b  0(A5,D4.l),D2   ;level des aktuellen Knotens holen
                move.w  #$7FFF,D5       ;!!! neu: vorher vertauscht
                and.w   0(A1,D4.l),D5   ;position des aktuellen Knotens holen und demarkieren

inode11:        cmp.w   D5,D6           ;page-Grenze übersprungen?
                bhi.s   inode12         ;Nein! =>
                sub.w   #$2000,D5       ;position (D5) anpassen

;nach Folgen gleicher Zeichen suchen
inode12:        movea.l _text-BSS(A6),A0 ;!!! BSS extern

                movea.l D5,A1           ;alte position +
                adda.l  D7,A1           ;level +
                adda.l  A0,A1           ;text

                adda.l  D6,A0           ;neue position + text +
                adda.l  D7,A0           ;level

                move.w  D2,D0           ;level
                sub.w   D7,D0           ;level
                ble.s   inode14

                subq.w  #1,D0
inode13:        cmpm.b  (A0)+,(A1)+     ;!!! neu
                dbne    D0,inode13
                bne.s   in_split

;                not.w   D0              ;(neg D0) - 1
;                add.w   D2,D0
;                move.w  D0,D7
                move.w  D2,D7           ;!!! neu: vorher s.o.

inode14:        cmp.w   #$0100,D7       ;level größer als max. level (255)? !!! MAX_MATCH
                bge.s   inode17         ;Ja! =>

                movea.l _position-BSS(A6),A1 ;!!! BSS extern

                move.w  D4,D3           ;parent sichern

                move.w  D6,0(A1,D4.l)   ;position setzen


                move.w  #$8000>>5,D4    ;Inhaltsknoten berechnen !!! neu: vorher moveq #0,D4; add.w #$8000,D4
                move.b  (A0),D4         ;Zeichen holen (text)
                lsl.w   #4+1,D4         ;*32
                add.w   D3,D4           ;parent dazu addieren

                move.w  D3,(A2)         ;aktuellen parent setzen (Abbruchbedingung)

                move.w  D4,D1


;Knoten mit parent D3 ab D4 suchen
nchild2:        move.w  0(A4,D4.l),D4   ;nächsten Knoten holen
                cmp.w   0(A2,D4.l),D3   ;hat er richtigen parent?
                bne.s   nchild2         ;Nein! =>

                tst.w   D4              ;was gefunden?
                bne.s   inode16         ;Ja! =>

;neuen Positionsknoten (später D4, parent D3) zwischen Inhaltsknoten (D1: $8000+ Zeichen) und dessen Folgeknoten (später D0) einfügen
                move.w  0(A4,D1.l),D0   ;Folgeknoten des Inhaltsknoten holen

                move.w  D6,D4           ;Positionsknoten (D4) berechnen
                add.w   D4,D4           ;(aktuelle Position)

                move.w  D4,0(A4,D1.l)   ;nächster Knoten des Inhaltsknoten (D1) ist Positionsknoten (D4)
                move.w  D0,0(A4,D4.l)   ;nächster Knoten des Positionsknoten (D4) ist Folgeknoten (D0)
                move.w  D4,0(A3,D0.l)   ;vorheriger Knoten des Folgeknotens (D0) ist Positionsknoten (D4)
                move.w  D1,0(A3,D4.l)   ;vorheriger Knoten des Positionsknoten (D4) ist Inhaltsknoten (D1)
                move.w  D3,0(A2,D4.l)   ;parent des Positionsknoten (D4) auf parent (D3) setzen
                addq.b  #1,1(A5,D3.l)   ;childcount des parents (D3) erhöhen
                rts

;align 4

;Ursprungsknoten (D4) durch neuen Positionsknoten (später D2, parent D3) ersetzen
inode17:        move.w  0(A3,D4.l),D1   ;vorherigen Knoten des Ursprungsknoten (D4) holen

                move.w  D6,D2           ;Positionsknoten (D2) berechnen !!! auslagern?
                add.w   D2,D2           ;(aktuelle Position)

                move.w  D1,0(A3,D2.l)   ;und als vorherigen Knoten des Positionsknoten (D2) setzen
                move.w  D2,0(A4,D1.l)   ;nächster Knoten des vorherigen Knotens von D4 ist D2
                move.w  0(A4,D4.l),D1   ;nächsten Knoten von D4 holen
                move.w  D1,0(A4,D2.l)   ;und als nächsten Knoten von D2 setzen
                move.w  D2,0(A3,D1.l)   ;vorheriger Knoten des nächsten Knotens von D4 ist D2
                move.w  D3,0(A2,D2.l)   ;parent von D2 setzen
                clr.w   0(A2,D4.l)      ;parent von D4 löschen
                move.w  D2,0(A4,D4.l)   ;nächster Knoten von D4 ist D2
                rts

;align 4

;Neuen parent (später D3) mit Kindern (D4,?) generieren?
in_split:       movea.l _position-BSS(A6),A1 ;!!! BSS extern optimieren

                not.w   D0              ;(neg D0) - 1
                add.w   D2,D0
                move.w  D0,D7

;freien Knoten als parent (D3) holen und dessen childcount auf 2 setzen
                move.w  avail-BSS(A6),D3 ;freien Knoten holen
                move.w  0(A4,D3.l),avail-BSS(A6) ;nächsten Knoten als 1. freien Knoten setzen

                moveq   #2,D0           ;!!! neu
                move.b  D0,1(A5,D3.l)   ;childcount des neuen parent setzen


;Knoten D4 durch neuen parent (D3) ersetzen
                move.w  0(A3,D4.l),D0   ;vorheriger Knoten von D4 holen
                move.w  D0,0(A3,D3.l)   ;und als vorherigen Knoten von D3 setzen
                move.w  D3,0(A4,D0.l)   ;nächster Knoten des vorherigen Knotens von D4 ist D3
                move.w  0(A4,D4.l),D0   ;nächsten Knoten von D4 holen
                move.w  D0,0(A4,D3.l)   ;und als nächsten Konten von D3 setzen
                move.w  D3,0(A3,D0.l)   ;vorheriger Knoten des nächsten Knotes von D4 ist D3
                move.w  0(A2,D4.l),0(A2,D3.l) ;parent von D4 als parent von D3 setzen
                move.w  D6,0(A1,D3.l)   ;position des parents (D3) auf aktuelle position setzen
                move.b  D7,0(A5,D3.l)   ;level des parents (D3) auf aktuellen level (D7) setzen


;neuen Knoten (D4, parent D3) zwischen Ursprungsknoten (später D2, $8000+ Zeichen + D3) und dessen Folgeknoten (später D1) einfügen
                move.w  D5,D0           ;alte position
                add.w   D7,D0           ;level dazuaddieren

                movea.l _text-BSS(A6),A0 ;!!! BSS extern

                move.w  #$8000>>5,D2    ;Inhaltsknoten berechnen !!! neu: vorher moveq #0,D2; add.w #$8000,D2
                move.b  0(A0,D0.l),D2   ;Zeichen holen (text)
                lsl.w   #4+1,D2         ;*32
                add.w   D3,D2           ;parent dazu addieren

                move.w  0(A4,D2.l),D1   ;Folgeknoten des Ursprungsknotens holen

                move.w  D4,0(A4,D2.l)   ;nächster Knoten von D2 ist D4
                move.w  D1,0(A4,D4.l)   ;nächster Knoten von D4 ist D1
                move.w  D4,0(A3,D1.l)   ;vorheriger Knoten von D1 ist D4
                move.w  D2,0(A3,D4.l)   ;vorheriger Knoten von D4 ist D2
                move.w  D3,0(A2,D4.l)   ;parent setzen


;neuen Positionsknoten (später D1, parent D3) zwischen Inhaltsknoten (später D4, $8000+ Zeichen + D3) und dessen Folgeknoten (später D0) einfügen
                move.w  D6,D1           ;neue position
                add.w   D7,D1           ;level dazuaddieren

                move.w  #$8000>>5,D4    ;Inhaltsknoten berechen !!! neu: vorher moveq #0,D4; add.w #$8000,D4
                move.b  0(A0,D1.l),D4   ;Zeichen holen (text)   !!! neu: vorher .w
                lsl.w   #4+1,D4         ;*32
                add.w   D3,D4           ;parent dazu addieren

                move.w  0(A4,D4.l),D0   ;Folgeknoten des Inhaltsknotens holen

                move.w  D6,D1           ;Positionsknoten (D1) berechnen
                add.w   D1,D1           ;(aktuelle Position)

                move.w  D1,0(A4,D4.l)   ;nächster Knoten des Inhaltsknoten (D4) ist Positionsknoten (D1)
                move.w  D0,0(A4,D1.l)   ;nächster Knoten des Positionsknoten (D1) ist Folgeknoten (D0)
                move.w  D1,0(A3,D0.l)   ;vorheriger Knoten des Folgeknotens (D0) ist Positionsknoten (D1)
                move.w  D4,0(A3,D1.l)   ;vorheriger Knoten des Positionsknoten (D1) ist Inhaltsknoten (D4)
                move.w  D3,0(A2,D1.l)   ;parent des neuen Positionsknoten (D1) auf D3 setzen
                rts


;*******************
;* delete_node: (wird von get_next_match direkt angesprungen!)
;* IN  D3.w: zu löschender Knoten (parent)
;*     D5.w: position?
;*     D6.w: position
;*     D7.w: level ( 0(level) )
;*     A2.l: parent
;*     A3.l: prev
;*     A4.l: next
;*     A5.l: level (childcount.b, level.b)
;*     A6.l: BSS

delete_node:    movea.l _position-BSS(A6),A1 ;!!! BSS extern !!! optimieren

                move.w  #$7FFF,D2
                and.w   0(A1,D3.l),D2   ;position !!! neu vorher D1 (s.u.)

                move.w  D3,D1           ;!!! neu: vorher weiter oben

                cmp.w   D6,D2
                blt.s   dnode1
                sub.w   #$2000,D2       ;!!! optimieren?

dnode1:         movea.w D2,A0           ;Anfangsposition merken !!! optimieren?
                move.w  D2,D4           ;aktuelle Position merken

                move.w  0(A2,D1.l),D0   ;position des parent
                move.w  0(A1,D0.l),D2   ;holen
                bclr    #15,D2          ;markiert?
                beq.s   dnode5          ;Nein! =>

dnode2:         cmp.w   D6,D2
                blt.s   dnode3
                sub.w   #$2000,D2       ;!!! optimieren?

dnode3:         cmp.w   D2,D4           ;D4 = max(D2,D4)
                bgt.s   dnode4          ;!!! neu: vorher bge
                move.w  D2,D4

dnode4:         move.w  D4,D1
                or.w    #$2000,D1       ;!!! optimieren?
                move.w  D1,0(A1,D0.l)   ;position des parents setzen

                move.w  0(A2,D0.l),D0   ;parent des parent holen
                move.w  0(A1,D0.l),D2   ;des position holen
                bclr    #15,D2          ;markiert?
                bne.s   dnode2          ;Ja! => weiter


dnode5:         cmp.w   #$4000,D0       ;ist es ein Positionsknoten?
                bhs.s   dnode8          ;Nein! =>

                cmp.w   D6,D2
                blt.s   dnode6
                sub.w   #$2000,D2       ;!!! optimieren?

dnode6:         cmp.w   D2,D4
                bgt.s   dnode7          ;!!! neu: vorher bge
                move.w  D2,D4

dnode7:         or.w    #$A000,D4       ;!!! ???
                move.w  D4,0(A1,D0.l)   ;position des parent setzen


dnode8:         moveq   #0,D0
                move.b  0(A5,D3.l),D0   ;level des zu löschenden Knotens holen
                add.w   A0,D0           ;Anfangsposition dazu addieren

                movea.l _text-BSS(A6),A1 ;!!! BSS extern !!! optimieren

                move.w  #$8000>>5,D4    ;Inhaltsknoten berechnen !!! neu: vorher moveq #0,D4; add.w #$8000,D4
                move.b  0(A1,D0.l),D4   ;Zeichen holen (text)
                lsl.w   #4+1,D4         ;*32
                add.w   D3,D4           ;zu löschenden Knoten dazu addieren

                move.w  D3,(A2)         ;aktuellen parent setzen (Abbruchbedingung) !!! optimieren (nach oben)?

;child mit zu löschendem parent (D3) ab Inhaltsknoten (D4, $8000+ Zeichen + D3) suchen
dchild1:        move.w  0(A4,D4.l),D4   ;nächsten Knoten holen
                cmp.w   0(A2,D4.l),D3   ;hat er den gewünschten parent
                bne.s   dchild1         ;Nein! =>

;child (D4) aushängen
                move.w  0(A3,D4.l),D0   ;vorherigen Knoten des child (D4) als D0 merken
                move.w  0(A4,D4.l),D2   ;nächsten Knoten des child (D4) als D2 merken
                move.w  D2,0(A4,D0.l)   ;nächster Knoten von D0 ist D2
                move.w  D0,0(A3,D2.l)   ;vorheriger Knoten von D2 ist D0

;zu löschenden parent (D3) durch child (D4) ersetzen und löschen
                move.w  0(A3,D3.l),D0   ;vorherigen Knoten des parent (D3) als D0 merken
                move.w  D0,0(A3,D4.l)   ;vorherigen Knoten des child (D4) auf D0 setzen
                move.w  D4,0(A4,D0.l)   ;nächster Knoten von D0 ist child (D4)
                move.w  0(A4,D3.l),D0   ;nächsten Knoten des parent (D3) als D0 merken
                move.w  D0,0(A4,D4.l)   ;nächsten Knoten des child (D4) auf D0 setzen
                move.w  D4,0(A3,D0.l)   ;vorheriger Knoten von D0 ist child (D4)
                move.w  0(A2,D3.l),0(A2,D4.l) ;parent des parent(D3) als parent des child (D4) setzen
                clr.w   0(A2,D3.l)      ;parent des parent (D3) löschen

;zu löschenden parent (D3) freigeben
                move.w  avail-BSS(A6),0(A4,D3.l) ;parent (D3) als ersten freien Knoten einfügen
                move.w  D3,avail-BSS(A6) ;parent (D3) als ersten freien Knoten setzen

                bra     insert_node



;*******************
;* get_next_match: get_next (ausgelagert)

align 4

;(text)+$2000 bis (text)+$4100 nach (text) kopieren
get_next:       movem.l D3-D7/A2-A6,-(SP)

                movea.l _text-BSS(A6),A0 ;(text)+$2000 bis
                lea     $2000(A0),A0    ;(text)+$4100 nach (text) kopieren

                moveq   #20-1,D0        ;$2100 Bytes kopieren
nxt_cpy:        REPT 8                  ;!!! evtl. auf 16 ändern
                movem.l (A0)+,D1-D7/A1-A6
                movem.l D1-D7/A1-A6,-$00002000-13*4(A0)
              ENDM
                subq.w  #1,D0
                bpl.s   nxt_cpy
                REPT 2
                movem.l (A0)+,D1-D7/A1-A6
                movem.l D1-D7/A1-A6,-$00002000-13*4(A0)
              ENDM
                movem.l (A0)+,D1-D6
                movem.l D1-D6,-$00002000-6*4(A0)

                movem.l (SP)+,D3-D7/A2-A6

;$2000 Bytes nach text+$2100 lesen
                movea.l _text-BSS(A6),A0 ;p
                lea     DICSIZ+MAXMATCH(A0),A0 ;[$2100]
                move.l  #DICSIZ,D0      ;n [$2000]
                movea.l comp_file-BSS(A6),A1
                bsr     shipin_enc

                add.w   D0,remainder-BSS(A6) ;Rest aktualisieren

                movea.l ProcInd-BSS(A6),A0
                jsr     do_ProcInd

                move.w  #DICSIZ,D6      ;position neu setzen [$2000]

                moveq   #0,D0           ;benutzte Register (Highwords) löschen
                moveq   #0,D1
                moveq   #0,D2
                bra     gnext1


                IF __030__
;*******************
;* MACRO putbits:
;* IN  D0.l: Anzahl Bits (n)
;*     D1.w: zu schreibende Bits
;*     A6.l: BSS

MACRO         putbits
LOCAL         putbits1

                lea     bitcount-BSS(A6),A0
                move.l  (A0),D2         ;bitcount
                sub.l   D0,(A0)+        ;bitcount
                bhi.s   putbits1

                bsr     putbits_ship

putbits1:       movea.l (A0)+,A1        ;bufadr
                neg.l   D2
                add.l   (A0),D2         ;bufsiz
              bfins   D1,(A1){D2:D0}
                moveq   #0,D2           ;!!! nötig ?

ENDM


;*******************
;* putbits:
;* IN  D0.l: Anzahl Bits (n)
;*     D1.w: zu schreibende Bits
;*     A6.l: BSS

putbits:        lea     bitcount-BSS(A6),A0
                move.l  (A0),D2         ;bitcount
                sub.l   D0,(A0)+        ;bitcount
                bls.s   putbits2

putbits1:       movea.l (A0)+,A1        ;bufadr
                neg.l   D2
                add.l   (A0),D2         ;bufsiz
              bfins   D1,(A1){D2:D0}
                moveq   #0,D2           ;!!! nötig ?

                rts

putbits2:       bsr.s   putbits_ship
                bra.s   putbits1


putbits_ship:   sub.l   D2,D0           ;fehlende Bits berechnen
                movem.l D0-D1,-(SP)     ;übrigbleibenden Rest merken

                lsr.w   D0,D1           ;Jetzt zu schreibende Bits zurechtschieben
                move.l  D2,D0           ;Anzahl jetzt zu schreibender Bits

                movea.l (A0)+,A1        ;bufadr
                neg.l   D2
                add.l   (A0),D2         ;bufsiz
              bfins   D1,(A1){D2:D0}

                movea.l outrec-BSS(A6),A1 ;outrec aktualisieren
                move.l  (A0),D0         ;bufsiz
                lsr.l   #3,D0
                add.l   D0,(A1)+
                sub.l   D0,(A1)

                bsr.s   shipout5

                lea     bitcount-BSS(A6),A0 ;Puffer aktualisieren
                movea.l outrec-BSS(A6),A1
                move.l  (A1)+,D0        ;Pufferaddresse holen
                move.l  (A1),D1         ;Puffergröße holen
                addq.l  #1,D1           ;und
                lsl.l   #3,D1           ;auf Bits umrechnen
                move.l  D1,(A0)+        ;bitcount
                move.l  D0,(A0)+        ;bufadr
                move.l  D1,(A0)         ;bufsiz

                movem.l (SP)+,D0-D1

                lea     bitcount-BSS(A6),A0
                move.l  (A0),D2         ;bitcount
                sub.l   D0,(A0)+        ;bitcount
;                bcs.s   error           ;!!! nötig ???

                rts

                ELSE
;*******************
;* MACRO putbits:
;* IN  D0.w: Anzahl Bits (n)
;*     D1.w: zu schreibende Bits
;*     A6.l: BSS

MACRO         putbits
LOCAL         putbits1
LOCAL         putbits2
LOCAL         putbits_end

                lea     bitcount-BSS(A6),A1
                sub.w   (A1)+,D0        ;bitcount
                blt.s   putbits2        ;Noch genug Platz in subbitbuf? Ja! =>

                move.w  D1,D2           ;zu schreibende Bits retten
                lsr.w   D0,D1           ;jetzt zu schreibende Bits zurechtschieben
                or.w    (A1)+,D1        ;und einfügen (subbitbuf)

                movea.l (A1),A0         ;bufadr
                move.w  D1,(A0)+        ;Wert schreiben
                move.l  A0,(A1)+        ;bufadr

                subq.l  #2,(A1)         ;bufptr
                bpl.s   putbits1

                bsr     putbits_ship

putbits1:       moveq   #16,D1          ;übrigbleibende Bits berechnen
                sub.w   D0,D1
                lsl.w   D1,D2           ;und zurechtschieben

                movem.w D1-D2,bitcount-BSS(A6) ;bitcount/subbitbuf
                bra.s   putbits_end

putbits2:       neg.w   D0
                lsl.w   D0,D1
                or.w    D1,(A1)         ;subbitbuf
                move.w  D0,-(A1)        ;bitcount


putbits_end:
ENDM


;*******************
;* putbits:
;* IN  D0.w: Anzahl Bits (n)
;*     D1.w: zu schreibende Bits
;*     A6.l: BSS

putbits:        lea     bitcount-BSS(A6),A1
                sub.w   (A1)+,D0        ;bitcount
                bge.s   putbits1

                neg.w   D0
                lsl.w   D0,D1
                or.w    D1,(A1)         ;subbitbuf
                move.w  D0,-(A1)        ;bitcount
                rts

putbits1:       move.w  D1,D2           ;zu schreibende Bits retten
                lsr.w   D0,D1           ;jetzt zu schreibende Bits zurechtschieben
                or.w    (A1)+,D1        ;und einfügen (subbitbuf)

                movea.l (A1),A0         ;bufadr
                move.w  D1,(A0)+        ;Wert schreiben
                move.l  A0,(A1)+        ;bufadr

                subq.l  #2,(A1)         ;bufptr
                bmi.s   putbits3

putbits2:       moveq   #16,D1          ;übrigbleibende Bits berechnen
                sub.w   D0,D1
                lsl.w   D1,D2           ;und zurechtschieben

                movem.w D1-D2,bitcount-BSS(A6) ;bitcount/subbitbuf
                rts

putbits3:       bsr.s   putbits_ship
                bra.s   putbits2


putbits_ship:   movem.l D0-D2,-(SP)

                movea.l outrec-BSS(A6),A1 ;outrec aktualisieren
                move.l  (A1)+,D0
                move.l  (A1)+,D1
                move.l  bufptr-BSS(A6),D2
                sub.l   D2,D1
                add.l   D1,D0
                move.l  D2,-(A1)
                move.l  D0,-(A1)

                bsr.s   shipout5

                movea.l outrec-BSS(A6),A1 ;Puffer aktualisieren
                move.l  (A1)+,D0        ;Pufferaddresse holen
                move.l  (A1),D1         ;Puffergröße holen
                lea     bufadr-BSS(A6),A0
                move.l  D0,(A0)+        ;bufadr
                move.l  D1,(A0)         ;bufptr

                movem.l (SP)+,D0-D2
                rts
                ENDC


;*******************
;* void shipout5 (void):

shipout5:       movem.l D0-D2/A0-A1,-(SP)

                movea.l comp_file-BSS(A6),A0
                move.b  compress-BSS(A6),D0
                bsr     shipout_enc

                movem.l (SP)+,D0-D2/A0-A1
                rts


;*******************
;* void send_block (void):
;* IN  A6.l: BSS
;*
;* REGISTER:
;* A2.l: pt_code (ehemals c_freq)
;* A3.l: textbuf
;* A4.l: c_code
;* A5.l: c_len

send_block:     movem.l D0-D7/A2-A5,-(SP)

                movea.l textbuf,A3      ;!!! BSS extern
                lea     c_code-BSS(A6),A4
                lea     c_len-BSS(A6),A5

                movea.l A4,A2           ;c_code
                movea.l A5,A1           ;c_len
                lea     c_freq-BSS(A6),A0 ;c_freq
                move.w  #NC,D0          ;NC
                bsr     make_tree       ; make_tree(NC,c_freq,c_len,c_code)

                move.w  D0,D3           ; k

                lea     pt_code-BSS(A6),A2

                lea     c_freq-BSS(A6),A0
                add.w   D0,D0           ;!!! 030
                move.w  0(A0,D0.w),D4   ; size=c_freq[k]

                move.w  D4,D1
                moveq   #16,D0
                bsr     putbits         ; putbits(16,size)

                cmp.w   #NC,D3          ; k>=nC ?
                bcs.s   k_lt_NC         ;Nein! =>

                bsr     count_t_freq

;                movea.l A2,A2           ;pt_code
                lea     pt_len-BSS(A6),A1 ;pt_len
                lea     t_freq-BSS(A6),A0 ;t_freq
                moveq   #NT,D0          ;NT
                bsr     make_tree       ; make_tree(NT,t_freq,pt_len,pt_code)

                move.w  D0,D3           ; k

                cmp.w   #NT,D3          ; k>=NT ?
                bcs.s   k_lt_NT         ;Nein! =>

                moveq   #3,D2           ;i_special
                moveq   #5,D1           ;nbit
                moveq   #NT,D0          ;n
                bsr     write_pt_len    ;void write_pt_len (NT, TBIT, 3)
                bsr     write_c_len     ;void write_c_len (void)
                bra.s   _k_ge_NC

k_lt_NT:        move.w  D3,D1           ;k (k < NT (19))
                moveq   #5+5,D0
                bsr     putbits         ;!!! neu: vorher putbits (5,0); putbits (5,k)

                bsr     write_c_len     ;void write_c_len (void)
                bra.s   _k_ge_NC

k_lt_NC:        moveq   #0,D1
                moveq   #8+8,D0
                bsr     putbits         ;!!! neu: vorher putbits (8,0); putbits (11,0)

                move.w  D3,D1           ;k (k < NC (510))
                moveq   #3+9,D0
                bsr     putbits         ;!!! neu: vorher putbits (11,0); putbits (9,k)

_k_ge_NC:
;                movea.l A2,A2           ;pt_code
                lea     pt_len-BSS(A6),A1 ;pt_len
                lea     p_freq-BSS(A6),A0 ;p_freq
                moveq   #NP,D0          ;NP
                bsr     make_tree       ; make_tree(NP,p_freq,pt_len,pt_code)

                move.w  D0,D3           ; k

                cmp.w   #NP,D3          ; k>=NP ?
                bcs.s   k_lt_NP

                moveq   #-1,D2          ;i_special
                moveq   #4,D1           ;nbit
                moveq   #NP,D0          ;n
                bsr     write_pt_len    ;void write_pt_len (NP, PBIT, -1)
                bra.s   _k_ge_NP

k_lt_NP:        move.w  D3,D1           ;k (k < NP (14))
                moveq   #8,D0
                bsr     putbits         ;!!! neu: vorher putbits (4,0); putbits (4,k)

_k_ge_NP:       subq.w  #1,D4
                bmi     send_exit

i_while:        moveq   #0,D7
                move.b  (A3)+,D7        ;Länge der Position (Offset) holen
                bne.s   i_char_bit      ;Ist es Zeichen? Nein! =>

                move.b  (A3)+,D7        ;k = Zeichen

                moveq   #0,D0
                move.b  0(A5,D7.w),D0   ; c_len[k]
                add.w   D7,D7
                move.w  0(A4,D7.w),D1   ; c_code[k]
              putbits

                dbra    D4,i_while      ; i<size ?
                bra     send_exit

i_char_bit:     subq.w  #1,D7           ;Position (Offset) korrigieren

                move.w  #256,D1
                move.b  (A3)+,D1        ;Pointerlänge holen

                moveq   #0,D0
                move.b  0(A5,D1.w),D0   ; c_len[k]
                add.w   D1,D1
                move.w  0(A4,D1.w),D1   ; c_code[k]
              putbits

                move.w  (A3)+,D3        ;Position (Offset) holen

                move.w  D7,D0
                add.w   D0,D0
                move.w  0(A2,D0.w),D1   ; pt_code[c+1]
                moveq   #0,D0
                move.b  pt_len-BSS(A6,D7.w),D0 ; pt_len[c+1] !!! neu
              putbits

                subq.w  #1,D7           ;Position (Offset) um oberstes Bit reduzieren, Position (Offset) < 2?
                bls.s   i_wend          ;Ja! => Position (Offset) ist durch seine Länge gegeben

                move.w  D3,D1
                bclr    D7,D1           ;oberstes Bit löschen (ist durch Länge gegeben (Bit muß 1 sein))
                move.w  D7,D0
              putbits                 ;Position (Offset) schreiben

i_wend:         dbra    D4,i_while      ; i<size ?

send_exit:      move.w  #(NC>>2)-1,D5   ;!!! OK ???
                moveq   #0,D3
                lea     c_freq-BSS(A6),A2
c_freq_clr:     REPT 2
                move.l  D3,(A2)+
              ENDM
                dbra    D5,c_freq_clr
                move.l  D3,(A2)+

                lea     p_freq-BSS(A6),A2
                REPT (NP>>1)
                move.l  D3,(A2)+
              ENDM

                movem.l (SP)+,D0-D7/A2-A5
                rts


;*******************
;* make_tree
;* IN  D0.w: n
;*     A0.l: freq
;*     A1.l: len
;*     A2.l: code
;*     A6.l: BSS
;* OUT D0.w: ?
;*
;* REGISTER:
;* D3.w: n
;* D4.w: avail
;* A3.l: &heap[1]
;* A4.l: code

make_tree:      movem.l D3-D7/A2-A5,-(SP)

                movem.l D0/A0-A1,mt_parameter-BSS(A6) ;n, freq, len

                lea     heap+1*2-BSS(A6),A3 ; &heap[1]
                clr.w   (A3)            ; heap[1] = 0
                movea.l A2,A4           ; code

                move.w  D0,D3           ; n
                move.w  D3,D4           ; avail

                moveq   #0,D1           ; heapsize = 0


                subq.w  #1,D0           ;n
                bmi.s   _m_no_for_i

                moveq   #0,D2
                moveq   #0,D5           ; i = 0
                movea.l A3,A5           ; &heap[1]

_m_for_i:       move.b  D2,(A1)+        ; len[i] = 0
                tst.w   (A0)+           ; freq[i] ?
                beq.s   _m_next_i

                addq.w  #1,D1           ;heapsize
                move.w  D5,(A5)+        ;heap

_m_next_i:      addq.w  #1,D5
                dbra    D0,_m_for_i     ;n

_m_no_for_i:    move.w  D1,heapsize-BSS(A6)


                subq.w  #2,D1           ;heapsize<2?
                bge.s   hs_ge_2         ;Nein! =>

                move.w  (A3),D0         ;heap[1] als Rückgabewert
                move.w  D0,D1
                add.w   D1,D1
                clr.w   0(A4,D1.w)      ;code[heap[1]]=0

                movem.l (SP)+,D3-D7/A2-A5
                rts


hs_ge_2:        move.w  heapsize-BSS(A6),D5
                moveq   #1,D6
                asr.w   D6,D5           ; i = heapsize>>1
                bra.s   down_h_next

down_h:         move.w  D5,D0


                movem.l D3-D5,-(SP)

                lea     heap-BSS(A6),A0
                movea.l freq-BSS(A6),A1

                move.w  heapsize-BSS(A6),D1
                add.w   D1,D1

                add.w   D0,D0           ;i
                lea     0(A0,D0.w),A2   ;heapptr = &heap[i]

                move.w  (A2),D2         ;k = heap[i]
                move.w  D2,D3
                add.w   D3,D3
                move.w  0(A1,D3.w),D3   ;fk = freq[heap[i]]
                move.w  D0,D4           ;j=i

_d_while1:      add.w   D4,D4           ;j=j*2

                cmp.w   D1,D4
                bgt.s   _d_exit1        ;j>heapsize? Ja! =>
                beq.s   _d_else1        ;j=heapsize? Ja! =>

                lea     0(A0,D4.w),A5   ;&heap[j]
                move.w  (A5)+,D5        ;heap[j]
                add.w   D5,D5
                move.w  0(A1,D5.w),D5   ;freq[heap[j]]
                move.w  (A5),D0         ;heap[j+1]
                add.w   D0,D0
                cmp.w   0(A1,D0.w),D5   ;freq[heap[j+1]]<freq[heap[j]]?
                bls.s   _d_else1        ;Nein! =>

                addq.w  #2,D4           ;j++

_d_else1:       lea     0(A0,D4.w),A5   ;&heap[j]
                move.w  (A5),D5         ;heap[j]
                move.w  D5,(A2)         ;*heapptr = heap[j]
                add.w   D5,D5
                cmp.w   0(A1,D5.w),D3   ;freq[heap[j]]<fk(=freq[heap[i]])?
                bls.s   _d_exit1        ;Nein! =>

                movea.l A5,A2           ;heapptr = &heap[j]
                bra.s   _d_while1

_d_exit1:       move.w  D2,(A2)         ;*heapptr = k

                movem.l (SP)+,D3-D5


                subq.w  #1,D5           ;i--

down_h_next:    cmp.w   D6,D5
                bge.s   down_h


no_down_heap:   move.l  A4,sortptr-BSS(A6) ;sortptr=code

do_heap:        move.w  (A3),D5         ;i = heap[1]
                cmp.w   n-BSS(A6),D5    ;i<n?
                bge.s   i_ge_n          ;Nein! =>

                movea.l sortptr-BSS(A6),A0 ;*sortptr++ = i
                move.w  D5,(A0)+
                move.l  A0,sortptr-BSS(A6)


i_ge_n:         move.w  heapsize-BSS(A6),D0 ;heap[1] = heap[--heapsize]
                add.w   D0,D0
                move.w  -1*2(A3,D0.w),(A3)
                subq.w  #1,heapsize-BSS(A6)


                movem.l D3-D5,-(SP)

                lea     heap-BSS(A6),A0
                movea.l freq-BSS(A6),A1

                move.w  heapsize-BSS(A6),D1
                add.w   D1,D1

                lea     1*2(A0),A2      ;heapptr=&heap[1]

                move.w  (A2),D2         ;k = heap[1]
                move.w  D2,D3
                add.w   D3,D3
                move.w  0(A1,D3.w),D3   ;fk = freq[heap[1]]
                moveq   #2*2,D4         ;j=2

_d_while2:      cmp.w   D1,D4
                bgt.s   _d_exit2        ;j>heapsize? Ja! =>
                beq.s   _d_else2        ;j=heapsize? Ja! =>

                lea     0(A0,D4.w),A5   ;&heap[j]
                move.w  (A5)+,D5        ;heap[j]
                add.w   D5,D5
                move.w  0(A1,D5.w),D5   ;freq[heap[j]]
                move.w  (A5),D0         ;heap[j+1]
                add.w   D0,D0
                cmp.w   0(A1,D0.w),D5   ;freq[heap[j+1]]<freq[heap[j]]?
                bls.s   _d_else2        ;Nein! =>

                addq.w  #2,D4           ;j++

_d_else2:       lea     0(A0,D4.w),A5   ;&heap[j]
                move.w  (A5),D5         ;heap[j]
                move.w  D5,(A2)         ;*heapptr = heap[j]
                add.w   D5,D5
                cmp.w   0(A1,D5.w),D3   ;freq[heap[j]]<fk(=freq[heap[1]])?
                bls.s   _d_exit2        ;Nein! =>

                movea.l A5,A2           ;heapptr = &heap[j]
                add.w   D4,D4           ;j=j*2
                bra.s   _d_while2

_d_exit2:       move.w  D2,(A2)         ;*heapptr = k(=heap[1])

                movem.l (SP)+,D3-D5


                move.w  (A3),D6         ;j=heap[1]
                cmp.w   n-BSS(A6),D6    ;j<n?
                bge.s   j_ge_n          ;Nein! =>

                movea.l sortptr-BSS(A6),A0 ;*sortptr++ = j
                move.w  D6,(A0)+
                move.l  A0,sortptr-BSS(A6)

j_ge_n:         move.w  D4,D7           ;k = avail
                addq.w  #1,D4           ;avail++

                movea.l freq-BSS(A6),A0
                move.w  D5,D0           ;i
                add.w   D0,D0
                move.w  0(A0,D0.w),D1   ;freq[i]
                move.w  D6,D2           ;j
                add.w   D2,D2
                add.w   0(A0,D2.w),D1   ;freq[j]
                move.w  D7,D0           ;k(=avail)
                add.w   D0,D0
                move.w  D1,0(A0,D0.w)   ;freq[k] = freq[i] + freq[j]
                move.w  D7,(A3)         ;heap[1] = k(=avail)


                movem.l D3-D5,-(SP)

                lea     heap-BSS(A6),A0
                movea.l freq-BSS(A6),A1

                move.w  heapsize-BSS(A6),D1
                add.w   D1,D1

                lea     1*2(A0),A2      ;heap[1]

                move.w  (A2),D2         ;k = heap[1]
                move.w  D2,D3
                add.w   D3,D3
                move.w  0(A1,D3.w),D3   ;fk = freq[heap[1]]
                moveq   #2*2,D4         ;j=2

_d_while3:      cmp.w   D1,D4
                bgt.s   _d_exit3        ;j>heapsize? Ja! =>
                beq.s   _d_else3        ;j=heapsize? Ja! =>

                lea     0(A0,D4.w),A5   ;&heap[j]
                move.w  (A5)+,D5        ;heap[j]
                add.w   D5,D5
                move.w  0(A1,D5.w),D5   ;freq[heap[j]]
                move.w  (A5),D0         ;heap[j+1]
                add.w   D0,D0
                cmp.w   0(A1,D0.w),D5   ;freq[heap[j+1]]<freq[heap[j]]?
                bls.s   _d_else3        ;Nein! =>

                addq.w  #2,D4           ;j++

_d_else3:       lea     0(A0,D4.w),A5   ;&heap[j]
                move.w  (A5),D5         ;heap[j]
                move.w  D5,(A2)         ;*heapptr = heap[j]
                add.w   D5,D5
                cmp.w   0(A1,D5.w),D3   ;freq[heap[j]]<fk(=freq[heap[i]])?
                bls.s   _d_exit3        ;Nein! =>

                movea.l A5,A2           ;heapptr = &heap[j]
                add.w   D4,D4           ;j=j*2
                bra.s   _d_while3

_d_exit3:       move.w  D2,(A2)         ;*heapptr = k(=heap[1])

                movem.l (SP)+,D3-D5


                move.w  D7,D0           ;k(=avail)
                add.w   D0,D0
                lea     left-BSS(A6),A0
                move.w  D5,0(A0,D0.w)   ;left[k] = i
                lea     right-BSS(A6),A1
                move.w  D6,0(A1,D0.w)   ;right[k] = j

                cmpi.w  #1,heapsize-BSS(A6) ; heapsize>1?
                bgt     do_heap         ;Ja! =>


                move.l  A4,sortptr-BSS(A6) ; sortptr = codeparm

                move.w  D7,D0           ;k(=avail)
                bsr.s   make_len        ;make_len(k)


                lea     start+1*2-BSS(A6),A0 ;&start[1]
                lea     len_cnt+1*2-BSS(A6),A1 ;&len_cnt[1]

                moveq   #0,D1           ;!!! start[0] wird nicht initialisiert
                moveq   #4-1,D0
                move.w  D1,(A0)+        ;start[1] = 0

for_start:      REPT 4
                add.w   (A1)+,D1        ;x=len_cnt[i++]
                add.w   D1,D1           ;x=x*2
                move.w  D1,(A0)+        ;start[j++]=x
              ENDM
                dbra    D0,for_start


                moveq   #0,D1
                movea.l len-BSS(A6),A2  ;&len, i=0
                bra.s   next_i

for_i:          move.b  (A2)+,D1        ;len[i]
                add.b   D1,D1
                move.w  start-BSS(A6,D1.w),(A4)+ ;code[i] = start[len[i]]++
                addq.w  #1,start-BSS(A6,D1.w)
next_i:         dbra    D3,for_i        ;i++, n--

                move.w  D7,D0           ;return (k)

                movem.l (SP)+,D3-D7/A2-A5
                rts


;*******************
;* void make_len(int root)
;* IN  D0.w: root
;*     A6.l: BSS
;*
;* REGISTER:
;* D2.w: cum

make_len:       pea     (A2)

                moveq   #0,D2           ;cum=0

                lea     len_cnt-BSS(A6),A0 ;ushort *lencnt=len_cnt
                move.w  #17-1,D1        ;i=17 !!! optimieren
ml_for1:        move.w  D2,(A0)+        ;*lencnt++=cum
                subq.w  #1,D1           ;--i>0?
                bpl.s   ml_for1

                bsr.s   count_len       ;count_len(root)

                moveq   #0,D2           ;uint cum=0

                lea     len_cnt-BSS(A6),A0 ;lencnt=&len_cnt[17]
                moveq   #17-1,D1        ;i=17
ml_for2:        move.w  (A0)+,D0        ;cum+=(*--lencnt)<<(k++)
                lsl.w   D1,D0
                add.w   D0,D2
                subq.w  #1,D1
                bpl.s   ml_for2

                tst.w   D2              ;while(cum!=(1U<<16))
                beq.s   ml_wend1

ml_while1:      lea     len_cnt+16*2-BSS(A6),A0 ;len_cnt[16]--
                subq.w  #1,(A0)+

                moveq   #17-1,D1        ;i=17
ml_for3:        tst.w   -(A0)           ;if(*--lencnt)
                bne.s   ml_if1
ml_endif1:      subq.w  #1,D1
                bpl.s   ml_for3
                bra.s   ml_endfor3

ml_if1:         subq.w  #1,(A0)+
                addq.w  #2,(A0)

ml_endfor3:     subq.w  #1,D2
                bne.s   ml_while1

ml_wend1:       lea     len_cnt+17*2-BSS(A6),A0
                movea.l len-BSS(A6),A1
                movea.l sortptr-BSS(A6),A2
                moveq   #17-1,D1
ml_for4:        move.w  -(A0),D0

                subq.w  #1,D0
                bmi.s   ml_wend2

ml_while2:      move.w  (A2)+,D2
                move.b  D1,0(A1,D2.w)
                subq.w  #1,D0
                bpl.s   ml_while2

ml_wend2:       subq.w  #1,D1
                bpl.s   ml_for4

                move.l  A2,sortptr-BSS(A6)

                movea.l (SP)+,A2
                rts


;*******************
;* count_len:
;* IN  D0.w: i
;*     A6.l: BSS

count_len:      cmp.w   n-BSS(A6),D0    ;i<n
                bge.s   _i_ge_n         ;Nein! =>

                move.w  depth-BSS(A6),D0
                cmp.w   #16,D0
                bge.s   _ge_16

                add.w   D0,D0
                addq.w  #1,len_cnt-BSS(A6,D0.w) ;!!! neu: vorher len_cnt in A0
                rts

_ge_16:         addq.w  #1,len_cnt+16*2-BSS(A6)
                rts

_i_ge_n:        move.w  D3,-(SP)

                addq.w  #1,depth-BSS(A6)

                move.w  D0,D3           ;i
                add.w   D3,D3

                lea     left-BSS(A6),A0 ;!!! optimieren?
                move.w  0(A0,D3.w),D0
                bsr.s   count_len

                lea     right-BSS(A6),A0 ;!!! optimieren?
                move.w  0(A0,D3.w),D0
                bsr.s   count_len

                subq.w  #1,depth-BSS(A6)

                move.w  (SP)+,D3
                rts


;*******************
;* void count_t_freq(void):
;* IN  A6.l: BSS
;*
;* REGISTER:
;* D0.w: n
;* D1.w: i
;* D2.w: k
;* A0.l: clen
;* A1.l: tfreq

count_t_freq:   movem.l D4-D5,-(SP)

                moveq   #0,D1

                lea     t_freq-BSS(A6),A0
                moveq   #NT-1,D0        ;!!! optimieren
ctf_for1:       move.w  D1,(A0)+
                subq.w  #1,D0
                bpl.s   ctf_for1

                lea     c_len+NC*1-BSS(A6),A0
                move.w  #NC,D0
ctf_while1:     tst.b   -(A0)
                bne.s   ctf_wend1
                subq.w  #1,D0
                bpl.s   ctf_while1

ctf_wend1:      lea     c_len-BSS(A6),A0 ;clen=c_len
                lea     t_freq-BSS(A6),A1 ;tfreq=t_freq

                moveq   #0,D1           ;i=tf0=tf1=0
                move.w  D1,D4
                move.w  D1,D5

ctf_while2:     cmp.w   D0,D1           ;while(i<n)
                bge.s   ctf_wend2

                addq.w  #1,D1           ;i++

                moveq   #0,D2           ;if(k=*clen++)
                move.b  (A0)+,D2
                bne.s   ctf_else1

ctf_if1:        moveq   #1,D2           ;k=1

                cmp.w   D0,D1           ;while(i<n && *clen==0)
                bge.s   ctf_wend3
                tst.b   (A0)
                bne.s   ctf_wend3

ctf_while3:     addq.l  #1,A0           ;clen++
                addq.w  #1,D2           ;k++
                addq.w  #1,D1           ;i++

                cmp.w   D0,D1
                bge.s   ctf_wend3
                tst.b   (A0)
                beq.s   ctf_while3

ctf_wend3:      cmp.w   #2,D2           ;if(k<=2)
                bgt.s   ctf_elseif2a

                add.w   D2,D4
                bra.s   ctf_while2      ;(endif2)

ctf_elseif2a:   sub.w   #18,D2          ;else if (k<=18)
                bgt.s   ctf_elseif2b

                addq.w  #1,D5
                bra.s   ctf_while2      ;(endif2)

ctf_elseif2b:   subq.w  #19-18,D2       ;else if (k==19)
                bne.s   ctf_else2

                addq.w  #1,D4
                addq.w  #1,D5
                bra.s   ctf_while2      ;(endif2)

ctf_else2:      addq.w  #1,2*2(A1)
                bra.s   ctf_while2      ;(endif2)

ctf_else1:      add.w   D2,D2           ;tfreq[k+2]++
                addq.w  #1,2*2(A1,D2.w)
                bra.s   ctf_while2      ;(endif1)

ctf_wend2:      add.w   D4,(A1)+
                add.w   D5,(A1)

                movem.l (SP)+,D4-D5
                rts


;*******************
;* void write_pt_len(int n, int nbit, int i_special):
;* IN  D0.w: n
;*     D1.w: nbit
;*     D2.w: i_special
;*     A6.l: BSS
;*
;* REGISTER:
;* D4.w: n
;* D5.w: nbit
;* D6.w: i_special
;* D7.w: i
;* A2.l: ptlen

write_pt_len:   movem.l D4-D7/A2,-(SP)

                move.w  D0,D4
                move.w  D1,D5
                move.w  D2,D6

                lea     pt_len-BSS(A6,D4.w),A2 ;ptlen=&ptlen[n]

wptl_while1:    move.b  -(A2),D0        ;while(*--ptlen==0 && --n>=0);
                bne.s   wptl_wend1
                subq.w  #1,D4
                bpl.s   wptl_while1

wptl_wend1:     move.w  D5,D0           ;nbit !!! .l
                move.w  D4,D1           ;n
                bsr     putbits         ;putbits(nbit, n)

                moveq   #0,D7           ;i=0
                lea     pt_len-BSS(A6),A2 ;ptlen=pt_len

wptl_while2:    cmp.w   D4,D7           ;while(i<n)
                bge.s   wptl_wend2

                addq.w  #1,D7           ;i++

                moveq   #0,D0           ;if(k=*ptlen++)<=6)
                move.b  (A2)+,D0
                cmp.w   #6,D0
                bgt.s   wptl_else1

wptl_if1:       move.w  D0,D1           ;k
                moveq   #3,D0           ;3
                bsr     putbits         ;putbits(3,k)
                bra.s   wptl_endif1

wptl_else1:     subq.w  #3,D0           ;c=3; k-=c !!! .l
                moveq   #1,D1           ;(1U<<k)-2
                lsl.w   D0,D1
                subq.w  #2,D1
                bsr     putbits         ;putbits(k,(1U<<)-2)

wptl_endif1:    cmp.w   D7,D6           ;if(i==i_special)
                bne.s   wptl_while2     ;(endif2)

wptl_if2:       moveq   #6,D1           ;while(i<6 && *ptlen==0)
                cmp.w   D1,D7           ;i<6
                bge.s   wptl_endif2
                move.b  (A2),D0
                bne.s   wptl_endif2

wptl_while3:    addq.l  #1,A2           ;ptlen++
                addq.w  #1,D7           ;i++

                cmp.w   D1,D7           ;i<6
                bge.s   wptl_endif2
                move.b  (A2),D0
                beq.s   wptl_while3

wptl_endif2:    moveq   #2,D0           ;2
                move.w  D7,D1           ;c=3; (i-c)&c
                subq.w  #3,D1
                and.w   #3,D1
                bsr     putbits         ;putbits (2,(i-c)&c)
                bra.s   wptl_while2

wptl_wend2:     movem.l (SP)+,D4-D7/A2
                rts


;*******************
;* void write_c_len(void):
;* IN  A6.l: BSS
;*
;* REGISTER:
;* D4.w: n
;* D5.w: i
;* D6.w: k
;* A2.l: clen

write_c_len:    movem.l D4-D6/A2,-(SP)

                move.w  #NC,D4          ;n=NC

                lea     c_len-BSS(A6),A2 ;clen=c_len
                lea     NC(A2),A0       ;clen=c_len[n=NC]

wcl_while1:     tst.b   -(A0)           ;while(--clen==0 && --n>=0)
                bne.s   wcl_wend1
                subq.w  #1,D4
                bpl.s   wcl_while1

wcl_wend1:      moveq   #CBIT,D0        ;CBIT
                move.w  D4,D1           ;n
                bsr     putbits         ;putbits(CBIT, n)

                moveq   #0,D5           ;i=0

wcl_while2:     cmp.w   D4,D5
                bge     wcl_wend2

                addq.w  #1,D5           ;i++

                moveq   #0,D6
                move.b  (A2)+,D6        ;if((k=*clen++)==0)
                bne     wcl_else1

wcl_if1:        moveq   #1,D6           ;k=1

                cmp.w   D4,D5
                bge.s   wcl_wend3
                tst.b   (A2)
                bne.s   wcl_wend3

wcl_while3:     addq.l  #1,A2           ;clen++
                addq.w  #1,D6           ;k++
                addq.w  #1,D5           ;i++

                cmp.w   D4,D5
                bge.s   wcl_wend3
                tst.b   (A2)
                beq.s   wcl_while3

wcl_wend3:      subq.w  #1,D6           ;switch(k)
                beq.s   wcl_switch1_1   ;case 1
                subq.w  #1,D6
                beq.s   wcl_switch1_2   ;case 2
                cmp.w   #19-2,D6
                beq.s   wcl_switch1_19  ;case 19

wcl_default1:   cmp.w   #18-2,D6
                bgt.s   wcl_else2

wcl_if2:        moveq   #0,D0
                move.b  pt_len+1*1-BSS(A6),D0 ;pt_len[1]
                move.w  pt_code+1*2-BSS(A6),D1 ;c1=pt_code[1]
                bsr     putbits         ;putbits(pt_len[1], c1)
                moveq   #4,D0
                move.w  D6,D1
                subq.w  #3-2,D1
                bsr     putbits         ;putbits(4,k-3)
                bra.s   wcl_while2      ;(endif2=endswitch1=endif1)

wcl_else2:      moveq   #0,D0
                move.b  pt_len+2*1-BSS(A6),D0 ;pt_len[2]
                move.w  pt_code+2*2-BSS(A6),D1
                bsr     putbits         ;putbits(pt_len[2], pt_code[2])
                moveq   #CBIT,D0
                move.w  D6,D1
                sub.w   #20-2,D1
                bsr     putbits         ;putbits(CBIT, k-20)
                bra.s   wcl_while2      ;(endif2=endswitch1=endif1)

wcl_switch1_2:  moveq   #0,D0
                move.b  pt_len+0*1-BSS(A6),D0
                move.w  pt_code+0*2-BSS(A6),D1
                bsr     putbits         ;putbits(pt_len[0], pt_code[0])

wcl_switch1_1:  moveq   #0,D0
                move.b  pt_len+0*1-BSS(A6),D0
                move.w  pt_code+0*2-BSS(A6),D1
                bsr     putbits         ;putbits(pt_len[0], pt_code[0])
                bra     wcl_while2      ;(endswitch1=endif1)

wcl_switch1_19: moveq   #0,D0
                move.b  pt_len+0*1-BSS(A6),D0
                move.w  pt_code+0*2-BSS(A6),D1
                bsr     putbits         ;putbits(pt_len[0], pt_code[0])
                moveq   #0,D0
                move.b  pt_len+1*1-BSS(A6),D0
                move.w  pt_code+1*2-BSS(A6),D1
                bsr     putbits         ;putbits(pt_len[1], pt_code[1])
                moveq   #4,D0
                moveq   #15,D1
                bsr     putbits         ;putbits(4,15)
                bra     wcl_while2      ;(endswitch1=endif1)

wcl_else1:      lea     pt_len+2*1-BSS(A6),A0 ;pt_len[k+2]
                adda.w  D6,A0
                moveq   #0,D0
                move.b  (A0),D0
                lea     pt_code+2*2-BSS(A6),A0 ;pt_code[k+2]
                add.w   D6,D6
                adda.w  D6,A0
                move.w  (A0),D1
                bsr     putbits         ;putbits(pt_len[k+2], pt_code[k+2])
                bra     wcl_while2      ;(endif1)

wcl_wend2:      movem.l (SP)+,D4-D6/A2
                rts


;*******************

                BSS

BSS:

align 4
temp:           DS.L 1                  ;temporäre Variable (Encode5)

align 4
pt_len:         DS.B NPT                ;(  19 Bytes) uchar pt_len[NPT]
align 4
len_cnt:        DS.W 17                 ;(  34 Bytes) ushort len_cnt[17]
align 4
start:          DS.W 18                 ;(  36 Bytes) ushort start[1..17]

align 4
output_pool:    DS.W 1
last_matchpos:  DS.W 1
depth:          DS.W 1                  ;
heapsize:       DS.W 1                  ;int heapsize

                IF __030__
align 4
bitcount:       DS.L 1                  ;struct
bufadr:         DS.L 1                  ; "
bufsiz:         DS.L 1                  ; "

                ELSE
align 4
bitcount:       DS.W 1                  ;struct
subbitbuf:      DS.W 1                  ; "
bufadr:         DS.L 1                  ; "
bufptr:         DS.L 1                  ; "
                ENDC

align 4
_text:          DS.L 1                  ;Pufferaddressen
_position:      DS.L 1
outrec:         DS.L 1                  ;OutRec *outrec

output_pos:     DS.L 1
remainder:      DS.L 1
avail:          DS.L 1
sortptr:        DS.L 1                  ;

align 4
mt_parameter:
                DS.W 1                  ;even
n:              DS.W 1                  ;
freq:           DS.L 1                  ;ushort *freq
len:            DS.L 1                  ;uchar *len

align 4
parameter:
                DS.B 3                  ;even
compress:       DS.B 1                  ;uchar compress
comp_file:      DS.L 1                  ;ArcFile *comp_file
ProcInd:        DS.L 1                  ;ProcInd_t *ProcInd

align 4
pt_code:        DS.W NPT                ;(  38 Bytes) ushort pt_code[NPT]
align 4
p_freq:         DS.W 2*NP-1             ;(  54 Bytes) ushort p_freq[2*NP-1]
align 4                               ;wegen Löschroutine !!!
align 4
t_freq:         DS.W 2*NT-1             ;(  74 Bytes) ushort t_freq[2*NT-1]
align 4
c_len:          DS.B NC                 ;( 510 Bytes) uchar c_len[NC]
align 4
c_code:         DS.W NC                 ;(1020 Bytes) ushort c_code[NC]
align 4
left:           DS.W 2*NC-1             ;(2038 Bytes) ushort left[2*NC-1]  !!! auch in decode5.s
align 4
right:          DS.W 2*NC-1             ;(2038 Bytes) ushort right[2*NC-1] !!! auch in decode5.s
align 4
c_freq:         DS.W 2*NC-1             ;(2038 Bytes) ushort c_freq[2*NC-1]
align 4                               ;wegen Löschroutine !!!

align 4
heap:           DS.W NC+1               ;(1022 Bytes) int heap[NC+1]

align 4

                END
