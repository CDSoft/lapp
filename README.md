# Lua Application packager

`lapp` packs Lua scripts together along with a Lua interpretor (Lua 5.4.3)
and produces a standalone executable for Linux and Windows.

`lapp` runs on Linux and produces Linux binaries.

`lapp.exe` runs on Windows or on Linux with Wine and produces Windows binaries.

No Lua interpretor needs to be installed. `lapp` contains its own interpretor.

## Installation

``` sh
$ make install    # install lapp and lapp.exe to ~/.local/bin
```

`lapp` and `lapp.exe` are single autonomous executables.
They do not need to be installed and can be copied anywhere you want.

## Usage

```
Usage: lapp [-o OUTPUT] script(s)

Options:
    -o OUTPUT   set the name of the output executable
```

The main script shall be the first one.
Other scripts are libraries that can be loaded by the main script.

## Examples

### Linux executable

```
lapp main.lua lib1.lua lib2.lua -o linux_executable
```

Running `linux_executable` is equivalent to running `lua main.lua`.

### Windows executable

Cross compilation from Linux:

```
wine lapp.exe main.lua lib1.lua lib2.lua -w -o windows_executable.exe
```

Native compilation from Windows:

```
lapp.exe main.lua lib1.lua lib2.lua -w -o windows_executable.exe
```

Running `windows_executable.exe` is equivalent to running `lua.exe main.lua`.

## License

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
