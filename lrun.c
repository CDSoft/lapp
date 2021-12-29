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

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#include "header.h"

__attribute__((noreturn))
static void fatal(const char* message)
{
    fprintf(stderr,"%s\n", message);
    exit(EXIT_FAILURE);
}

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
    FILE *f = fopen(argv[0], "rb");
    assert(f != NULL);
    t_header header;
    fseek(f, 0, SEEK_END);
    const long end = ftell(f) - (long)sizeof(header);
    fseek(f, end, SEEK_SET);
    assert(fread(&header, sizeof(header), 1, f) == 1);
    if (memcmp(header.magic, MAGIC, sizeof(header.magic)) != 0)
    {
        fprintf(stderr, "%s: No Lua application found\n", argv[0]);
        exit(EXIT_FAILURE);
    }
    fseek(f, (long)header.start, SEEK_SET);
    char *chunk = malloc(header.size);
    assert(chunk != NULL);
    assert(fread(chunk, header.size, 1, f) == 1);
    fclose(f);

    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    createargtable(L, argv, argc);
    if (luaL_loadbuffer(L, chunk, header.size, NULL) != LUA_OK) fatal(lua_tostring(L, -1));
    free(chunk);
    if (lua_pcall(L, 0, LUA_MULTRET, 0) != LUA_OK) fatal(lua_tostring(L, -1));
    lua_close(L);
}
