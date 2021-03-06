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

#include <libgen.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#include "lauxlib.h"
#include "lundump.h"

#include "header.h"
#include "lapp_version.h"
#include "lz4lib.h"
#include "tools.h"

#include "lz4hc.h"

#include "crypt-scripts.h"
#include "fs-scripts.h"
#include "lpeg-scripts.h"
#include "luasocketlib-scripts.h"
#include "lz4lib-scripts.h"
#include "ps-scripts.h"
#include "rl-scripts.h"
#include "std-scripts.h"
#include "sys-scripts.h"

#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)

#define WELCOME (                                                           \
    "Lua application compiler "LAPP_VERSION"\n"                             \
    "Copyright (C) 2021-2022 Christophe Delord (http://cdelord.fr/lapp)\n"  \
    "Based on "LUA_COPYRIGHT"\n"                                            \
    )

static const char *usage =
    "usage: lapp <main Lua script> [Lua libraries] -o <executable name>\n"
    "\n"
    "supported targets:\n"
#ifndef __MINGW32__
    "    " TOSTRING(KERNEL) "\t" TOSTRING(MACHINE) "\n"
#endif
#if HAS_MINGW
    "    " "Windows" "\t" TOSTRING(MACHINE) "\n"
#endif
    ;

static const lapp_Lib lapp_libs[] = {
    std_scripts,
    fs_scripts,
    ps_scripts,
    sys_scripts,
    lz4_scripts,
    lpeg_scripts,
    luasocket_scripts,
    crypt_scripts,
    rl_scripts,
    NULL,
};

#if !defined(__MINGW32__)
extern const unsigned char lrun_linux[];
extern const unsigned int lrun_linux_size;
#endif

#if defined(__MINGW32__) || HAS_MINGW
extern const unsigned char lrun_win[];
extern const unsigned int lrun_win_size;
#endif

typedef struct
{
    char *script_name;
    char *lib_name;
    char *source;
    char *chunk;
    size_t size;
    size_t allocated;
} t_chunk;

static const t_chunk empty_chunk =
{
    .script_name = NULL,
    .lib_name = NULL,
    .source = NULL,
    .chunk = NULL,
    .size = 0,
    .allocated = 0,
};

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
    const size_t required = buf->size + n + 1;
    if (required >= buf->allocated)
    {
        buf->allocated = 2*required;
        buf->data = safe_realloc(buf->data, buf->allocated);
    }
    strcpy(&buf->data[buf->size], s);
    buf->size += n;
}

#define toproto(L, i) getproto(s2v(L->top+(i)))

static int writer(lua_State *L __attribute__((unused)), const void *p, size_t size, void *u)
{
    t_chunk *chunk = u;
    if (size > 0)
    {
        const size_t required = chunk->size + size + 1;
        if (required >= chunk->allocated)
        {
            chunk->allocated = 2*required;
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
}

static void encode_chunk(t_chunk *chunk)
{
    for (size_t i = chunk->size; i > 0; i--)
    {
        chunk->chunk[i] -= chunk->chunk[i-1];
    }
}

static void chunk_free(t_chunk *chunk)
{
    if (chunk->script_name != NULL) free(chunk->script_name);
    if (chunk->lib_name != NULL) free(chunk->lib_name);
    if (chunk->chunk != NULL) free(chunk->chunk);
}

static size_t max(size_t a, size_t b)
{
    return a > b ? a : b;
}

static void log_chunk_size(size_t w, const char *name, size_t size)
{
    char fmt[64];
    sprintf(fmt, "%%-%zus: %%7zu bytes\n", w);
    printf(fmt, name, size);
}

int main(int argc, const char *argv[])
{
    printf("%s\n", WELCOME);

    if (argc <= 1) error(NULL, usage);

    const char *output = NULL;
    char *main_name = NULL;

    size_t nb_scripts = 0;
    size_t max_scripts = 0;
    const char **scripts = NULL;

    const unsigned char *lrun = NULL;
    size_t lrun_size = 0;
    bool add_std_lib = true;
    const char *target = "Unknown target";

    size_t w = 16;

    for (int i = 1; i < argc; i++)
    {
        if (strcmp(argv[i], "-o") == 0)
        {
            if (i >= argc-1) error(NULL, usage);
            output = argv[++i];
            if (strncasecmp(ext(output), ".exe", 4) == 0)
            {
#if defined(__MINGW32__) || HAS_MINGW
                lrun = lrun_win;
                lrun_size = lrun_win_size;
                target = "Windows";
                add_std_lib = true;
#else
                error(argv[0], "Windows target not supported");
#endif
            }
            else if (strncasecmp(ext(output), ".lc", 3) == 0)
            {
                lrun = NULL;
                lrun_size = 0;
                target = "Bytecode";
                add_std_lib = false;
            }
            else
            {
#if !defined(__MINGW32__)
                lrun = lrun_linux;
                lrun_size = lrun_linux_size;
                target = "Linux";
                add_std_lib = true;
#else
                error(argv[0], "Linux target not supported");
#endif
            }
            continue;
        }

        nb_scripts++;
        if (nb_scripts > max_scripts)
        {
            max_scripts = 2 * nb_scripts;
            scripts = safe_realloc(scripts, max_scripts*sizeof(const char *));
        }
        scripts[nb_scripts-1] = argv[i];
        w = max(w, strlen(argv[i])+1);
    }

    t_buffer b;
    buffer_init(&b);

    t_buffer autoload;
    buffer_init(&autoload);

    buffer_cat(&b, "local libs = {\n");
    /* insert standard library scripts first */
    if (add_std_lib)
    {
        size_t runtime_script_size = 0;
        for (int i = 0; lapp_libs[i] != NULL; i++)
        {
            lapp_Lib libs = lapp_libs[i];
            for (int j = 0; libs[j].chunk != NULL; j++)
            {
                const struct lrun_Reg *lib = &libs[j];
                buffer_cat(&b, lib->name);
                buffer_cat(&b, " = \"");
                for (unsigned int k = 0; k < *lib->size; k++)
                {
                    char c[5];
                    sprintf(c, "\\x%02X", lib->chunk[k]);
                    buffer_cat(&b, c);
                }
                buffer_cat(&b, "\",\n");
                runtime_script_size += *lib->size;
                if (lib->autoload)
                {
                    buffer_cat(&autoload, "require \"");
                    buffer_cat(&autoload, lib->name);
                    buffer_cat(&autoload, "\"\n");
                }
            }
        }
        log_chunk_size(w, "Runtime chunk", runtime_script_size);
        printf("\n");
    }

    /* then scripts from the command line */
    for (size_t i = 0; i < nb_scripts; i++)
    {
        t_chunk chunk = empty_chunk;
        chunk.script_name = safe_strdup(scripts[i]);
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
        chunk_free(&chunk);
        log_chunk_size(w, scripts[i], chunk.size);
    }
    if (main_name == NULL) error(NULL, usage);
    buffer_cat(&b, "}\n");
    buffer_cat(&b,
        "table.insert(package.searchers, 1, function(name)\n"
        "    local lib = libs[name]\n"
        "    return lib and function() return assert(load(lib, name, \"b\"))() end\n"
        "end)\n");
    buffer_cat(&b, autoload.data);
    buffer_cat(&b, "require \""); buffer_cat(&b, main_name); buffer_cat(&b, "\"\n");

    if (main_name != NULL) free(main_name);

    if (output != NULL)
    {
        printf("\n");
        printf("%s:\n", output);

        printf("    Target      : %s %s\n", target, TOSTRING(MACHINE));

        t_chunk main_chunk = empty_chunk;
        main_chunk.source = b.data;
        main_chunk.size = 0;
        compile_string(&main_chunk, 1);
        encode_chunk(&main_chunk);

        const t_header header =
        {
            .magic_id = LAPP_MAGIC,
            .header_size = sizeof(t_header),
            .magic_str = LAPP_SIGNATURE,
            .chunk_size = main_chunk.size,
        };
        FILE *f = fopen(output, "wb");
        if (lrun_size > 0) fwrite(lrun, sizeof(lrun[0]), lrun_size, f);
        fwrite(main_chunk.chunk, sizeof(main_chunk.chunk[0]), main_chunk.size, f);
        fwrite(&header, sizeof(header), 1, f);
        fclose(f);
        if (lrun_size > 0)
        {
            chmod(output, S_IRUSR|S_IWUSR|S_IXUSR|S_IRGRP|S_IXGRP|S_IROTH|S_IXOTH);
        }
        printf("    Header      : %7zu bytes\n", sizeof(header));
        printf("    Lua chunk   : %7zu bytes\n", main_chunk.size);
        printf("    Lua runtime : %7zu bytes\n", lrun_size);
        printf("    Total size  : %7zu bytes\n", lrun_size + main_chunk.size + sizeof(header));

        chunk_free(&main_chunk);
    }

    buffer_free(&b);

}
