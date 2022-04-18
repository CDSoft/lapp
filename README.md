# Lua Application packager

`lapp` packs Lua scripts together along with a Lua interpretor (Lua 5.4.4) and
produces a standalone executable for Linux and Windows.

`lapp` runs on Linux and `lapp.exe` on Windows.

`lapp` and `lapp.exe` can produce both Linux and Windows binaries.

No Lua interpretor needs to be installed. `lapp` contains its own interpretor.

`lapp` also comes with `luax` which bundles `lapp` with a Lua REPL.

## Compilation

Get `lapp` sources on GitHub: <https://github.com/CDSoft/lapp>, download
dependencies and submodules and run `make`:

```sh
$ git clone https://github.com/CDSoft/lapp
$ cd lapp
$ sudo make dep         # install make, gcc, readline, ...
$ make submodules       # retreive submodules (luasocket, lz4, ...)
$ make                  # compile and test
```

## Installation

``` sh
$ make install    # install lapp and luax to ~/.local/bin or ~/bin
$ make install PREFIX=/usr/bin  # install lapp and luax to /usr/bin
```

`lapp` and `luax` are single autonomous executables.
They do not need to be installed and can be copied anywhere you want.

`make install` only install Linux binaries and is not meant to be used on Windows.

## Precompiled binaries

It is usually highly recommended to build `lapp` from sources.
Precompiled binaries of the latest version are available here:

- Linux: [lapp-linux-x86_64.tar.gz](http://cdelord.fr/lapp/lapp-linux-x86_64.tar.gz)
- Raspberry Pi: [lapp-linux-aarch64.tar.gz](http://cdelord.fr/lapp/lapp-linux-aarch64.tar.gz)
- Windows: [lapp-win-x86_64.zip](http://cdelord.fr/lapp/lapp-win-x86_64.zip)

## Usage

```
Usage: lapp [-o OUTPUT] script(s)

Options:
    -o OUTPUT   set the name of the output executable
```

The main script shall be the first one.
Other scripts are libraries that can be loaded by the main script.

If `OUTPUT` ends with `.exe` then `lapp` produces a Windows binary.
Otherwise the output is assumed to be a Linux executable.

## Examples

| Host    | Target      | Command                                                            |
| ------- | ----------- | ------------------------------------------------------------------ |
| Linux   | Linux       | `lapp main.lua lib1.lua lib2.lua -o linux_executable`              |
| Linux   | Windows     | `lapp main.lua lib1.lua lib2.lua -o windows_executable.exe`        |
| Windows | Linux       | `lapp.exe main.lua lib1.lua lib2.lua -o linux_executable`          |
| Windows | Windows     | `lapp.exe main.lua lib1.lua lib2.lua -o windows_executable.exe`    |

Running `linux_executable` is equivalent to running `luax main.lua`.

Running `windows_executable.exe` is equivalent to running `luax.exe main.lua`.

## Dependencies

Building `lapp` requires some external softwares.

- [wget](https://www.gnu.org/software/wget/): to download the Lua sources
- [gcc](https://gcc.gnu.org/): used to compile Lua and `lapp` for Linux
- [MinGW-w64](https://www.mingw-w64.org/): Linux port of the Windows MinGW
  compiler used to compile the Windows version of `lapp.exe`
- [Wine](https://www.winehq.org/): used to test the Windows binaries on Linux
- and a decent programming environment on Linux...

## Built-in modules

The `lapp` runtime comes with a few builtin modules.

These modules are heavily inspired by [BonaLuna](http://cdelord.fr/bl).

### "Standard" library

```lua
local fun = require "fun"
```

**`fun.id(...)`{.lua}** is the identity function.

**`fun.const(...)`{.lua}** returns a constant function that returns `...`.

**`fun.keys(t)`{.lua}** returns a sorted list of keys from the table `t`.

**`fun.values(t)`{.lua}** returns a list of values from the table `t`, in the same order than `fun.keys(t)`{.lua}.

**`fun.pairs(t)`{.lua}** returns a `pairs`{.lua} like iterator, in the same order than `fun.keys(t)`{.lua}.

**`fun.concat(...)`{.lua}** returns a concatenated list from input lists.

**`fun.merge(...)`{.lua}** returns a merged table from input tables.

**`fun.flatten(...)`{.lua}** flattens input lists and non list parameters.

**`fun.compose(...)`{.lua}** returns a function that composes input functions.

**`fun.map(f, xs)`{.lua}** returns the list of `f(x)`{.lua} for all `x` in `xs`.

**`fun.filter(p, xs)`{.lua}** returns the list of `x` such that `p(x)`{.lua} is true.

**`fun.foreach(xs, f)`{.lua}** executes `f(x)`{.lua} for all `x` in `xs`.

**`fun.prefix(pre)`{.lua}** returns a function that adds a prefix `pre` to a string.

**`fun.suffix(suf)`{.lua}** returns a function that adds a suffix `suf` to a string.

**`fun.range(a, b [, step])`{.lua}** returns a list of values `[a, a+step, ... b]`. The default step value is 1.

**`fun.I(t)`{.lua}** returns a string interpolator that replaces `$(...)` by
the value of `...` in the environment defined by the table `t`. An interpolator
can be given another table to build a new interpolator with new values.

`lapp` adds a few functions to the builtin `string` module:

**`string.split(s, sep, maxsplit, plain)`{.lua}** splits `s` using `sep` as a separator.
If `plain` is true, the separator is considered as plain text.
`maxsplit` is the maximum number of separators to find (ie the remaining string is returned unsplit.
This function returns a list of strings.

**`string.lines(s)`{.lua}** splits `s` using '\n' as a separator.

**`string.words(s)`{.lua}** splits `s` using '%s' as a separator.

**`string.ltrim(s)`{.lua}, `string.rtrim(s)`{.lua}, `string.trim(s)`{.lua}** remove left/right/both end spaces

### fs: File System module

```lua
local fs = require "fs"
```

**`fs.getcwd()`{.lua}** returns the current working directory.

**`fs.chdir(path)`{.lua}** changes the current directory to `path`.

**`fs.dir([path])`{.lua}** returns the list of files and directories in
`path` (the default path is the current directory).

**`fs.walk([path], [reverse])`{.lua}** returns a list listing directory and
file names in `path` and its subdirectories (the default path is the current
directory). If `reverse` is true, the list is built in a reverse order
(suitable for recursive directory removal)

**`fs.mkdir(path)`{.lua}** creates a new directory `path`.

**`fs.rename(old_name, new_name)`{.lua}** renames the file `old_name` to
`new_name`.

**`fs.remove(name)`{.lua}** deletes the file `name`.

**`fs.copy(source_name, target_name)`{.lua}** copies file `source_name` to
`target_name`. The attributes and times are preserved.

**`fs.is_file(name)`** returns `true` if `name` is a file.

**`fs.is_dir(name)`** returns `true` if `name` is a directory.

**`fs.stat(name)`{.lua}** reads attributes of the file `name`.  Attributes are:

- `name`: name
- `type`: `"file"` or `"directory"`
- `size`: size in bytes
- `mtime`, `atime`, `ctime`: modification, access and creation times.
- `mode`: file permissions
- `uR`, `uW`, `uX`: user Read/Write/eXecute permissions (Linux only)
- `gR`, `gW`, `gX`: group Read/Write/eXecute permissions (Linux only)
- `oR`, `oW`, `oX`: other Read/Write/eXecute permissions (Linux only)
- `aR`, `aW`, `aX`: anybody Read/Write/eXecute permissions

**`fs.inode(name)`{.lua}** reads device and inode attributes of the file `name`.
Attributes are:

- `dev`, `ino`: device and inode numbers

**`fs.chmod(name, other_file_name)`{.lua}** sets file `name` permissions as
file `other_file_name` (string containing the name of another file).

**`fs.chmod(name, bit1, ..., bitn)`{.lua}** sets file `name` permissions as
`bit1` or ... or `bitn` (integers).

**`fs.touch(name)`{.lua}** sets the access time and the modification time of
file `name` with the current time.

**`fs.touch(name, number)`{.lua}** sets the access time and the modification
time of file `name` with `number`.

**`fs.touch(name, other_name)`{.lua}** sets the access time and the
modification time of file `name` with the times of file `other_name`.

**`fs.basename(path)`{.lua}** return the last component of path.

**`fs.dirname(path)`{.lua}** return all but the last component of path.

**`fs.absname(path)`{.lua}** return the absolute path name of path.

**`fs.join(...)`{.lua}** return a path name made of several path components
(separated by `fs.sep`).

**`fs.sep`{.lua}** is the directory separator (/ or \\).

**`fs.uR, fs.uW, fs.uX`{.lua}** are the User Read/Write/eXecute mask for
`fs.chmod`.

**`fs.gR, fs.gW, fs.gX`{.lua}** are the Group Read/Write/eXecute mask for
`fs.chmod`.

**`fs.oR, fs.oW, fs.oX`{.lua}** are the Other Read/Write/eXecute mask for
`fs.chmod`.

**`fs.aR, fs.aW, fs.aX`{.lua}** are All Read/Write/eXecute mask for `fs.chmod`.

### ps: Process management module

```lua
local ps = require "ps"
```

**`ps.sleep(n)`{.lua}** sleeps for `n` seconds.

### sys: System module

```lua
local sys = require "sys"
```

**`sys.hostname()`{.lua}** returns the host name.

**`sys.domainname()`{.lua}** returns the domain name.

**`sys.hostid()`{.lua}** returns the host id.

**`sys.platform`{.lua}** is `"Linux"` or `"Windows"`

### lz4: compression module

```lua
local lz4 = require "lz4"
```

**`lz4.compress(data)`{.lua}** compresses `data` with LZ4 and returns the
compressed string.

**`lz4.compress_hc(data)`{.lua}** compresses `data` with LZ4HC and returns the
compressed string.

**`lz4.decompress(data)`{.lua}** decompresses `data` with LZ4 and returns the
decompressed string.

### crypt: cryptography module

```lua
local crypt = require "crypt"
```

**Warning**: the `crypt` package is a pure Lua package (i.e. not really fast).

**`crypt.hex.encode(data)`{.lua}** encodes `data` in hexa.

**`crypt.hex.decode(data)`{.lua}** decodes the hexa `data`.

**`crypt.base64.encode(data)`{.lua}** encodes `data` in base64.

**`crypt.base64.decode(data)`{.lua}** decodes the base64 `data`.

**`crypt.crc32(data)`{.lua}** computes the CRC32 of `data`.

**`crypt.AES(password [,keylen [,mode] ])`{.lua}** returns an AES codec.
`password` is the encryption/decryption key, `keylen` is the length of the key
(128 (default), 192 or 256), `mode` is the encryption/decryption mode ("cbc"
(default) or "ecb"). `crypt.AES` objects have two methods: `encrypt(data)` and
`decrypt(data)`.

**`crypt.BTEA(password)`{.lua}** returns a BTEA codec (a tiny cipher with
reasonable security and efficiency, see http://en.wikipedia.org/wiki/XXTEA).
`password` is the encryption/decryption key (only the first 16 bytes are used).
`crypt.BTEA` objects have two methods: `encrypt(data)` and `decrypt(data)`.
BTEA encrypts 32-bit words so the length of data should be a multiple of 4 (if
not, BTEA will add null padding at the end of data).

**`crypt.RC4(password, drop)`{.lua}** return a RC4 codec (a popular stream
cypher, see http://en.wikipedia.org/wiki/RC4). `password` is the
encryption/decryption key. `drop` is the numbre of bytes ignores before
encoding (768 by default). `crypt.RC4` returns the encryption/decryption
function.

**`crypt.random(bits)`{.lua}** returns a string with `bits` random bits.

### lpeg: Parsing Expression Grammars For Lua

LPeg is a pattern-matching library for Lua.

```lua
local lpeg = require "lpeg"
local re = require "re"
```

The documentation of these modules are available on Lpeg web site:

- [Lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/)
- [Re](http://www.inf.puc-rio.br/~roberto/lpeg/re.html)

### luasocket: Network support for the Lua language

```lua
local socket = require "socket"
```

The socket package is based on [Lua
Socket](http://w3.impa.br/~diego/software/luasocket/) and adapted for `lapp`.

The documentation of `Lua Socket` is available at the [Lua Socket documentation
web site](http://w3.impa.br/~diego/software/luasocket/reference.html).

`lapp` provides an additional package for higher level FTP functionalities:

```lua
local ftp = require "ftp" -- ftp is a function
```

**ftp(url [, login, password])** creates an FTP object to connect to
the FTP server at `url`. `login` and `password` are optional.
Methods are:

- `cd(path)` changes the current working directory.

- `pwd()` returns the current working directory.

- `get(path)` retrieves `path`.

- `put(path, data)` sends and stores the string `data` to the file `path`.

- `rm(path)` deletes the file `path`.

- `mkdir(path)` creates the directory `path`.

- `rmdir(path)` deletes the directory `path`.

- `list(path)` returns an iterator listing the directory `path`.

### rl: readline

The rl (readline) package was initially inspired by
[ilua](https://github.com/ilua)
and adapted for lapp.

**rl.read(prompt)** prints `prompt` and returns the string entered by the user.

**rl.add(line)** adds `line` to the readline history (Linux only).

## License

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

`lapp` uses other third party softwares:

* **[Lua 5.4](http://www.lua.org)**: Copyright (C) 1994-2022 Lua.org, PUC-Rio
  ([MIT license](http://www.lua.org/license.html))
* **[Lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/)**: Parsing Expression Grammars For Lua
  ([MIT license](http://www.lua.org/license.html))
* **[luasocket](https://github.com/diegonehab/luasocket)**: Network support for the Lua language
  ([LuaSocket 3.0 license](https://github.com/diegonehab/luasocket/blob/master/LICENSE))
* **[LZ4](https://github.com/lz4/lz4)**: Extremely Fast Compression algorithm
  ([BSD license](https://github.com/lz4/lz4/blob/dev/LICENSE))
