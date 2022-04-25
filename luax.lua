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

local function usage(wrong_arg)
    if wrong_arg then
        print(("luax: unrecognized option '%s'"):format(wrong_arg))
    end
    print [==[
usage: luax [options] [script [args]]
Available options are:
  -e stat  execute string 'stat'
  -i       enter interactive mode after executing 'script'
  -l name  require library 'name' into global 'name'
  -v       show version information
  --       stop handling options
  -        stop handling options and execute stdin
]==]
    os.exit(1)
end

local function print_version()
    print(("Lua eXtended - %s REPL powered by lapp %s (http://cdelord.fr/lapp)"):format(_VERSION, _LAPP_VERSION))
end

local function traceback(message)
    local trace = {"luax: "..message.."\n"}
    local luax = 0
    for _, line in ipairs(debug.traceback():lines()) do
        if line:match "^%s+luax.lua:" then luax = luax + 1
        elseif luax < 2 then table.insert(trace, line.."\n")
        end
    end
    table.remove(trace)
    io.stderr:write(table.concat(trace))
end

-- Read options

local interactive = #arg == 0

local function shift(n)
    n = n or 1
    for _ = 1, n do table.remove(arg, 1) end
end

while #arg > 0 do
    local a = arg[1]
    if a == '-e' then
        if #arg < 2 then usage(a) end
        local stat = arg[2]
        shift(2)
        local chunk, err = load(stat, "=(command line)")
        if not chunk then
            io.stderr:write(("%s: %s\n"):format(arg[0], err))
            os.exit(1)
        end
        local res = table.pack(xpcall(chunk, traceback))
        local ok = table.remove(res, 1)
        if ok then
            print(table.unpack(res))
        else
            os.exit(1)
        end
    elseif a == '-i' then
        interactive = true
        shift()
    elseif a == '-l' then
        if #arg < 2 then usage(a) end
        local lib = arg[2]
        _G[lib] = require(lib)
        shift(2)
    elseif a == '-v' then
        print_version()
        shift()
    elseif a == "--" then
        shift()
        break
    elseif a == "-" then
        break
    elseif a:match "^%-" then
        usage(a)
    else
        break
    end
end

-- run script

local function loadbytecode(fname)
    local f = assert(io.open(fname, "rb"))
    local bytes = f:read "a"
    f:close()
    local chunk_size, header_size, magic_id = string.unpack("=I8I8I8", bytes, #bytes+1-8*3)
    magic_id = string.unpack("z", string.pack("=I8", ~magic_id))
    assert(chunk_size+header_size == #bytes and magic_id == "LAPP;-)", fname..": invalid bytecode")
    local c0
    local chunk = string.unpack("c"..chunk_size, bytes):gsub(".", function(c)
        c0 = (c:byte() + (c0 or 0)) % 0x100
        return string.char(c0)
    end)
    return load(chunk, fname)
end

if #arg >= 1 then
    local luax = arg[0]
    local script = arg[1]
    shift()
    arg[0] = script == "-" and "stdin" or script
    local chunk, err
    if script == "-" then
        chunk, err = load(io.stdin:read "*a")
    elseif script:match "%.lc$" then
        chunk, err = loadbytecode(script)
    else
        chunk, err = loadfile(script)
    end
    if not chunk then
        io.stderr:write(("%s: %s\n"):format(script, err))
        os.exit(1)
    end
    local res = table.pack(xpcall(chunk, traceback))
    local ok = table.remove(res, 1)
    if ok then
        print(table.unpack(res))
    else
        os.exit(1)
    end
    arg[0] = luax
end

-- interactive REPL

if interactive then
    local rl = require "rl"
    local function try(input)
        local chunk, err = load(input, "=stdin")
        if not chunk then
            if err:match "<eof>$" then return "cont" end
            return nil, err
        end
        local res = table.pack(xpcall(chunk, traceback))
        local ok = table.remove(res, 1)
        if ok then
            if res ~= nil then print(table.unpack(res)) end
        else
            os.exit(1)
        end
        return "done"
    end
    print_version()
    while true do
        local inputs = {}
        local prompt = "> "
        while true do
            table.insert(inputs, rl.read(prompt))
            local input = table.concat(inputs, "\n")
            local try_expr, err_expr = try("return "..input)
            if try_expr == "done" then break end
            local try_stat, err_stat = try(input)
            if try_stat == "done" then break end
            if try_expr ~= "cont" and try_stat ~= "cont" then
                print(try_stat == nil and err_stat or err_expr)
                break
            end
            prompt = ">> "
        end
    end
end
