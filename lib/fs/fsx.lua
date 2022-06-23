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

local flatten = require"fun".flatten

function fs.join(...)
    return table.concat({...}, fs.sep)
end

function fs.is_file(name)
    return fs.stat(name).type == "file"
end

function fs.is_dir(name)
    return fs.stat(name).type == "directory"

function fs.mkdirs(path)
    if fs.stat(path) then return end
    fs.mkdirs(fs.dirname(path))
    fs.mkdir(path)
end

-- fs.walk(path) iterates over the file names in path and its subdirectories
function fs.walk(path, reverse)
    if type(path) == "boolean" and reverse == nil then
        path, reverse = nil, path
    end
    local dirs = {path or "."}
    local acc_files = {}
    local acc_dirs = {}
    while #dirs > 0 do
        local dir = table.remove(dirs)
        local names = fs.dir(dir)
        if names then
            table.sort(names)
            for i = 1, #names do
                local name = dir..fs.sep..names[i]
                local stat = fs.stat(name)
                if stat then
                    if stat.type == "directory" then
                        dirs[#dirs+1] = name
                        if reverse then acc_dirs = {name, acc_dirs}
                        else acc_dirs[#acc_dirs+1] = name
                        end
                    else
                        acc_files[#acc_files+1] = name
                    end
                end
            end
        end
    end
    return flatten(reverse and {acc_files, acc_dirs} or {acc_dirs, acc_files})
end
