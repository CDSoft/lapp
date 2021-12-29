#pragma once

#include <stdlib.h>

void error(const char *what, const char *message);

void *safe_malloc(size_t size);
void *safe_realloc(void *ptr, size_t size);
char *safe_strdup(const char *s);
