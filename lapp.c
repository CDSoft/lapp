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

#include <assert.h>
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

static const char *usage = "usage: lapp <main Lua script> [Lua libraries]";

#include "lrun_blob.c"

typedef struct
{
    char *script_name;
    char *lib_name;
    char *source;
    unsigned char *chunk;
    size_t size;
    size_t allocated;
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
    buf->data = malloc(buf->allocated);
}

static void buffer_free(t_buffer *buf)
{
    if (buf->data != NULL) free(buf->data);
}

static void buffer_cat(t_buffer *buf, const char *s)
{
    const size_t n = strlen(s);
    while (buf->size + n + 1 >= buf->allocated)
    {
        buf->allocated *= 2;
        buf->data = realloc(buf->data, buf->allocated * sizeof(char));
        assert(buf->data != NULL);
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

__attribute__((noreturn))
static void fatal(const char* message)
{
    fprintf(stderr,"%s\n", message);
    exit(EXIT_FAILURE);
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
            chunk->chunk = malloc(chunk->allocated);
        }
        while (chunk->size + size + 1 >= chunk->allocated)
        {
            chunk->allocated *= 2;
            chunk->chunk = (unsigned char *)realloc(chunk->chunk, chunk->allocated);
            assert(chunk->chunk != NULL);
        }
        memcpy(&chunk->chunk[chunk->size], p, size);
        chunk->size += size;
    }
    return 0;
}

static void compile_file(t_chunk *chunk, int strip)
{
    lua_State *L = luaL_newstate();
    if (luaL_loadfile(L, chunk->script_name) != LUA_OK) fatal(lua_tostring(L, -1));
    const Proto* f = toproto(L, -1);
    lua_lock(L);
    luaU_dump(L, f, writer, chunk, strip);
    lua_unlock(L);
    lua_close(L);
}

static void compile_string(t_chunk *chunk, int strip)
{
    lua_State *L = luaL_newstate();
    if (luaL_loadstring(L, chunk->source) != LUA_OK) fatal(lua_tostring(L, -1));
    const Proto* f = toproto(L, -1);
    lua_lock(L);
    luaU_dump(L, f, writer, chunk, strip);
    lua_unlock(L);
    lua_close(L);
}

int main(int argc, const char *argv[])
{
    printf("Lua application compiler\n");

    if (argc <= 1) fatal(usage);

    //size_t nb_chunks = 0;
    //t_chunk *chunks = NULL;
    const char *output = NULL;
    char *main_name = NULL;

    t_buffer b;
    buffer_init(&b);

    buffer_cat(&b, "local libs = {\n");
    for (int i = 1; i < argc; i++)
    {
        if (strcmp(argv[i], "-o") == 0)
        {
            if (i >= argc-1) fatal(usage);
            output = argv[++i];
            continue;
        }

        printf("Compiling %s\n", argv[i]);

        //nb_chunks++;
        //chunks = (t_chunk *)realloc(chunks, nb_chunks * sizeof(t_chunk));
        //assert(chunks != NULL);

        //t_chunk *chunk = &chunks[nb_chunks-1];
        t_chunk chunk;
        chunk.script_name = strdup(argv[i]);
        assert(chunk.script_name != NULL);
        chunk.lib_name = strdup(basename(chunk.script_name));
        assert(chunk.lib_name != NULL);
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
            sprintf(c, "\\x%02X", chunk.chunk[j]);
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
        "    if lib ~= nil then\n"
        "        return function()\n"
        "            return assert(load(lib, name, \"b\"))()\n"
        "        end\n"
        "    end\n"
        "end)\n");
    buffer_cat(&b, "require \""); buffer_cat(&b, main_name); buffer_cat(&b, "\"\n");

    if (main_name != NULL) free(main_name);

    printf("Linking all chunks\n");
    t_chunk main_chunk = {
        .source = b.data,
        .size = 0,
    };
    compile_string(&main_chunk, 1);

    if (output != NULL)
    {
        printf("Writing %s\n", output);
        const t_header header =
        {
            .magic = MAGIC,
            .start = lrun_len,
            .size = main_chunk.size,
        };
        FILE *f = fopen(output, "wb");
        fwrite(lrun, sizeof(lrun[0]), lrun_len, f);
        fwrite(main_chunk.chunk, sizeof(main_chunk.chunk[0]), main_chunk.size, f);
        fwrite(&header, sizeof(header), 1, f);
        fclose(f);
        chmod(output, S_IRUSR|S_IWUSR|S_IXUSR|S_IRGRP|S_IXGRP|S_IROTH|S_IXOTH);
    }

    buffer_free(&b);

}
