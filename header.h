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
 *  |                                   |     |
 *  |                                   |     |
 *  |                                   |     |
 *  |                                   |     |
 *  +-----------------------------------+  <--+
 *  | header                            |     |
 *  | .chunk_size: size of the          | ----+
 *  |       Lua chunk                   |
 *  | .magic_str: lapp signature        |
 *  | .header_size: size of this header |
 *  | .magic_id: lapp magic             |
 *  +-----------------------------------+
 */

#pragma once

#include <stdint.h>
#include <stdlib.h>

#include "lapp_version.h"

#define LAPP_MAGIC     (~0x292D3B5050414CULL)
#define LAPP_SIGNATURE "\x1b" "Compiled with lapp "LAPP_VERSION" (http://cdelord.fr/lapp)" "\0"

typedef struct __attribute__((packed))
{
    char magic_str[sizeof(LAPP_SIGNATURE)-1];
    size_t chunk_size;
    size_t header_size;
    uint64_t magic_id;
} t_header;
