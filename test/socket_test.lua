--[[
This file is part of lapp.

lapp is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

lapp is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with lapp.  If not, see <https://www.gnu.org/licenses/>.

For further information about lapp you can visit
http://cdelord.fr/lapp
--]]

---------------------------------------------------------------------
-- luasocket
---------------------------------------------------------------------

local sys = require "sys"

return function()
    local socket = assert(require "socket")
    assert(require "socket.core")
    assert(require "socket.ftp")
    assert(require "socket.headers")
    local http = assert(require "socket.http")
    assert(require "socket.smtp")
    assert(require "socket.tp")
    assert(require "socket.url")
    if sys.platform == "Linux" then
        assert(require "socket.unix")
        assert(require "socket.serial")
    end
    assert(require "mime")
    assert(require "mime.core")
    assert(type(require "ftp") == "function")

    local t = assert(http.request"http://time.cdelord.fr/time.php")
    assert(math.abs(t - os.time() ) < 5*60)
    assert(math.abs(t - socket.gettime() ) < 5*60)
end

