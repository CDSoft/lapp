#include "tools.h"

#include <stdio.h>
#include <string.h>

__attribute__((noreturn))
void error(const char *what, const char *message)
{
    fprintf(stderr,"%s: %s\n", what, message);
    exit(EXIT_FAILURE);
}

static inline void *check_ptr(void *ptr)
{
    if (ptr == NULL)
    {
        fprintf(stderr, "Memory allocation error\n");
        exit(EXIT_FAILURE);
    }
    return ptr;
}

void *safe_malloc(size_t size)
{
    return check_ptr(malloc(size));
}

void *safe_realloc(void *ptr, size_t size)
{
    return check_ptr(realloc(ptr, size));
}

char *safe_strdup(const char *s)
{
    return check_ptr(strdup(s));
}
