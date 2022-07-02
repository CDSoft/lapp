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

#include "ps.h"

#include "tools.h"

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <math.h>
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

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

static int ps_sleep(lua_State *L)
{
    double t = luaL_checknumber(L, 1);
#ifdef __MINGW32__
    Sleep(1000 * t);
#else
    struct timeval timeout;
    double s;
    double us = modf(t, &s);
    timeout.tv_sec = (long int)s;
    timeout.tv_usec = (long int)(1e6*us);
    select(0, NULL, NULL, NULL, &timeout);
#endif
    return 0;
}

static const luaL_Reg pslib[] =
{
    {"sleep",       ps_sleep},
    {NULL, NULL}
};

LUAMOD_API int luaopen_ps (lua_State *L)
{
    luaL_newlib(L, pslib);
    return 1;
}
