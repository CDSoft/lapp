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

#ifdef __MINGW32__
#include <windows.h>
#else
#include <unistd.h>
#endif

#include "header.h"
#include "tools.h"

#include "lauxlib.h"
#include "lualib.h"

#include "lz4.h"

#include "crypt.h"
#include "fs.h"
#include "lpeg.h"
#include "luasocketlib.h"
#include "lz4lib.h"
#include "ps.h"
#include "rl.h"
#include "std.h"
#include "sys.h"
#include "mathx.h"
#include "imathlib.h"
#include "qmathlib.h"
#include "complexlib.h"

static const luaL_Reg lrun_libs[] = {
    {"std", luaopen_std},
    {"fs", luaopen_fs},
    {"ps", luaopen_ps},
    {"sys", luaopen_sys},
    {"lz4", luaopen_lz4},
    {"lpeg", luaopen_lpeg},
    {"luasocket", luaopen_luasocket},
    {"crypt", luaopen_crypt},
    {"rl", luaopen_rl},
    {"mathx", luaopen_mathx},
    {"imath", luaopen_imath},
    {"qmath", luaopen_qmath},
    {"complex", luaopen_complex},
    {NULL, NULL},
};

static void createargtable(lua_State *L, const char **argv, int argc, int shift)
{
    int i, narg;
    narg = argc - 1 - shift;  /* number of positive indices */
    lua_createtable(L, narg, 1);
    for (i = 0; i < argc-shift; i++) {
        lua_pushstring(L, argv[i+shift]);
        lua_rawseti(L, -2, i);
    }
    lua_setglobal(L, "arg");
}

static void get_exe(const char *arg0, char *name, size_t name_size)
{
#ifdef __MINGW32__
    DWORD n = GetModuleFileName(NULL, name, name_size);
    if (n == 0) error(arg0, "Can not be found");
#else
    ssize_t n = readlink("/proc/self/exe", name, name_size);
    if (n < 0) perror(arg0);
#endif
    name[n] = '\0';
}

static int traceback(lua_State *L)
{
    const char *msg = lua_tostring(L, 1);
    luaL_traceback(L, L, msg, 1);
    fprintf(stderr, "%s\n", lua_tostring(L, -1));
    lua_pop(L, 1);
    return 0;
}

int main(int argc, const char *argv[])
{
    /* Lua payload extraction */
    char exe[1024];
    get_exe(argv[0], exe, sizeof(exe));
    FILE *f = fopen(exe, "rb");
    if (f == NULL) perror(exe);

    t_header header;
    char *chunk = NULL;
    int shift_args = 0;
    fseek(f, -(long)sizeof(header), SEEK_END);
    if (fread(&header, sizeof(header), 1, f) != 1) perror(argv[0]);
    if (header.magic_id != LAPP_MAGIC || header.header_size != sizeof(t_header))
    {
        /* The runtime does not contain any precompiled application */
        error(argv[0], "Lua application not found");
    }
    else
    {
        /* Read the precompiled application from the runtime */
        fseek(f, -(long)(header.chunk_size + sizeof(header)), SEEK_END);
        chunk = safe_malloc(header.chunk_size);
        if (fread(chunk, header.chunk_size, 1, f) != 1) perror(argv[0]);
        fclose(f);
    }

    for (size_t i = 1; i < header.chunk_size; i++)
    {
        chunk[i] += chunk[i-1];
    }

    /* Lua interpretor */
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    createargtable(L, argv, argc, shift_args);

    /* standard libraries */
    for (const luaL_Reg *lib = lrun_libs; lib->func != NULL; lib++)
    {
        luaL_requiref(L, lib->name, lib->func, 0);
        lua_pop(L, 1);
    }

    /* Lua payload execution */
    if (luaL_loadbuffer(L, chunk, header.chunk_size, NULL) != LUA_OK) error(argv[0], lua_tostring(L, -1));
    free(chunk);
    int base = lua_gettop(L);  /* function index */
    lua_pushcfunction(L, traceback); /* push message handler */
    lua_insert(L, base);  /* put it under function and args */
    int status = lua_pcall(L, 0, 0, base);
    lua_remove(L, base);  /* remove message handler from the stack */
    lua_close(L);
    return status;
}
