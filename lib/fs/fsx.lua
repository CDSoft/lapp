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

local fs = require "fs"

function fs.join(...)
    return table.concat({...}, fs.sep)
end

-- fs.walk(path) iterates over the file names in path and its subdirectories
function fs.walk(path)
    local dirs = {path or "."}
    local files = {}
    return function()
        if #files > 0 then
            return table.remove(files, 1)
        elseif #dirs > 0 then
            local dir = table.remove(dirs)
            local names = fs.dir(dir)
            if names then
                table.sort(names)
                for i = 1, #names do
                    local name = dir..fs.sep..names[i]
                    local stat = fs.stat(name)
                    if stat then
                        if stat.type == "directory" then
                            table.insert(dirs, name)
                        else
                            table.insert(files, name)
                        end
                    end
                end
                return dir
            end
        end
    end
end
