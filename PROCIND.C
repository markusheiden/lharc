
/* Prozež-Indikator-Erzeugung (z.Z. nur ein Objekt m”glich) */

#include "procind.h"
#include "lharc.h"
#include <stdio.h>
#include <osbind.h>

void ProcInd_star(ProcInd_t *);
void ProcInd_percent(ProcInd_t *);
void ProcInd_rotate(ProcInd_t *);
void ProcInd_shell(ProcInd_t *);


ProcInd_t object;

const void *indicator_table[] = {ProcInd_star,
                                 NULL,
                                 ProcInd_percent,
                                 ProcInd_rotate,
                                 ProcInd_shell};

const char rotator_table[] = "-/|\\";


void init_ProcInd (void)
{
}


/* Erzeugen eines ProcInd-Objektes */
ProcInd_t *create_ProcInd (int flg_n, unsigned char star, unsigned char pnt)
{
  int mode=flg_n;

#ifdef SHELL  
  if (mode>4)
#else
  if (mode>3)
#endif
  {
    mode=0;
  }
    
  object.mode=mode;
  object.indicator=indicator_table[mode];
  object.star=star;
  object.pnt=pnt;

  object.count=0;
  object.blocksize=0;
  object.act_len=0;
  object.len=0;
  object.rotator_cnt=0;
  object.message=NULL;
  
  return (&object);
}


/* ProcInd-Ausgabe starten */
void start_ProcInd (ProcInd_t *object, unsigned char *message, unsigned long len, unsigned long blocksize, unsigned int maxblk)
{
  int blkcnt=(int) ((len+blocksize-1)/blocksize);
  unsigned long blksize=blocksize;

  char indicator[256]; /* Žndern !!! */
  char *p=indicator, pnt=object->pnt;

  switch (object->mode)
  {
#ifdef __SHELL__
    case 4: DialIndicator(0);
            break;
#endif

    case 3: sprintf(print_buf,"\r %s:   ",message);
            print(print_buf,0);
            break;

    case 2: sprintf(print_buf,"\r %s: %3d%% (%9ld/%9ld)",message,(int) 0, 0L, len);
            print(print_buf,0);
            break;

    case 1: break;

    case 0:
    default: if (blkcnt>maxblk)
             {
               blkcnt=maxblk;
               blksize=(len-1)/(maxblk-1);
             }

             for (;--blkcnt>=0;)
             {
               *p++=pnt;
             }
             *p='\0';

             sprintf(print_buf,"\r %s:   %s\r %s:   ",message,indicator,message);
             print(print_buf,0);
  }

  object->count=blksize-1;
  object->blocksize=blksize;
  object->act_len=0;
  object->len=len;
  object->rotator_cnt=0;
  object->message=message;
}


/* ProcInd-Schritt ausfhren */
void do_ProcInd (ProcInd_t *object, unsigned long count)
{
  void (*indicator) (ProcInd_t *)=object->indicator;

  object->count+=count;
  object->act_len+=count;

  while (object->count>=object->blocksize)
  {
    object->count-=object->blocksize;

    if (indicator)
    {
      (*indicator) (object);
    }
  }
}

void ProcInd_star (ProcInd_t *object)
{
  Cconout((int) object->star);
}

void ProcInd_percent (ProcInd_t *object)
{
  unsigned long act_len=object->act_len;
  unsigned long len=object->len;
  unsigned int percent=(unsigned int) (act_len*100L/len);

  if (act_len>=len)
  {
    act_len=len;
    percent=100;
  }

  sprintf(print_buf,"\r %s: %3d%% (%9ld/%9ld)",object->message,percent,act_len,len);
  print(print_buf,0);
}

void ProcInd_rotate (ProcInd_t *object)
{
  object->rotator_cnt+=1;
  object->rotator_cnt&=3;

  Cconout((int) rotator_table[object->rotator_cnt]);
  Cconout((int) '\b');
}

void ProcInd_shell (ProcInd_t *object)
{
  object->message=NULL;   /* Dummy */

#ifdef __SHELL__
  Dialindicator(0);
#endif
}


/* ProcInd-Ausgabe abschliežen */
void end_ProcInd (ProcInd_t *object, unsigned char *message, unsigned long original_len, unsigned long packed_len, unsigned int ratio)
{
  if (object->mode!=1)
  {
    if (original_len==0 && packed_len==0 && ratio==0)   /* Keine Zusammenfassung zeigen */
    {
      sprintf(print_buf,"\r %s:",message);
      print(print_buf,1);
    }
    else
    {
      sprintf(print_buf,"\r\033l\r %s: %9ld -> %9ld (%3d%%) ",message,original_len,packed_len,ratio);   /* Zusammenfassung */
      print(print_buf,1);
    } 
  }
}


/* ProcInd-Objekt zerst”ren */
void destroy_ProcInd (ProcInd_t *object)
{
  object->mode=1;   /* Dummy */
}
