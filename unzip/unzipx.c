/* unzipx.c - Troels K. 2003-2004 */

#include <stdio.h>
#include <stdlib.h>
#include "unzipx.h"

#ifndef local
#  define local static
#endif

unzFile ZEXPORT unzAttachW(stream, pzlib_filefunc_def)
    voidpf stream;
    struct zlib_filefunc_defW_s* pzlib_filefunc_def;
{
   /* 
      just cast away the wchar_t stuff. 
      zlib_filefunc_defW_s and zlib_filefunc_def_s is same size
      and open(wchar_t) isn't even called
   */
   return unzAttach(stream, (zlib_filefunc_def*)pzlib_filefunc_def);
}

unzFile ZEXPORT unzOpen2W (path, pzlib_filefunc_def)
    const wchar_t *path;
    struct zlib_filefunc_defW_s* pzlib_filefunc_def;
{
   /* 
      just cast away the wchar_t stuff. 
      zlib_filefunc_defW_s and zlib_filefunc_def_s is same size,
      unzOpen2 doesn't use path for anything (only passes it on to the zopen_file callback)
   */
   return unzOpen2((const char*)path, (zlib_filefunc_def*)pzlib_filefunc_def);
}

/* 
   unzValidate: Thanks to Tom De Man for idea and testing
   - If the directory is corrupt (last part of the file is missing/bad), 
     unzOpen will probably fail (and your program needn't call unzValidate at all)
*/

local int unzValidateCurrent(unzFile file, const char* password, void* buffer, uLong buf_size)
{
   unz_file_info info;
   int result = unzGetCurrentFileInfo(file, &info, NULL, 0, NULL, 0, NULL, 0);
   if (UNZ_OK == result)
   {
      uLong crc = 0;
      size_t read_total = 0;
      int read;
      do
      {
         read = unzReadCurrentFile(file, buffer, buf_size);
         if (read > 0)
         {
            read_total+=read;
            crc = crc32(crc, (const Bytef *)buffer, read);
         }
         else if (read < 0)
         {
            /* Problem: Failed to fetch data? */
            result = read;
            break;
         }
      } while (read == buf_size);
      if (UNZ_OK == result)
      {
         if (crc != info.crc)
         {
            result = UNZ_BADZIPFILE;
         }
         if (read_total != info.uncompressed_size) /* crc check above is probably sufficient */
         {
            result = UNZ_BADZIPFILE;
         }
      }
   }
   /* else: Problem with unzGetCurrentFileInfo? */
   return result;
}

int unzValidate (file, password, buffer, buf_size)
   unzFile file;
   const char* password;
   void* buffer; 
   uLong buf_size; 
{
   int result = unzGoToFirstFile(file);
   if (UNZ_OK == result)
   {
      do
      {
         result = unzOpenCurrentFilePassword(file, password);
         if (UNZ_OK == result)
         {
            if (buffer && buf_size)
            {
               result = unzValidateCurrent(file, password, buffer, buf_size);
            }
            unzCloseCurrentFile(file);
         }
         /* else: Unsupported compression (PKZIP 1.x), or bad password, or ?? */
      } while ((UNZ_OK == result) && (UNZ_OK == unzGoToNextFile(file)));
   }
   /* else: Directory corrupt ?? */
   return result;
}

local uLong ZCALLBACK unz_read(voidpf opaque, voidpf stream, void* dst, uLong cb)
{
   unzFile file = (unzFile)opaque;
   uLong dwRead = 0;
   const int result = unzReadCurrentFile(file, dst, cb);
   if (result > 0) dwRead = (uLong)result;
   return dwRead;
}

local ZPOS_T ZCALLBACK unz_tell(voidpf opaque, voidpf stream)
{
   unzFile file = (unzFile)opaque;
   return unztell(file);
}

local int ZCALLBACK unz_close(voidpf opaque, voidpf stream)
{
   unzFile file = (unzFile)opaque;
   unzCloseCurrentFile(file);
   return 0;
}

void unz_fill_filefunc(unzFile file, zlib_filefunc_def* api)
{
   api->zopen_file  = NULL;
   api->zread_file  = unz_read;
   api->zwrite_file = NULL;
   api->ztell_file  = unz_tell;
   api->zseek_file  = NULL;
   api->zclose_file = unz_close;
   api->zerror_file = NULL;
   api->opaque      = file;
}

voidpf unzOpenCurrentFilePassword2(file, api, password)
   unzFile file;
   zlib_filefunc_def* api;
   const char* password;
{
   voidpf stream = NULL;
   if (UNZ_OK == unzOpenCurrentFilePassword(file, password))
   {
      unz_fill_filefunc(file, api);
      stream = (voidpf)1;
   }
   return stream;
}

voidpf unzLocateFileAndOpen (file, szFileName, iCaseSensitivity, api, password)
   unzFile file;
   const char *szFileName;
   int iCaseSensitivity;
   zlib_filefunc_def* api;
   const char* password;
{
   voidpf stream = NULL;
   if (UNZ_OK == unzLocateFile(file, szFileName, iCaseSensitivity))
   {
      stream = unzOpenCurrentFilePassword2(file, api, password);
   }
   return stream;
}

#if !TROELS_GOOD_UNZATTACH

typedef struct _ATTACH
{
   zlib_filefunc_def api; /* real api */
   voidpf stream;         /* real file stream */
} ATTACH;

static voidpf ZCALLBACK attach_open (voidpf opaque, const char* filename, int mode)
{
   /* NOP */
   return (voidpf)1;
}

static uLong ZCALLBACK attach_read (voidpf opaque, voidpf stream, void* buf, uLong size)
{
   ATTACH* attach = (ATTACH*)opaque;
   return (*attach->api.zread_file)(attach->api.opaque, attach->stream, buf, size);
}

static uLong ZCALLBACK attach_write (voidpf opaque, voidpf stream, const void* buf, uLong size)
{
   ATTACH* attach = (ATTACH*)opaque;
   return (*attach->api.zwrite_file)(attach->api.opaque, attach->stream, buf, size);
}

static ZPOS_T ZCALLBACK attach_tell (voidpf opaque, voidpf stream)
{
   ATTACH* attach = (ATTACH*)opaque;
   return (*attach->api.ztell_file)(attach->api.opaque, attach->stream);
}

static long ZCALLBACK attach_seek (voidpf opaque, voidpf stream, ZPOS_T offset, int origin)
{
   ATTACH* attach = (ATTACH*)opaque;
   return (*attach->api.zseek_file)(attach->api.opaque, attach->stream, offset, origin);
}

static int ZCALLBACK attach_close (voidpf opaque, voidpf stream)
{
   /* NOP */
   return 0;
}

static int ZCALLBACK attach_error (voidpf opaque, voidpf stream)
{
   ATTACH* attach = (ATTACH*)opaque;
   return (*attach->api.zerror_file)(attach->api.opaque, attach->stream);
}

unzFile ZEXPORT unzAttach(voidpf stream, zlib_filefunc_def* real_api)
{
   ATTACH* attach  = (ATTACH*)malloc(sizeof(ATTACH));
   zlib_filefunc_def api;
   unzFile file;
   
   api.zopen_file  = attach_open;
   api.zread_file  = attach_read;
   api.zwrite_file = attach_write;
   api.ztell_file  = attach_tell;
   api.zseek_file  = attach_seek;
   api.zclose_file = attach_close;
   api.zerror_file = attach_error;
   api.opaque      = attach;

   attach->api = *real_api;
   attach->stream = stream;
   file = unzOpen2(NULL, &api);
   if (file == NULL)
   {
      free(attach);
   }
   return file;
}

voidpf ZEXPORT unzDetach(unzFile* file)
{
   /* TERRIBLE HACK! unz_s definition is not in scope. z_filefunc is first in unz_s structure. */
   zlib_filefunc_def api = *(zlib_filefunc_def*)*file;
   ATTACH* attach = (ATTACH*)api.opaque;
   voidpf stream = attach->stream;
   unzClose(*file);
   *file = NULL;
   free(attach);
   return stream;
}

#endif /* !TROELS_GOOD_UNZATTACH */
