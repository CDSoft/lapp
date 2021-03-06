--[[ FTP library

Copyright (C) 2010-2022 Christophe Delord
http://cdelord.fr/bl
http://cdelord.fr/lapp

--]]

local socket = require "socket"

local function FTP(url, user, password)
    local ftp = {}
    local server = socket.url.parse(url)
    if user then server.user = user end
    if password then server.password = password end

    local open = socket.protect(function()
        local f = socket.ftp.open(server.host, server.port, server.create)
        f:greet()
        f:login(server.user, server.password)
        return f
    end)

    local f, err = open()
    if not f then return nil, err end

    ftp.close = socket.protect(function()
        f:quit()
        return f:close()
    end)

    ftp.cd = socket.protect(function(path)
        f:pasv()
        return f:cwd(path)
    end)

    ftp.pwd = socket.protect(function()
        f.try(f.tp:command("PWD"))
        local code, path = f.try(f.tp:check{257})
        if not code then return code, path end
        return (path:gsub('^[^"]*"(.*)"[^"]*$', "%1"))
    end)

    ftp.get = socket.protect(function(path)
        local t = {}
        f:pasv()
        f:receive{path=path, command="RETR", sink=ltn12.sink.table(t)}
        return table.concat(t)
    end)

    ftp.put = socket.protect(function(path, data)
        local partial = path..".part"
        f:pasv()
        local sent = f:send{path=partial, command="STOR", source=ltn12.source.string(data)}
        f:pasv()
        f.try(f.tp:command("RNFR", partial))
        f.try(f.tp:check{350})
        f.try(f.tp:command("RNTO", path))
        f.try(f.tp:check{250})
        return sent
    end)

    ftp.rm = socket.protect(function(path)
        f.try(f.tp:command("DELE", path))
        return f.try(f.tp:check{250})
    end)

    ftp.mkdir = socket.protect(function(path)
        f.try(f.tp:command("MKD", path))
        return f.try(f.tp:check{257})
    end)

    ftp.rmdir = socket.protect(function(path)
        f.try(f.tp:command("RMD", path))
        return f.try(f.tp:check{250})
    end)

    ftp.list = socket.protect(function(path)
        local t = {}
        f:pasv()
        f:receive{path=(path or "."), command="LIST", sink=ltn12.sink.table(t)}
        local files = {}
        for line in table.concat(t):gmatch("[^\r\n]+") do
            local dir, size, name = line:match "([d-])[rwx-]+%s+%d+%s+%w+%s+%w+%s+(%d+)%s+%w+%s+%w+%s+[%w:]+%s+(.*)"
            if not name:match("^%.%.?$") then
                if dir == "d" then table.insert(files, {name, dir})
                else table.insert(files, {name, tonumber(size)})
                end
            end
        end
        return files
    end)

    -- TODO: ftp.walk (as fs.walk)

    return ftp
end

return FTP
