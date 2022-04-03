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
-- ps
---------------------------------------------------------------------

local ps = require "ps"

local socket = require "socket"

local function sleep_test(n)
    local t0 = socket.gettime()
    ps.sleep(n)
    local t1 = socket.gettime()
    local dt = t1 - t0
    assert(n <= dt and dt <= n+0.001)
end

return function()
    sleep_test(0)
    sleep_test(0.142)
end
