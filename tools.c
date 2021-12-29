#include "tools.h"

#include <stdio.h>
#include <string.h>

__attribute__((noreturn))
void error(const char *what, const char *message)
{
    fprintf(stderr,"%s: %s\n", what, message);
    exit(EXIT_FAILURE);
}

void *safe_malloc(size_t size)
{
    void *ptr = malloc(size);
    if (ptr == NULL)
    {
        fprintf(stderr, "Memory allocation error\n");
        exit(EXIT_FAILURE);
    }
    return ptr;
}

void *safe_realloc(void *ptr, size_t size)
{
    ptr = realloc(ptr, size);
    if (ptr == NULL)
    {
        fprintf(stderr, "Memory allocation error\n");
        exit(EXIT_FAILURE);
    }
    return ptr;
}

char *safe_strdup(const char *s)
{
    char *ptr = strdup(s);
    if (ptr == NULL)
    {
        fprintf(stderr, "Memory allocation error\n");
        exit(EXIT_FAILURE);
    }
    return ptr;
}
