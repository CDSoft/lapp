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

#include "luasocketlib.h"

#include "tools.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include "external/luasocket/src/luasocket.h"
#include "external/luasocket/src/mime.h"
#ifdef __MINGW32__
#else
#include "external/luasocket/src/unix.h"
extern LUASOCKET_API int luaopen_socket_serial(lua_State *L);
#endif

LUAMOD_API int luaopen_luasocket(lua_State *L)
{
    luaL_requiref(L, "socket.core", luaopen_socket_core, 0);
    luaL_requiref(L, "mime.core", luaopen_mime_core, 0);
#ifdef __MINGW32__
#else
    luaL_requiref(L, "socket.unix", luaopen_socket_unix, 0);
    luaL_requiref(L, "socket.serial", luaopen_socket_serial, 0);
#endif
    lua_pop(L, 1);
    return 0;
}
