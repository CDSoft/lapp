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

-- luasocket
assert(require "socket")
assert(require "socket.core")
assert(require "socket.ftp")
assert(require "socket.headers")
assert(require "socket.http")
assert(require "socket.smtp")
assert(require "socket.tp")
assert(require "socket.url")
if require "sys".platform == "Linux" then
    assert(require "socket.unix")
    assert(require "socket.serial")
end
assert(require "mime")
assert(require "mime.core")
assert(type(require "ftp") == "function")

local hamac_time = require "socket.http".request("http://hamac.dev/time.php")
assert(math.abs(hamac_time - os.time() ) < 5*60)

-- crypt
local crypt = require "crypt"
do
    local x = "foo"
    local y = crypt.hex.encode(x)
    assert(y == "666f6f")
    assert(crypt.hex.decode(y) == x)
end
do
    local x = "foo"
    local y = crypt.base64.encode(x)
    assert(y == "Zm9v")
    assert(crypt.base64.decode(y) == x)
end
do
    local x = "foo123456789\n"
    local y = crypt.crc32(x)
    assert(y == 0x3b13cda7)
end
do
    local x = "foobar!"
    local aes1 = crypt.AES("password", 128)
    local aes2 = crypt.AES("password", 128)
    local y1 = aes1.encrypt(x)
    local y2 = aes2.encrypt(x)
    local z1 = aes1.decrypt(y1)
    local z2 = aes2.decrypt(y2)
    assert(y1 ~= x)
    assert(y2 ~= x)
    assert(y1 ~= y2)
    assert(z1 == x)
    assert(z2 == x)
end
do
    local x = "foobar!"
    local btea_1 = crypt.BTEA("password")
    local btea_2 = crypt.BTEA("password")
    local y = btea_1.encrypt(x)
    local z = btea_2.decrypt(y)
    assert(y ~= x)
    assert(z:sub(1, #x) == x)
end
do
    local x = "foobar!"
    local rc4_1 = crypt.RC4("password", 4)
    local rc4_2 = crypt.RC4("password", 4)
    local y = rc4_1(x)
    local z = rc4_2(y)
    assert(y ~= x)
    assert(z == x)
end
