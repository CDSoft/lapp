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

#include <errno.h>
#include <libgen.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#include "lauxlib.h"
#include "lstate.h"
#include "lundump.h"

#include "header.h"
#include "tools.h"
#include "lapp_version.h"

#include "lz4.h"
#include "lz4hc.h"

#define WELCOME ( "Lua application compiler "LAPP_VERSION"\n"                       \
                  "Copyright (C) 2021-2022 Christophe Delord (cdelord.fr/lapp)\n"   \
                  "Based on "LUA_COPYRIGHT"\n"                                      \
                )

static const char *usage = "usage: lapp <main Lua script> [Lua libraries] -o <executable name>";

#include "lrun_blob.c"

typedef struct
{
    char *script_name;
    char *lib_name;
    char *source;
    char *chunk;
    size_t size;
    size_t allocated;
    char *compressed_chunk;
    int compressed_size;
} t_chunk;

typedef struct
{
    char *data;
    size_t size;
    size_t allocated;
} t_buffer;

static void buffer_init(t_buffer *buf)
{
    buf->size = 0;
    buf->allocated = 4096;
    buf->data = safe_malloc(buf->allocated);
}

static void buffer_free(t_buffer *buf)
{
    if (buf->data != NULL) free(buf->data);
}

static void buffer_cat(t_buffer *buf, const char *s)
{
    const size_t n = strlen(s);
    if (buf->size + n + 1 >= buf->allocated)
    {
        while (buf->size + n + 1 >= buf->allocated)
        {
            buf->allocated *= 2;
        }
        buf->data = safe_realloc(buf->data, buf->allocated * sizeof(char));
    }
    strcpy(&buf->data[buf->size], s);
    buf->size += n;
}

static void strip_ext(char *name)
{
    for (size_t i = strlen(name); i > 0; i--)
    {
        if (name[i] == '.')
        {
            name[i] = '\0';
            break;
        }
    }
}

#define toproto(L, i) getproto(s2v(L->top+(i)))

static int writer(lua_State *L __attribute__((unused)), const void *p, size_t size, void *u)
{
    t_chunk *chunk = u;
    if (size > 0)
    {
        if (chunk->chunk == NULL)
        {
            chunk->allocated = 4096;
            chunk->chunk = safe_malloc(chunk->allocated);
        }
        if (chunk->size + size + 1 >= chunk->allocated)
        {
            while (chunk->size + size + 1 >= chunk->allocated)
            {
                chunk->allocated *= 2;
            }
            chunk->chunk = safe_realloc(chunk->chunk, chunk->allocated);
        }
        memcpy(&chunk->chunk[chunk->size], p, size);
        chunk->size += size;
    }
    return 0;
}

static void compile_file(t_chunk *chunk, int strip)
{
    lua_State *L = luaL_newstate();
    if (luaL_loadfile(L, chunk->script_name) != LUA_OK) error(chunk->script_name, lua_tostring(L, -1));
    const Proto* f = toproto(L, -1);
    lua_lock(L);
    luaU_dump(L, f, writer, chunk, strip);
    lua_unlock(L);
    lua_close(L);
    printf("    compiled chunk  : %6zu bytes\n", chunk->size);
}

static void compile_string(t_chunk *chunk, int strip)
{
    lua_State *L = luaL_newstate();
    if (luaL_loadstring(L, chunk->source) != LUA_OK) error("loader", lua_tostring(L, -1));
    const Proto* f = toproto(L, -1);
    lua_lock(L);
    luaU_dump(L, f, writer, chunk, strip);
    lua_unlock(L);
    lua_close(L);
    printf("    compiled chunk  : %6zu bytes\n", chunk->size);
}

static void compress_chunk(t_chunk *chunk)
{
    for (size_t i = chunk->size; i > 0; i--)
    {
        chunk->chunk[i] -= chunk->chunk[i-1];
    }
    const int max_size = LZ4_compressBound((int)chunk->size);
    chunk->compressed_chunk = safe_malloc((size_t)max_size);
    chunk->compressed_size = LZ4_compress_HC(
            chunk->chunk,
            chunk->compressed_chunk,
            (int)chunk->size,
            max_size,
            LZ4HC_CLEVEL_MAX);
    if (chunk->compressed_size < 0) error(chunk->script_name, "Can not compress Lua chunk");
    printf("    compressed chunk: %6d bytes\n", chunk->compressed_size);
}

int main(int argc, const char *argv[])
{
    printf("%s\n", WELCOME);

    if (argc <= 1) error(argv[0], usage);

    const char *output = NULL;
    char *main_name = NULL;

    t_buffer b;
    buffer_init(&b);

    buffer_cat(&b, "local libs = {\n");
    for (int i = 1; i < argc; i++)
    {
        if (strcmp(argv[i], "-o") == 0)
        {
            if (i >= argc-1) error(argv[0], usage);
            output = argv[++i];
            continue;
        }

        printf("%s:\n", argv[i]);

        t_chunk chunk;
        chunk.script_name = safe_strdup(argv[i]);
        chunk.lib_name = safe_strdup(basename(chunk.script_name));
        strip_ext(chunk.lib_name);
        chunk.source = NULL;
        chunk.chunk = NULL;
        chunk.size = 0;

        if (main_name == NULL) main_name = strdup(chunk.lib_name);

        compile_file(&chunk, 0);
        buffer_cat(&b, chunk.lib_name);
        buffer_cat(&b, " = \"");
        for (size_t j = 0; j < chunk.size; j++)
        {
            char c[5];
            sprintf(c, "\\x%02X", (unsigned char)chunk.chunk[j]);
            buffer_cat(&b, c);
        }
        buffer_cat(&b, "\",\n");
        free(chunk.script_name);
        free(chunk.lib_name);
        if (chunk.size > 0) free(chunk.chunk);
    }
    buffer_cat(&b, "}\n");
    buffer_cat(&b,
        "table.insert(package.searchers, 1, function(name)\n"
        "    local lib = libs[name]\n"
        "    return lib and function() return assert(load(lib, name, \"b\"))() end\n"
        "end)\n");
    buffer_cat(&b, "require \""); buffer_cat(&b, main_name); buffer_cat(&b, "\"\n");

    if (main_name != NULL) free(main_name);

    if (output != NULL)
    {
        printf("\n");
        printf("%s:\n", output);

        t_chunk main_chunk = {
            .source = b.data,
            .size = 0,
        };
        compile_string(&main_chunk, 1);
        compress_chunk(&main_chunk);

        const t_header header =
        {
            .magic = LAPP_SIGNATURE,
            .uncompressed_size = main_chunk.size,
            .compressed_size = (size_t)main_chunk.compressed_size,
        };
        FILE *f = fopen(output, "wb");
        fwrite(lrun, sizeof(lrun[0]), sizeof(lrun), f);
        fwrite(main_chunk.compressed_chunk, sizeof(main_chunk.chunk[0]), (size_t)main_chunk.compressed_size, f);
        fwrite(&header, sizeof(header), 1, f);
        fclose(f);
        chmod(output, S_IRUSR|S_IWUSR|S_IXUSR|S_IRGRP|S_IXGRP|S_IROTH|S_IXOTH);
        printf("    Header          : %6zu bytes\n", sizeof(header));
        printf("    Lua runtime     : %6zu bytes\n", sizeof(lrun));
        printf("    Total size      : %6zu bytes\n", sizeof(lrun) + (size_t)main_chunk.compressed_size + sizeof(header));
    }

    buffer_free(&b);

}
