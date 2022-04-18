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
-- lz4
---------------------------------------------------------------------

local lz4 = require "lz4"

local fun = require "fun"
local map = fun.map
local range = fun.range
local prefix = fun.prefix

return function()

    -- compressible string
    local x = table.concat(map(range(1, 10000), prefix"Lua is great "), " ")
    local y = lz4.compress(x)
    local z = lz4.compress_hc(x)
    assert(#y < #x)
    assert(#z < #x)
    assert(#z < #y)
    assert(lz4.decompress(y) == x)
    assert(lz4.decompress(z) == x)

    -- not compressible string
    local x = "Lua"
    local y = lz4.compress(x)
    local z = lz4.compress_hc(x)
    assert(#y > #x)
    assert(#z > #x)
    assert(z == y)
    assert(lz4.decompress(y) == x)
    assert(lz4.decompress(z) == x)

end

