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

#include "acme.h"

#include "tools.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

extern const unsigned char acmelua_chunk[];
extern const unsigned int acmelua_chunk_size;

static const struct lrun_Reg acmelua_scripts[] = {
    {"acmelua", acmelua_chunk, &acmelua_chunk_size, false},
    {NULL, NULL, NULL, false},
};

const struct lrun_Reg *acme_libs(void)
{
    return acmelua_scripts;
}

static int acme_launch(lua_State *L)
{
    (void)L;
    printf("3, 2, 1, boom!\n");
    return 0;
}

static const struct luaL_Reg acme[] = {
    {"launch", acme_launch},
    {NULL, NULL},
};

LUAMOD_API int luaopen_acme(lua_State *L)
{
    luaL_newlib(L, acme);
    return 1;
}
