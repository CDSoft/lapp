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

-- Check the test environment first
require "test_test"()

-- lapp builtins
require "arg_test"()
require "require_test"()

-- lapp libraries
require "fun_test"()
require "string_test"()
require "sys_test"()
require "fs_test"()
require "ps_test"()
require "lz4_test"()
require "crypt_test"()
require "lpeg_test"()
require "socket_test"()
require "rl_test"()
