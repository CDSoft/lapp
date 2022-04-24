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
-- embeded modules can be loaded with require
---------------------------------------------------------------------

return function()
    local lib = require "lib"
    local traceback = lib.hello "World":gsub("\t", "    ")
    local expected_traceback = [[
@test/lib.lua says: Hello World
Traceback test
stack traceback:
    test/lib.lua:25: in function 'lib.hello'
    test/require_test.lua:27: in function 'require_test'
    test/main.lua:26: in main chunk
    (...tail calls...)
    [C]: in function 'require'
    ?: in main chunk]]
    if arg[0]:match "%.lc$" then
        eq(traceback:sub(1, #expected_traceback), expected_traceback)
    else
        eq(traceback, expected_traceback)
    end
end
