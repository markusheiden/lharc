/* Codierung (z.Z. nur ein Objekt möglich) */

typedef struct
{
  long          cryptsize;
  unsigned char *key;
  unsigned char *keyinit;
} crypt_t;

extern void init_crypt (unsigned char *);
extern crypt_t *create_crypt (long cryptsize);
extern void encrypt (unsigned char *, long, crypt_t *);
extern void decrypt (unsigned char *, long, crypt_t *);
extern void destroy_crypt (crypt_t *);
