/* @(#)lhatypes.h, -dh- 23.05.1996
 */

#ifndef _LHATYPES_H
#define _LHATYPES_H

#include <osbind.h>

typedef unsigned char	uchar;
typedef unsigned int	uint;
typedef unsigned short	ushort;
typedef unsigned long	ulong;

typedef unsigned long	clock_t;

typedef struct
{
	int dirs,files,items,selected;
	long bytes;
} SELECT;

typedef struct
{
	uchar	*ptr;
	long	cnt;
	uchar	*base;
	long	len;
	uchar	*buffer_start;
	uchar	*buffer_last;
	long	buffer_cnt;
	uchar	buffered;
} OutRec;

typedef struct
{
	FILE	*arc;		/*  0 */
	FILE	*file;		/*  4 */
	OutRec	*outrec;	/*  8 */
	ulong	size;		/* 12 */
	ulong	compsize;	/* 16 */
	crc_t	*crc;		/* 20 */
	crypt_t	*crypt;		/* 24 */
} ArcFile;
	
typedef struct
{
	void	*next;
	_DOSTIME time,Mtime;
	int		cluster;
#ifdef __SHELL__
	uint	crc,index;
	int		sel_files,sel_dirs;
	long	seek_pos,packed,unpacked,sel_size,sel_pack;
	uchar	*name,*comment;
	uchar	method,system,level;
	uchar	view[20],id[3];
#endif
	uchar	fpos,cpos,flag,Case,attr;
	uchar	dir[MAXPATH];
} filebuf;

typedef struct
{
	uchar		HeadSiz,HeadChk,HeadID[5];
	ulong		PacSiz,OrgSiz;
	_DOSTIME	Ftime;
	uchar		Attr,Level;
	uchar		Fname[MAXPATH];
	uchar		crypted;
	_DOSTIME	Mtime;
	uint		crc;
} LzHead;

typedef struct
{
    unsigned hour:5;
    unsigned min:6;
    unsigned sec:5;
    unsigned year:7;
    unsigned mon:4;
    unsigned day:5;
} ftime;

typedef struct xattr {
	ushort	mode;
	long	index;
	ushort	dev;
	ushort	reserved1;
	ushort	nlink;
	ushort	uid;
	ushort	gid;
	long	size;
	long	blksize;
	long	nblocks;
	short	mtime, mdate;
	short	atime, adate;
	short	ctime, cdate;
	short	attr;
	short	reserved2;
	long	reserved3[2];
} XATTR;

#endif
