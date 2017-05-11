
;FILE
F_cnt           equ     0       ;long           _cnt                ;fest (label wird nicht benutzt)
F_ptr           equ     4       ;unsigned char  *_ptr               ;fest (label wird nicht benutzt)
F_base          equ     8       ;unsigned char  *_base              ;fest (label wird nicht benutzt)
F_flag          equ     12      ;unsigned int   _flag               ;fest (label wird nicht benutzt)
F_file          equ     14      ;int            _file               ;fest (label wird nicht benutzt)
F_bsiz          equ     16      ;long           _bsiz               ;fest (label wird nicht benutzt)
F_ch            equ     20      ;unsigned       _ch                 ;fest (label wird nicht benutzt)

;OutRec
OR_ptr          equ     0       ;uchar          *ptr                ;fest (label wird nicht benutzt)
OR_cnt          equ     4       ;long           cnt                 ;fest (label wird nicht benutzt)
OR_base         equ     8       ;uchar          *base               ;fest (label wird nicht benutzt)
OR_len          equ     12      ;long           len                 ;fest (label wird nicht benutzt)
OR_buffer_start equ     16      ;uchar          *buffer_start
OR_buffer_last  equ     20      ;uchar          *buffer_last
OR_buffer_cnt   equ     24      ;long           buffer_cnt
OR_buffered     equ     28      ;uchar          buffered

;ArcFile
AF_arc          equ     0       ;FILE           *arc            
AF_file         equ     4       ;FILE           *file
AF_outrec       equ     8       ;OutRec         *outrec
AF_size         equ     12      ;long           size
AF_compsize     equ     16      ;long           compsize
AF_crc          equ     20      ;t_crc          *crc
AF_crypt        equ     24      ;t_crypt        *crypt

