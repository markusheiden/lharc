#define BETA
#define GERMAN

#include <limits.h>
#include <ctype.h>

#include <errno.h>
#include <basepage.h>

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <osbind.h>
#include <time.h>
#include <mintbind.h>

#ifdef __SHELL__
# include "..\version.h"
#else
# include "version.h"
#endif

#include "crc.h"
#include "crypt.h"
#include "lhaconst.h"
#include "lhatypes.h"
#include "procind.h"

#ifdef __SHELL__
# define LZHVERSION VERSNO
#else
# ifdef __030__
#  define LZHVERSION VERSNO" junior/68030"
# else
#  define LZHVERSION VERSNO" junior"
# endif
#endif

#define close_file(f)   {if (f!=NULL) fclose(f);f=NULL;}

#define ITIME(t)        itime((ulong *) &t)
#define getch()         gemdos(0x08)

extern int __mint;
extern uchar upper[], print_buf[];

extern uchar *backpath(uchar *);

extern void DecodeOld (ArcFile *, ProcInd_t *);
extern void Decode1   (ArcFile *, ProcInd_t *);
extern int  Decode5   (ArcFile *, ProcInd_t *);
extern void EncodeOld (ArcFile *, ProcInd_t *, uchar);
extern void Encode1   (ArcFile *, ProcInd_t *, uchar);
extern void Encode5   (ArcFile *, ProcInd_t *, uchar);

extern ulong FTimeToULong(_DOSTIME*);
extern uchar *get_fname(uchar*);
extern void ilong(ulong*);
extern void itime(ulong*);
extern uchar mksum(LzHead*,int);
extern void OpenOut(OutRec *, uchar *, ulong);
extern void ProcInd(void);
extern uchar *stpcpy(uchar*,uchar*);
extern int test_afx(uchar*);

long    afxonoff(long);
/*int   arc_ext(uchar *);*/
/*int   Attrib(uchar *);*/
/*int   case_sensitive(uchar *);*/
/*int   chk_wild(uchar *,uchar *,int,int);*/
/*clock_t clock(void);*/
/*void  copyfile(FILE *,FILE *,uchar *,long,ProcInd_t *,int);*/
void    copy_to_view(uchar*,long);
void    dos_2_unixtime(void *);
/*int   drive(uchar *,uchar **);*/
void    error(int,uchar*,int);
/*int   gethdr(FILE *,LzHead *);*/
void    get_comment(FILE*);
/*uchar *get_ext(void);*/
/*void  lha_exit(void);*/
/*void  MakeBuffers(void);*/
/*void  make_attr(uchar*,int);*/
/*int   matchpattern(uchar*,uchar*);*/
/*int   openarc1(long,uchar *);*/
/*int   path_conf(uchar*,int);*/
void    print(uchar*,int);
void    Print(int);
void    proc_ind(void);
/*uint  ratio(ulong,ulong);*/
/*int   read_attr(uchar *,_DTA *);*/
int     search_lzh(FILE*,int);
void    ShipOut(OutRec *, int);
/*int   slash(uchar *,int);*/
/*uchar *sysid(char);*/
void    TruncFile(uchar *);
/*int   tst_fname(uchar *);*/
int     tstID(uchar *);
void    unix2dos(uchar *,int);
void    unix_2_dostime(void *);
/*int   wildcard(uchar *);*/
void    yen2slash(uchar *);
