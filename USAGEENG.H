uchar title[] =
"\r\n"
" LHarc "LZHVERSION", Copyright (c) Yoshizaki, 1988-89\r\n"
" Atari version (c) Grunenberg, Mandel, 1994, Dirk Haun, 1996/97, Heiden, 1998/99\r\n";

#ifndef __SHELL__

uchar title_x[] =
"  LHarc Version "LZHVERSION" (Atari)\r\n"
"  (c) Yoshizaki, 1988-89, Grunenberg, Mandel, 1994, Haun, 1996/97, Heiden, 1998/99";

uchar *usage[] =
{
" ================================================================ "__DATE__" =",
" Syntax: LHarc [<command>] [{{-|/}{<switchs>[-|+|0-3|<options>]}}...] <archive>",
"         [{<Drive>:[\\]}|{<Base-Directory>\\}] {[&|&-|~] <Paths/Files> ...}",
" ------------------------------------------------------------------------------",
"  <Command>",
"    a: Add files to archive             u: Update newer files to archive",
"  f,r: Freshen/Re-construct archive     m: Move files to archive (means 'a -d')",
"    d: Delete files from archive      e,x: Extract files from archive",
"    p: DisPlay files on screen        l,v: List/Verbose list of archive",
"    t: Test integrity of archive        c: Compress files in AFX-format",
" ------------------------------------------------------------------------------",
"  <Switches> (WARNING: The meaning of the d-switch has been completely changed)",
"    a: Any attribute                    b: Clear 'Changed'-attribute",
"    c: Skip time-comparison             d: Delete files after command",
"    e: Include file-comments            f: Include folders in archive",
"    g: Extract archive in folder        h: Hold screen after finishing",
"    i: Ignore attributes                j: Exclude empty files",
"    k: Header-level (0-2)               l: Use Larc compatible method",
"    m: No Message at query              n: Set process-indicator",
"    o: Use LHarc 1.13 compatible method p: Distinguish pathnames",
"    q: Suppress all messages (quiet)    r: Recursive expansion of dirs",
"    s: Convert backslashs to slashs     t: Time-stamp of archive",
"    u: Store - don't compress files     v: Display with external tool",
"    w: Specify work-directory           x: Extend filenames",
"    y: Only files with 'changed' attr.  z: Include archive-comment",
"    A: Add if file is not in archive    B: Retain backup copy of archive",
"    C: No crc-check during extraction   D: Delete if file is not specified",
"    F: create 5+3 file names            I: Compress files to directory",
"    K: Acoustic signal after finishing  L: Limit memory-allocations",
"    M: Maximum file-size                N: Only files newer than date ddmmyy",
"    O: don't extract to folder          P: Process-Indicator-Character",
"    R: Rename Unix-Files                S: Case-Sensitive filenames",
"    U: Store files uncompressed         W: No wildcard-matching",
"    X: Make relativ pathnames           Y: Encryption",
"    4: Store in Larc compatible method  5: Force LHarc 2.0x archive (lh5)",
"    ?: Display helpscreen",
"path;\ Make relativ pathnames          ~,! Exclude files",
"   &,@ Get file-list from file       &-,@- Get file-list from standard input",
" ==============================================================================",
"  (You'll find a more detailed description in the documentation 'MANUAL.ENG')",
"",
"  e-mail Yoshizaki: Nifty-Serve  PFF00253  /  oASCII-pcs   pcs02846",
0L
};
#endif

uchar KEY_YES        = 'Y';
uchar KEY_NO         = 'N';
uchar KEY_ALL        = 'A';
uchar KEY_RENAME     = 'R';
uchar KEY_QUIT       = 'Q';
uchar KEYS_YESNO[]   = "YN";
uchar KEYS_CHOOSE[]  = "YNA";
uchar KEYS_CHOOSE2[] = "YNRA";

uchar M_UNKNOWNERR[] = "Unknown error";
uchar M_INVCMDERR[]  = "Unknown command";
uchar M_MANYPATERR[] = "";
uchar M_NOARCNMERR[] = "No arcname";
uchar M_NOFNERR[]    = "No filename";
uchar M_NOARCERR[]   = "Archive doesn't exist";
uchar M_RENAMEERR[]  = "Unable to rename archive";
uchar M_MKTMPERR[]   = "Unable to create temporary file";
uchar M_DUPFNERR[]   = "";
uchar M_TOOMANYERR[] = "";
uchar M_TOOLONGERR[] = "Pathname is to long";
uchar M_NOFILEERR[]  = "No files found";
uchar M_MKFILEERR[]  = "Unable to create archive";
uchar M_RDERR[]      = "Unable to read file";
uchar M_WTERR[]      = "Unable to write file";
uchar M_MEMOVRERR[]  = "Not enough memory available";
uchar M_INVSWERR[]   = "";
uchar M_CTRLBRK[]    = "";
uchar M_NOMATCHERR[] = "Unable to find file";
uchar M_COPYERR[]    = "\r\nUnable to copy temporary file to archive";
uchar M_NOTLZH[]     = "Extension of archive (%s) is not 'LZH'.\r\nContinue? [Y/N]";
uchar M_OVERWT[]     = "File exists - Overwrite [Y/N/All] or Rename?";
uchar M_ENTERNEW[]   = "New name:";
uchar M_MKDIR[]      = "Create folder? [Y/N/All]";
uchar M_MKDIRERR[]   = "Unable to create folder";
uchar M_CRCERR[]     = "";
uchar M_RDONLY[]     = "File is read-only!";
uchar M_PRESSKEY[]   = "-- Press key to continue --";
uchar M_COMMENT[]    = "Comment:";
uchar M_PATH[]       = "Paths/Files (wildcards possible (*?@[^-|],)) :";
uchar M_FILETAB[]    = "File table overflow. Ignore";
uchar M_BADTAB[]     = "Bad table/encrypted file";
uchar M_GARBAGE[]    = "Garbage found and skipped";
uchar M_FT_OVERF[]   = "File table overflow, %d file(s) ignored!\r\nUse minimal or medium memory-usage!";
uchar M_DELETE_F[]   = "Deleting original files...";
uchar M_DELETE_A[]   = "Clearing archive bits...";
uchar M_UPDATE[]     = "Updating archive";
uchar M_FREEZE[]     = "Freeze/Store to";
uchar M_CREATE[]     = "Creating archive";
uchar M_ALLR_AFX[]   = "Already in AFX-format";
uchar M_ALLR_LHA[]   = "Already in LHarc-format";
uchar M_PRG[]        = "Program-file";
uchar M_READ_ERR[]   = "Read-Error";
uchar M_FRESHEN[]    = "Freshening archive";
uchar M_SAME_NAME[]  = "Object with same name exists";
uchar M_F_EXISTS[]   = "File already exists";
uchar M_NEW_O_SAME[] = "New or same file exists";
uchar M_UNKNOWN_M[]  = "Unknown method";
uchar M_FILE_LONG[]  = "File too long";
uchar M_HIDDEN_F[]   = "Hidden/System file";
uchar M_CRYPT_F[]    = "Encrypted file";
uchar M_NO_SELF_E[]  = "Self-Extracting-Files: NOT YET IMPLEMENTED!\7";
#ifdef __030__
uchar M_WRONG_CPU[]  = "\r\n This version of LHarc requires a 68020 processor or better!\r\n\r\n";
#endif

uchar T_DIRECTORY[]  = "Directory";
uchar T_TEMP_ARC[]   = "temp. archive";
uchar T_DISK_FULL[]  = "Disk full";
uchar T_EXTRACT[]    = "Extract from";
uchar T_GARBAGE[]    = "Garbage found at the archive-end";
uchar T_BYTES[]      = "bytes";
uchar T_PATTERN[]    = "Pattern";
uchar T_FILE_MATCH[] = "Files matched";
uchar T_FT_OVERF[]   = "File table overflow";
uchar T_FILES_IGN[]  = "file(s) ignored";
uchar T_SKIPPED[]    = "Skipped";
uchar T_CRC_ERR[]    = "CRC error";
uchar T_BAD_TBL[]    = "Bad Table";
uchar T_DELETING[]   = "Deleting";
uchar T_LISTING[]    = "Listing of archive";
uchar T_ARGUMENTS[]  = "Arguments:";
uchar T_ARCS_MATCH[] = "Archives matched";
uchar T_NO_FILE[]    = "No file";
uchar T_FILES[]      = "files";
uchar T_DIRS[]       = "directories";
uchar T_ENCRYPTED[]  = "encrypted";
uchar T_UNKNOWN_S[]  = "Unknown system";

/* Processing Status */
uchar T_FREEZING[]   = "Freezing";
uchar T_FREEZED[]    = "Freezed ";
uchar T_STORING[]    = "Storing ";
uchar T_STORED[]     = "Stored  ";
uchar T_MELTING[]    = "Melting ";
uchar T_MELTED[]     = "Melted  ";
uchar T_TESTING[]    = "Testing ";
uchar T_TESTED[]     = "Tested  ";

/* Error report */
uchar T_BAD_TBLS[]   = "Bad Tables   ";   /* must have same width */
uchar T_CRC_ERRS[]   = "CRC errors   ";
uchar T_SKIPPED_F[]  = "Skipped files";
uchar T_CRASHED_F[]  = "Crashed files";

/* List header */
uchar T_NAME[]       = "Name";          /* max. width 13 */
uchar T_ORIGINAL[]   = "Original";      /* max. width  8 */
uchar T_PACKED[]     = "Packed";        /* max. width  8 */
uchar T_RATIO[]      = "Ratio";         /* max. width  6 */
uchar T_DATE[]       = "Date";          /* max. width  8 */
uchar T_TIME[]       = "Time";          /* max. width  8 */
uchar T_ATTR[]       = "Attr";          /* max. width  4 */
uchar T_TYP[]        = "Typ";           /* max. width  5 */
uchar T_CRC[]        = "CRC";           /* max. width  4 */
uchar T_LEVEL[]      = "Level";         /*      width  5 */

