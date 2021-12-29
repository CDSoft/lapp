/* This file is part of lapp.
 *
 * lapp is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * lapp is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with lapp.  If not, see <https://www.gnu.org/licenses/>.
 *
 * For further information about lapp you can visit
 * http://cdelord.fr/lapp
 */

/* A compiled Lua application is made of three parts:
 *  - Lua runtime (see lrun.c)
 *  - compiled and compressed Lua chunk
 *  - header describing the Lua chunk
 *
 *  +-----------------------------------+
 *  | Lua runtime (lrun.c)              |
 *  |                                   |
 *  |                                   |
 *  +-----------------------------------+  <--+
 *  | Lua chunk                         |     |
 *  | compiled with luaU_dump           |     |
 *  | compressed with LZ4               |     |
 *  |                                   |     |
 *  |                                   |     |
 *  |                                   |     |
 *  +-----------------------------------+  <--+
 *  | header                            |     |
 *  | .compressed_size: size of the     | ----+
 *  |       Lua chunk in the file       |
 *  | .uncompressed_size: size of the   |
 *  |       Lua chunk after             |
 *  |       decompression               |
 *  | .magic: lapp signature            |
 *  +-----------------------------------+
 */

#pragma once

#include <stdlib.h>

#include "lapp_version.h"

#define LAPP_SIGNATURE "\x1b" "Compiled with lapp "LAPP_VERSION" (http://cdelord.fr/lapp)" "\0"

typedef struct __attribute__((packed))
{
    size_t compressed_size;
    size_t uncompressed_size;
    char magic[sizeof(LAPP_SIGNATURE)-1];
} t_header;
