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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#include "header.h"
#include "tools.h"

#include "lz4.h"

#include "acme.h"
#include "lapp_stdlib.h"
#include "fs.h"
#include "ps.h"
#include "sys.h"

static const luaL_Reg lrun_libs[] = {
    {"acme", luaopen_acme},
    {"stdlib", luaopen_stdlib},
    {"fs", luaopen_fs},
    {"ps", luaopen_ps},
    {"sys", luaopen_sys},
    {NULL, NULL},
};

static void createargtable(lua_State *L, const char **argv, int argc)
{
    int i, narg;
    narg = argc - 1;  /* number of positive indices */
    lua_createtable(L, narg, 1);
    for (i = 0; i < argc; i++) {
        lua_pushstring(L, argv[i]);
        lua_rawseti(L, -2, i);
    }
    lua_setglobal(L, "arg");
}

int main(int argc, const char *argv[])
{
    /* Lua payload extraction */
    FILE *f = fopen(argv[0], "rb");
    if (f == NULL) error(argv[0], "can not be open");

    t_header header;
    fseek(f, -(long)sizeof(header), SEEK_END);
    if (fread(&header, sizeof(header), 1, f) != 1) error(argv[0], "can not be read");
    if (memcmp(header.magic, LAPP_SIGNATURE, sizeof(header.magic)) != 0) error(argv[0], "Lua application not found");
    fseek(f, -(long)(header.compressed_size + sizeof(header)), SEEK_END);
    char *compressed_chunk = safe_malloc(header.compressed_size);
    if (fread(compressed_chunk, header.compressed_size, 1, f) != 1) error(argv[0], "Can not read Lua chunk");
    fclose(f);

    char *chunk = safe_malloc(header.uncompressed_size);
    const int uncompressed_size = LZ4_decompress_safe(
            compressed_chunk,
            chunk,
            (int)header.compressed_size,
            (int)header.uncompressed_size);
    if (uncompressed_size < 0 || (size_t)uncompressed_size != header.uncompressed_size)
    {
        error(argv[0], "Can not uncompress Lua chunk");
    }
    free(compressed_chunk);
    for (size_t i = 1; i < (size_t)uncompressed_size; i++)
    {
        chunk[i] += chunk[i-1];
    }

    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    createargtable(L, argv, argc);

    /* standard libraries */
    for (const luaL_Reg *lib = lrun_libs; lib->func != NULL; lib++)
    {
        luaL_requiref(L, lib->name, lib->func, 0);
        lua_pop(L, 1);
    }

    /* Lua payload execution */
    if (luaL_loadbuffer(L, chunk, header.uncompressed_size, NULL) != LUA_OK) error(argv[0], lua_tostring(L, -1));
    free(chunk);
    if (lua_pcall(L, 0, LUA_MULTRET, 0) != LUA_OK) error(argv[0], lua_tostring(L, -1));
    lua_close(L);
}
