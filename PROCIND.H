/* Prozeß-Indikator-Erzeugung (z.Z. nur ein Objekt möglich) */

#ifndef _PROCIND_H
#define _PROCIND_H

typedef struct
{
  unsigned long count;
  unsigned long blocksize;
  unsigned long act_len;
  unsigned long len;
  void (*indicator) ();
  unsigned char *message;
  int rotator_cnt;
  int mode;
  unsigned char star;
  unsigned char pnt;
} ProcInd_t;

extern void init_ProcInd (void);
extern ProcInd_t *create_ProcInd (int, unsigned char, unsigned char);
extern void start_ProcInd (ProcInd_t *, unsigned char *, unsigned long, unsigned long, unsigned int);
extern void do_ProcInd (ProcInd_t *, unsigned long);
extern void end_ProcInd (ProcInd_t *, unsigned char *, unsigned long, unsigned long, unsigned int);
extern void destroy_ProcInd (ProcInd_t *);

#endif
