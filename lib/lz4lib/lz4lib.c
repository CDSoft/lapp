/* This file is part of lapp.
 *
 * lapp is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * lapp is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with lapp.  If not, see <https://www.gnu.org/licenses/>.
 *
 * For further information about lapp you can visit
 * http://cdelord.fr/lapp
 */

#include "lz4lib.h"

#include "tools.h"

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>
#include <unistd.h>
#include <utime.h>

#ifdef __MINGW32__
#include <io.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <wincrypt.h>
#else
#include <glob.h>
#include <sys/select.h>
#endif

#include "lz4.h"
#include "lz4hc.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

// TODO: wrapper en C pour les fonctions de lz4
// TODO: functions plus haut niveau en lua pour la gestion de fichiers lz4 (frames)

#define LZ4_SIG  0x00345A4C

typedef struct
{
    uint32_t  sig;
    uint32_t  len;
} t_z_header;

static int bl_lz4_compress_core(const char *src, size_t src_len, char **dst, size_t *dst_len)
{
    unsigned long lz4_max_dst_len = LZ4_COMPRESSBOUND(src_len);
    char *lz4_dst = (char*)safe_malloc(lz4_max_dst_len + sizeof(t_z_header));
    int lz4_dst_len = LZ4_compress_default(src, lz4_dst+sizeof(t_z_header), (int)src_len, (int)lz4_max_dst_len);
    ((t_z_header *)lz4_dst)->sig = (uint32_t)LZ4_SIG;
    ((t_z_header *)lz4_dst)->len = (uint32_t)src_len;
    *dst = lz4_dst;
    *dst_len = (size_t)lz4_dst_len;
    *dst_len += sizeof(t_z_header);
    return 0;
}

static int bl_lz4hc_compress_core(const char *src, size_t src_len, char **dst, size_t *dst_len)
{
    unsigned long lz4_max_dst_len = LZ4_COMPRESSBOUND(src_len);
    char *lz4_dst = (char*)safe_malloc(lz4_max_dst_len + sizeof(t_z_header));
    int lz4_dst_len = LZ4_compress_HC(src, lz4_dst+sizeof(t_z_header), (int)src_len, (int)lz4_max_dst_len, LZ4HC_CLEVEL_MAX);
    ((t_z_header *)lz4_dst)->sig = (uint32_t)LZ4_SIG;
    ((t_z_header *)lz4_dst)->len = (uint32_t)src_len;
    *dst = lz4_dst;
    *dst_len = (size_t)lz4_dst_len;
    *dst_len += sizeof(t_z_header);
    return 0;
}

static int bl_lz4_decompress_core(lua_State *L, const char *src, size_t src_len, char **dst, size_t *dst_len)
{
    if (((const t_z_header *)src)->sig == LZ4_SIG)
    {
        *dst_len = ((const t_z_header *)src)->len + 3;
        *dst = (char*)safe_malloc(*dst_len);
        int r = LZ4_decompress_safe(src+sizeof(t_z_header), *dst, (int)(src_len-sizeof(t_z_header)), (int)*dst_len);
        if (r < 0)
        {
            free(*dst);
            lua_pushnil(L);
            lua_pushfstring(L, "lz4: LZ4_decompress_safe (error: %d)", *dst_len);
            return 2;
        }
        *dst_len = (size_t)r;
        return 0;
    }
    return -1;
}

static int bl_lz4_compress(lua_State *L)
{
    const char *src = luaL_checkstring(L, 1);
    size_t src_len = lua_rawlen(L, 1);
    char *dst;
    size_t dst_len;
    int n = bl_lz4_compress_core(src, src_len, &dst, &dst_len);
    if (n > 0) return n; /* error messages pushed by bl_lz4_compress_core */
    lua_pop(L, 1);
    lua_pushlstring(L, dst, (size_t)(dst_len));
    free(dst);
    return 1;
}

static int bl_lz4hc_compress(lua_State *L)
{
    const char *src = luaL_checkstring(L, 1);
    size_t src_len = lua_rawlen(L, 1);
    char *dst;
    size_t dst_len;
    int n = bl_lz4hc_compress_core(src, src_len, &dst, &dst_len);
    if (n > 0) return n; /* error messages pushed by bl_lz4_compress_core */
    lua_pop(L, 1);
    lua_pushlstring(L, dst, (size_t)(dst_len));
    free(dst);
    return 1;
}

static int bl_lz4_decompress(lua_State *L)
{
    const char *src = luaL_checkstring(L, 1);
    size_t src_len = lua_rawlen(L, 1);
    char *dst;
    size_t dst_len;
    int n = bl_lz4_decompress_core(L, src, src_len, &dst, &dst_len);
    if (n > 0) return n; /* error messages pushed by bl_lz4_decompress_core */
    if (n < 0)           /* string not compressed by lz4 */
    {
        lua_pushnil(L);
        lua_pushstring(L, "lz4: not a compressed string");
        return 2;
    }
    lua_pop(L, 1);
    lua_pushlstring(L, dst, (size_t)(dst_len));
    free(dst);
    return 1;
}

static const luaL_Reg lz4lib[] =
{
    {"compress", bl_lz4_compress},
    {"compress_hc", bl_lz4hc_compress},
    {"decompress", bl_lz4_decompress},
    {NULL, NULL}
};

LUAMOD_API int luaopen_lz4 (lua_State *L)
{
    luaL_newlib(L, lz4lib);
    return 1;
}
