/* unzipx.h - Troels K. 2003-2004 */

#ifndef _unzx_H
#define _unzx_H

#ifndef _unz_H
   #include "unzip.h"
#endif

/*
TROELS_GOOD_UNZATTACH 1: unzAttach/unzDetach implemented in unzip.c - nice
TROELS_GOOD_UNZATTACH 0: unzAttach/unzDetach implemented in unzipx.c using zlib_filefunc_def - messy
*/
#define TROELS_GOOD_UNZATTACH 0

#ifdef __cplusplus
   extern "C" {
#endif

#define ZIPDEFAULTFILEEXT "zip"

extern unzFile ZEXPORT unzAttach  OF((voidpf stream, zlib_filefunc_def*));

extern voidpf  ZEXPORT unzDetach  OF((unzFile*));

extern int    unzValidate OF((unzFile file, const char* password, void* check_contents_buffer, uLong buf_size));

/* Access compressed files using ioapi */
extern voidpf unzOpenCurrentFilePassword2 OF((unzFile file, zlib_filefunc_def*, const char* password));
extern voidpf unzLocateFileAndOpen OF((unzFile file, const char *szFileName, int iCaseSensitivity, zlib_filefunc_def*, const char* password));

/* the rest is Unicode stuff */
struct zlib_filefunc_defW_s;

extern unzFile ZEXPORT unzAttachW OF((voidpf stream, struct zlib_filefunc_defW_s*));

#ifdef _WCHAR_T_DEFINED
extern unzFile ZEXPORT unzOpen2W  OF((const wchar_t *path, struct zlib_filefunc_defW_s*));
#endif

#ifdef _UNICODE
   #define tunzAttach unzAttachW
   #define tunzOpen2  unzOpen2W
#else
   #define tunzAttach unzAttach
   #define tunzOpen2  unzOpen2
#endif

#ifdef __cplusplus
   }
#endif

#endif /* _unzx_H */
