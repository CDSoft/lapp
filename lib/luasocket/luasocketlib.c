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

extern const unsigned char ftp_chunk[];
extern const unsigned int ftp_chunk_size;
extern const unsigned char headers_chunk[];
extern const unsigned int headers_chunk_size;
extern const unsigned char http_chunk[];
extern const unsigned int http_chunk_size;
extern const unsigned char ltn12_chunk[];
extern const unsigned int ltn12_chunk_size;
extern const unsigned char mbox_chunk[];
extern const unsigned int mbox_chunk_size;
extern const unsigned char mime_chunk[];
extern const unsigned int mime_chunk_size;
extern const unsigned char smtp_chunk[];
extern const unsigned int smtp_chunk_size;
extern const unsigned char socket_chunk[];
extern const unsigned int socket_chunk_size;
extern const unsigned char tp_chunk[];
extern const unsigned int tp_chunk_size;
extern const unsigned char url_chunk[];
extern const unsigned int url_chunk_size;

static const struct lrun_Reg luasocket_scripts[] = {
    {"socket", socket_chunk, &socket_chunk_size, false},
    {"['socket.ftp']", ftp_chunk, &ftp_chunk_size, false},
    {"['socket.headers']", headers_chunk, &headers_chunk_size, false},
    {"['socket.http']", http_chunk, &http_chunk_size, false},
    {"['socket.smtp']", smtp_chunk, &smtp_chunk_size, false},
    {"['socket.tp']", tp_chunk, &tp_chunk_size, false},
    {"['socket.url']", url_chunk, &url_chunk_size, false},
    {"ltn12", ltn12_chunk, &ltn12_chunk_size, false},
    {"mbox", mbox_chunk, &mbox_chunk_size, false},
    {"mime", mime_chunk, &mime_chunk_size, false},
    {NULL, NULL, NULL, false},
};

const struct lrun_Reg *luasocket_libs(void)
{
    return luasocket_scripts;
}

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
