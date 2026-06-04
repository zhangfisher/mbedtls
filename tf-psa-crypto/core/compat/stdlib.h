#ifndef TF_PSA_CRYPTO_COMPAT_STDLIB_H
#define TF_PSA_CRYPTO_COMPAT_STDLIB_H

#include <stddef.h>

// 内存分配函数声明
void* malloc(size_t size);
void* calloc(size_t nmemb, size_t size);
void* realloc(void *ptr, size_t size);
void free(void *ptr);

#endif // TF_PSA_CRYPTO_COMPAT_STDLIB_H
