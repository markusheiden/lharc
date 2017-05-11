const uchar title[] =
"\r\n"
" LHarc "LZHVERSION", Copyright (c) Yoshizaki, 1988-89\r\n"
" Atari-Version (c) Grunenberg, Mandel, 1994, Haun, 1996/97, Heiden, 1998/99\r\n";

#ifndef __SHELL__

const uchar title_x[] =
"  LHarc Version "LZHVERSION" (Atari)\r\n"
"  (c) Yoshizaki, 1988-89, Grunenberg, Mandel, 1994, Haun, 1996/97, Heiden, 1998/99";

uchar *usage[] =
{
" ================================================================ "__DATE__" =",
" Aufruf: LHarc [<Kommando>] [{{-|/}{<Schalter>[-|+|0-3|<Option>]}}...] <Archiv>",
"         [{<Laufwerk>:[\\]}|{<Hauptverzeichnis>\\}] {[&|&-|~] <Pfade> ...}",
" ------------------------------------------------------------------------------",
"  <Kommando>",
"     a: Dateien an Archiv anfügen       u: Dateien, falls neuer, anfügen",
"   f,r: Dateien im Archiv erneuern      m: Datei in das Archiv schieben",
"     d: Dateien aus Archiv löschen    e,x: Dateien aus Archiv extrahieren",
"     p: Dateien aus Archiv anzeigen   l,v: Dateiliste des Archivs",
"     t: Archiv testen                   c: Dateien für AFX komprimieren",
" ------------------------------------------------------------------------------",
"  <Schalter>  (ACHTUNG: Die Bedeutung des d-Schalters wurde komplett geändert)",
"     a: Erlaube alle Dateiattribute     b: Archiv-Bit der Dateien löschen",
"     c: Kein Vergleich des Dateidatums  d: Bearbeitete Dateien löschen",
"     e: Dateikommentare eingeben        f: Ordner ebenfalls einpacken",
"     g: Archiv in Ordner auspacken      h: Warte auf Tastendruck vor Ende",
"     i: Dateiattribute ignorieren       j: Dateien der Länge 0 ausschließen",
"     k: Header-Level (0-2)              l: Erzeuge Larc-kompatibles Archiv",
"     m: Nachfragen ausschalten          n: Prozeßindikator einstellen",
"     o: Erzeuge 1.13-kompatibles Archiv p: Unterscheide Ordnernamen",
"     q: Unterdrücke alle Ausgaben       r: rekursive Datei-/Ordnersuche",
"     s: Wandle \\ in / um                t: Archivdatum setzen",
"     u: Ungepackt archivieren           v: Dateien mit anderem Prg ansehen",
"     w: Arbeitsverzeichnis bestimmen    x: Erweitere Dateinamen",
"     y: Nur Dateien mit Archiv-Bit      z: Archivkommentar eingeben",
"     A: Dateien an das Archiv anhängen  B: Backup vom Archiv erzeugen",
"     C: Keine Prüfsummenüberprüfung     D: Dateien aus dem Archiv entfernen",
"     F: 5+3-Regel für lange Dateinamen  I: Dateien in Verzeichnis packen",
"     K: Akustisches Signal am Ende      L: Speicherbedarf einstellen",
"     M: Maximale Dateigröße             N: Nur Dateien neuer als Datum ddmmyy",
"     O: nicht in Verzeichnis entpacken  P: Prozeßindikator-Zeichen",
"     R: Unix-Dateien manuell umbenennen S: Groß-/Kleinschreibung von Dateinamen",
"     U: Dateien ungepackt archivieren   W: Kein Wildcard-Matching",
"     X: Dateipfade relativ sichern      Y: Verschlüsselung",
"     4: Ungepacktes Larc-Archiv         5: Erzwinge lh5-Archiv",
"     ?: Hilfsbildschirm ausgeben",
" Pfad;\ Dateipfad relativ sichern      ~,! Dateien ausschließen",
"    &,@ Pfade aus Datei einlesen     &-,@- Pfade von stdin eingeben",
" ==============================================================================",
"   ( Eine genauere Beschreibung finden Sie in der Anleitung 'MANUAL.GER' )",
"",
"  e-mail Yoshizaki: Nifty-Serve  PFF00253  /  oASCII-pcs   pcs02846",
0L
};
#endif

uchar KEY_YES        = 'J';
uchar KEY_NO         = 'N';
uchar KEY_ALL        = 'A';
uchar KEY_RENAME     = 'R';
uchar KEY_QUIT       = 'Q';
uchar KEYS_YESNO[]   = "JN";
uchar KEYS_CHOOSE[]  = "JNA";
uchar KEYS_CHOOSE2[] = "JNRA";

uchar M_UNKNOWNERR[] = "Unbekannter Fehler";
uchar M_INVCMDERR[]  = "Unbekanntes Kommando";
uchar M_MANYPATERR[] = "";
uchar M_NOARCNMERR[] = "Kein Archivname";
uchar M_NOFNERR[]    = "Kein Dateiname";
uchar M_NOARCERR[]   = "Archiv existiert nicht";
uchar M_RENAMEERR[]  = "Ich kann das Archiv nicht umbenennen";
uchar M_MKTMPERR[]   = "Ich kann die temporäre Datei nicht erstellen";
uchar M_DUPFNERR[]   = "";
uchar M_TOOMANYERR[] = "";
uchar M_TOOLONGERR[] = "Pfadname ist zu lang";
uchar M_NOFILEERR[]  = "Keine Datei gefunden";
uchar M_MKFILEERR[]  = "Ich kann das Archiv nicht anlegen";
uchar M_RDERR[]      = "Ich kann die Datei nicht lesen";
uchar M_WTERR[]      = "Ich kann die Datei nicht schreiben";
uchar M_MEMOVRERR[]  = "Kein Speicher mehr frei";
uchar M_INVSWERR[]   = "";
uchar M_CTRLBRK[]    = "";
uchar M_NOMATCHERR[] = "Ich kann die Datei nicht finden";
uchar M_COPYERR[]    = "\r\nIch konnte die temporäre Datei nicht in das Archiv kopieren";
uchar M_NOTLZH[]     = "Erweiterung des Archivs (%s) ist nicht 'LZH'.\r\nWollen Sie fortfahren? [J/N] ";
uchar M_OVERWT[]     = "Datei existiert. Überschreiben [J/N/Alle] oder Rename [R]? ";
uchar M_ENTERNEW[]   = "Neuer Name:";
uchar M_MKDIR[]      = "Ordner anlegen? [J/N/Alle] ";
uchar M_MKDIRERR[]   = "Ich konnte den Ordner nicht anlegen";
uchar M_CRCERR[]     = "";
uchar M_RDONLY[]     = "Datei mit 'Nur lesen'-Status!";
uchar M_PRESSKEY[]   = "-- Mit Tastendruck gehts weiter --";
uchar M_COMMENT[]    = "Kommentar:";
uchar M_PATH[]       = "Pfade/Dateien (Wildcards erlaubt (*?@[^-|],)):";
uchar M_FILETAB[]    = "Datei-Tabelle voll. Ignoriere";
uchar M_BADTAB[]     = "Zerstörte Tabelle/verschlüsselte Datei";
uchar M_GARBAGE[]    = "Zerstörte Daten gefunden und überlesen";
uchar M_FT_OVERF[]   = "Datei-Tabelle voll, %d Datei(en) ignoriert!\r\nBenutzen sie minimalen oder mittleren Speicherverbrauch!";
uchar M_DELETE_F[]   = "Lösche Original-Dateien...";
uchar M_DELETE_A[]   = "Lösche Archiv-Bits...";
uchar M_UPDATE[]     = "Aktualisiere Archiv";
uchar M_FREEZE[]     = "Komprimiere/Speichere nach";
uchar M_CREATE[]     = "Erstelle Archiv";
uchar M_ALLR_AFX[]   = "Datei bereits im AFX-Format";
uchar M_ALLR_LHA[]   = "Datei bereits im LHarc-Format";
uchar M_PRG[]        = "Programm-Datei";
uchar M_READ_ERR[]   = "Lese-Fehler";
uchar M_FRESHEN[]    = "Aktualisiere Archiv";
uchar M_SAME_NAME[]  = "Objekt mit gleichem Namen existiert bereits";
uchar M_F_EXISTS[]   = "Datei existiert bereits";
uchar M_NEW_O_SAME[] = "Neuere oder gleiche Datei existiert bereits";
uchar M_UNKNOWN_M[]  = "Unbekannte Methode";
uchar M_FILE_LONG[]  = "Datei zu lang";
uchar M_HIDDEN_F[]   = "Versteckte oder System-Datei";
uchar M_CRYPT_F[]    = "Verschlüsselte Datei";
uchar M_NO_SELF_E[]  = "Selbst-extrahierende Files: NOCH NICHT IMPLEMENTIERT!\7";
#ifdef __030__
uchar M_WRONG_CPU[]  = "\r\n Diese Version benötigt mindestens einen 68020-Prozessor!\r\n\r\n";
#endif

uchar T_DIRECTORY[]  = "Verzeichnis";
uchar T_TEMP_ARC[]   = "temp. Archiv";
uchar T_DISK_FULL[]  = "Disk voll";
uchar T_EXTRACT[]    = "Extrahiere aus";
uchar T_GARBAGE[]    = "Überflüssige Daten am Archivende";
uchar T_BYTES[]      = "Bytes";
uchar T_PATTERN[]    = "Suchmuster";
uchar T_FILE_MATCH[] = "Dateien gefunden";
uchar T_FT_OVERF[]   = "Datei-Tabelle voll";
uchar T_FILES_IGN[]  = "Datei(en) ignoriert";
uchar T_SKIPPED[]    = "Übersprungen";
uchar T_CRC_ERR[]    = "Prüfsummen-Fehler";
uchar T_BAD_TBL[]    = "Zerstörte Tabelle";
uchar T_DELETING[]   = "Lösche";
uchar T_LISTING[]    = "Inhalt von";
uchar T_ARGUMENTS[]  = "Argumente:";
uchar T_ARCS_MATCH[] = "Archive gefunden";
uchar T_NO_FILE[]    = "Keine Datei";
uchar T_FILES[]      = "Dateien";
uchar T_DIRS[]       = "Verzeichnisse";
uchar T_ENCRYPTED[]  = "verschlüsselt";
uchar T_UNKNOWN_S[]  = "Unbekanntes System";

/* Processing Status */
uchar T_FREEZING[]   = "Komprimiere";
uchar T_FREEZED[]    = "Komprimiert";
uchar T_STORING[]    = "Speichere  ";
uchar T_STORED[]     = "Gespeichert";
uchar T_MELTING[]    = "Dekomprimiere";
uchar T_MELTED[]     = "Dekomprimiert";
uchar T_TESTING[]    = "Teste   ";
uchar T_TESTED[]     = "Getestet";

/* Error report */
uchar T_BAD_TBLS[]   = "Zerstörte Tabellen   ";   /* must have same width */
uchar T_CRC_ERRS[]   = "Prüfsummen-Fehler    ";
uchar T_SKIPPED_F[]  = "Übersprungene Dateien";
uchar T_CRASHED_F[]  = "Zerstörte Dateien    ";

/* List header */
uchar T_NAME[]       = "Name";          /* max. width 13 */
uchar T_ORIGINAL[]   = "Original";      /* max. width  8 */
uchar T_PACKED[]     = "Gepackt";       /* max. width  8 */
uchar T_RATIO[]      = "Rate";          /* max. width  6 */
uchar T_DATE[]       = "Datum";         /* max. width  8 */
uchar T_TIME[]       = "Zeit";          /* max. width  8 */
uchar T_ATTR[]       = "Attr";          /* max. width  4 */
uchar T_TYP[]        = "Typ";           /* max. width  5 */
uchar T_CRC[]        = "CRC";           /* max. width  4 */
uchar T_LEVEL[]      = "Level";         /* max. width  5 */

