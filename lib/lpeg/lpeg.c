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

#include "lpeg.h"

#include "tools.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

extern const unsigned char re_chunk[];
extern const unsigned int re_chunk_size;

static const struct lrun_Reg lpeg_scripts[] = {
    {"re", re_chunk, &re_chunk_size, false},
    {NULL, NULL, NULL, false},
};

const struct lrun_Reg *lpeg_libs(void)
{
    return lpeg_scripts;
}
