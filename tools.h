#pragma once

#include <stdlib.h>

void error(const char *what, const char *message);

void *safe_malloc(size_t size);
void *safe_realloc(void *ptr, size_t size);
char *safe_strdup(const char *s);

const char *last_index(const char *s, char c);
const char *ext(const char *name);
void strip_ext(char *name);
