/* CRC-Berechnung (z.Z. nur ein Objekt möglich) */

typedef struct
{
  int crc;
} crc_t;

extern void init_crc (void);
extern crc_t *create_crc (void);
extern void block_crc (unsigned char *, long, crc_t *);
extern int get_crc (crc_t *);
extern void destroy_crc (crc_t *);
