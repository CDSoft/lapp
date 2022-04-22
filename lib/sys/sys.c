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

#include "sys.h"

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

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#define SYS_PATHSIZE 1024
#define SYS_BUFSIZE  (64*1024)

static int sys_hostname(lua_State *L)
{
    char name[SYS_PATHSIZE+1];
    if (gethostname(name, SYS_PATHSIZE)==0)
    {
        lua_pushstring(L, name);
    }
    else
    {
        return bl_pushresult(L, 0, "");
    }
    lua_pushstring(L, name);
    return 1;
}

static int sys_domainname(lua_State *L)
{
#ifdef __MINGW32__
    return bl_pusherror(L, "getdomainname not defined by mingw");
#else
    char name[SYS_PATHSIZE+1];
    if (getdomainname(name, SYS_PATHSIZE)==0)
    {
        lua_pushstring(L, name);
    }
    else
    {
        return bl_pushresult(L, 0, "");
    }
    return 1;
#endif
}

static int sys_hostid(lua_State *L)
{
#ifdef __MINGW32__
    return bl_pusherror(L, "gethostid not defined by mingw");
#else
    lua_pushinteger(L, gethostid());
    return 1;
#endif
}

static const luaL_Reg blsyslib[] =
{
    {"hostname",    sys_hostname},
    {"domainname",  sys_domainname},
    {"hostid",      sys_hostid},
    {NULL, NULL}
};

LUAMOD_API int luaopen_sys (lua_State *L)
{
    luaL_newlib(L, blsyslib);
#define STRING(NAME, VAL) lua_pushliteral(L, VAL); lua_setfield(L, -2, NAME)
#ifdef __MINGW32__
    STRING("platform", "Windows");
#else
    STRING("platform", "Linux");
#endif
#undef STRING
    return 1;
}
