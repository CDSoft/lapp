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

local name = arg[1]
local input = arg[2]
local output = arg[3]

local bytes = {"const unsigned char ", name, "[] = {"}
local n = 0
assert(io.open(input, "rb"):read("a"):gsub(".", function(c)
    if n % 16 == 0 then table.insert(bytes, "\n") end
    n = n + 1
    table.insert(bytes, (" 0x%02X,"):format(c:byte()))
end))
if n % 16 ~= 1 then table.insert(bytes, "\n") end
table.insert(bytes, "};\n")

io.open(output, "wb"):write(table.concat(bytes))
