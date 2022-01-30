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

-- arg is built by the runtime
print("arg = {"..table.concat(arg, ", ").."}")

-- embeded modules can be loaded with require
local lib = require "lib"
lib.hello "World"

-- ACME demonstration module
print "Test of the acme module (C & Lua)"
local acme = require "acme"
acme.launch()
local acmelua = require "acmelua"
acmelua.launch()

-- fun
local fun = require "fun"
do
    local k = fun.const(42, 43)
    local x, y = k(1000)
    assert(x == 42 and y == 43)
    x, y = fun.id(44, 45)
    assert(x == 44 and y == 45)
end
print("squares", table.concat(fun.map(function(x) return x*x end, fun.range(10)), ", "))
print("split", table.concat(("ab/cd/ef/"):split "/", ", "))
print("words", table.concat(("ab cd ef"):words(), ", "))

-- fs
assert(require "fs")

-- ps
assert(require "ps")

-- sys
assert(require "sys")

-- lz4
local lz4 = require "lz4"
do
    local x = "Lua is great\n"
    for i = 1, 10 do x = x..x end
    local y = lz4.compress(x)
    local z = lz4.compress_hc(x)
    assert(#y < #x)
    assert(#z < #x)
    assert(lz4.decompress(y) == x)
    assert(lz4.decompress(z) == x)
end

-- lpeg
assert(require "lpeg")
assert(require "re")
