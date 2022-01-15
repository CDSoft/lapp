# Lua Application packager

`lapp` packs Lua scripts together along with a Lua interpretor (Lua 5.4.3) and
produces a standalone executable for Linux and Windows.

`lapp` runs on Linux and `lapp.exe` on Windows.

`lapp` and `lapp.exe` can produce both Linux and Windows binaries.

No Lua interpretor needs to be installed. `lapp` contains its own interpretor.

## Compilation

Get `lapp` sources on GitHub: <https://gitbuh.com/CDSoft/lapp>, download
submodules and run `make`:

```sh
$ git clone https://github.com/CDSoft/lapp
$ cd lapp
$ git submodule sync && git submodule update --init --recursive
$ make
```

## Installation

``` sh
$ make install    # install lapp and lapp.exe to ~/.local/bin
```

`lapp` and `lapp.exe` are single autonomous executables.
They do not need to be installed and can be copied anywhere you want.

## Precompiled binaries

It is usually highly recommended to build `lapp` from sources.
Precompiled binaries of the latest version are available here:

- Linux: [lapp](http://cdelord.fr/lapp/lapp)
- Windows: [lapp.exe](http://cdelord.fr/lapp/lapp.exe)

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

Running `linux_executable` is equivalent to running `lua main.lua`.

Running `windows_executable.exe` is equivalent to running `lua.exe main.lua`.

## Dependencies

`lapp` requires some external softwares. Some are included in its repository.

- [wget](https://www.gnu.org/software/wget/): to download the Lua sources
- [Lua 5.4.3](https://lua.org): the sources of Lua are downloaded by Makefile
  when `lapp` is compiled
- [LZ4](https://github.com/lz4/lz4): the LZ4 compression library is a submodule
  of `lapp`
- [gcc](https://gcc.gnu.org/): used to compile Lua and `lapp` for Linux
- [MinGW-w64](https://www.mingw-w64.org/): Linux port of the Windows MinGW
  compiler used to compile the Windows version of `lapp.exe`
- [Wine](https://www.winehq.org/): used to test the Windows binaries on Linux
- and a decent programming environment on Linux...

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
