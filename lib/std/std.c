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

#include "std.h"

#include "tools.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

extern const unsigned char fun_chunk[];
extern const unsigned int fun_chunk_size;

extern const unsigned char stringx_chunk[];
extern const unsigned int stringx_chunk_size;

static const struct lrun_Reg std_scripts[] = {
    {"fun", fun_chunk, &fun_chunk_size, false},
    {"stringx", stringx_chunk, &stringx_chunk_size, true},
    {NULL, NULL, NULL, false},
};

const struct lrun_Reg *std_libs(void)
{
    return std_scripts;
}

LUAMOD_API int luaopen_std(lua_State *L)
{
    (void)L;
    return 0;
}
