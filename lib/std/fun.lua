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

local fun = {}

function fun.id(...)
    return ...
end

function fun.const(...)
    local res = {...}
    return function() return table.unpack(res) end
end

function fun.keys(t)
    local ks = {}
    for k,_ in pairs(t) do table.insert(ks, k) end
    table.sort(ks)
    return ks
end

function fun.values(t)
    local vs = {}
    for _,v in fun.pairs(t) do table.insert(vs, v) end
    return vs
end

function fun.pairs(t)
    local ks = fun.keys(t)
    local i = 1
    return function()
        if i <= #ks then
            local k = ks[i]
            local v = t[k]
            i = i+1
            return k, v
        end
    end
end

function fun.concat(...)
    local t = {}
    for i = 1, select("#", ...) do
        local ti = select(i, ...)
        for _, v in ipairs(ti) do table.insert(t, v) end
    end
    return t
end

function fun.merge(...)
    local t = {}
    for i = 1, select("#", ...) do
        local ti = select(i, ...)
        for k, v in pairs(ti) do t[k] = v end
    end
    return t
end

function fun.flatten(...)
    local xs = {}
    local function f(...)
        for i = 1, select("#", ...) do
            local x = select(i, ...)
            if type(x) == "table" then
                f(table.unpack(x))
            else
                table.insert(xs, x)
            end
        end
    end
    f(...)
    return xs
end

function fun.compose(...)
    local n = select("#", ...)
    local fs = {...}
    local function apply(i, ...)
        if i > 0 then return apply(i-1, fs[i](...)) end
        return ...
    end
    return function(...)
        return apply(n, ...)
    end
end

function fun.map(f, xs)
    if type(f) == "table" and type(xs) == "function" then f, xs = xs, f end
    local ys = {}
    for i, x in ipairs(xs) do table.insert(ys, (f(x, i))) end
    return ys
end

function fun.filter(p, xs)
    if type(p) == "table" and type(xs) == "function" then p, xs = xs, p end
    local ys = {}
    for i, x in ipairs(xs) do
        if p(x, i) then table.insert(ys, x) end
    end
    return ys
end

function fun.foreach(xs, f)
    if type(f) == "table" and type(xs) == "function" then f, xs = xs, f end
    for i, x in ipairs(xs) do f(x, i) end
end

function fun.prefix(pre)
    return function(s) return pre..s end
end

function fun.suffix(suf)
    return function(s) return s..suf end
end

function fun.range(a, b, step)
    assert(step ~= 0, "range step can not be zero")
    if not b then a, b = 1, a end
    step = step or (a < b and 1) or (a > b and -1)
    local r = {}
    if a < b then
        assert(step > 0, "step shall be positive")
        while a <= b do
            table.insert(r, a)
            a = a + step
        end
    elseif a > b then
        assert(step < 0, "step shall be negative")
        while a >= b do
            table.insert(r, a)
            a = a + step
        end
    else
        table.insert(r, a)
    end
    return r
end

function fun.memo(f)
    local cache = {}
    return function(x)
        local y = cache[x]
        if y == nil then
            y = f(x)
            cache[x] = y
        end
        return y
    end
end

local function interpolate(s, t)
    return (s:gsub("%$(%b())", function(x)
        return (assert(load("return "..x, nil, "t", t)))()
    end))
end

local function Interpolator(t)
    return function(x)
        if type(x) == "table" then return Interpolator(fun.merge(t, x)) end
        if type(x) == "string" then return interpolate(x, t) end
    end
end

function fun.I(t)
    return Interpolator(fun.merge(t))
end

return fun
