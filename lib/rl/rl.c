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

#include "rl.h"

#include "tools.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

static const struct lrun_Reg rl_scripts[] = {
    {NULL, NULL, NULL, false},
};

const struct lrun_Reg *rl_libs(void)
{
    return rl_scripts;
}
#ifdef __MINGW32__

/* no readline package for Windows */

#else

#include <readline/readline.h>
#include <readline/history.h>

#endif

static int rl_read(lua_State* L)
{
    const char *prompt = lua_tostring(L, 1);
#ifdef __MINGW32__
    /* io.write(prompt) */
    lua_getglobal(L, "io");         /* push io */
    lua_getfield(L, -1, "write");   /* push io.write */
    lua_remove(L, -2);              /* remove io */
    lua_pushstring(L, prompt);      /* push prompt */
    lua_call(L, 1, 0);              /* call io.write(prompt) */
    /* return io.read "*l" */
    lua_getglobal(L, "io");         /* push io */
    lua_getfield(L, -1, "read");    /* push io.read */
    lua_remove(L, -2);              /* remove io */
    lua_pushstring(L, "*l");        /* push "*l" */
    lua_call(L, 1, 1);              /* call io.read("*l") */
    return 1;
#else
    char *line = readline(prompt);
    char *c;
    for (c = line; *c; c++)
        if (!isspace(*c))
        {
            add_history(line);
            break;
        }
    lua_pushstring(L, line);
    free(line);
    return 1;
#endif
}

static int rl_add(lua_State* L)
{
#ifdef __MINGW32__
    /* no readline history for Windows */
    (void)L;
#else
    const char *line = lua_tostring(L, 1);
    const char *c;
    for (c = line; *c; c++)
        if (!isspace(*c))
        {
            add_history(line);
            break;
        }
#endif
    return 0;
}

static const struct luaL_Reg rl[] = {
    {"read", rl_read},
    {"add",rl_add},
    {NULL, NULL},
};

LUAMOD_API int luaopen_rl(lua_State *L)
{
    luaL_newlib(L, rl);
    return 1;
}
