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

#pragma once

#include <lstate.h>

#include <stdlib.h>
#include <stdbool.h>

struct lrun_Reg
{
    const char *name;
    const unsigned char *chunk;
    const unsigned int *size;
    bool autoload;
};

typedef const struct lrun_Reg *lapp_Lib;

void error(const char *what, const char *message);

void *safe_malloc(size_t size);
void *safe_realloc(void *ptr, size_t size);
char *safe_strdup(const char *s);

const char *ext(const char *name);
void strip_ext(char *name);

int bl_pushresult(lua_State *L, int i, const char *filename);
int bl_pusherror(lua_State *L, const char *msg);
int bl_pusherror1(lua_State *L, const char *msg, const char *arg1);
int bl_pusherror2(lua_State *L, const char *msg, const char *arg1, int arg2);
