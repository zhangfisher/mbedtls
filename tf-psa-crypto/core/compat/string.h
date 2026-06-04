#ifndef TF_PSA_CRYPTO_COMPAT_STRING_H
#define TF_PSA_CRYPTO_COMPAT_STRING_H

#include <stdint.h>
#include <stddef.h>

// 基本内存操作函数
static inline void* memcpy(void* dest, const void* src, size_t n) {
    return __builtin_memcpy(dest, src, n);
}

static inline void* memmove(void* dest, const void* src, size_t n) {
    return __builtin_memmove(dest, src, n);
}

static inline void* memset(void* s, int c, size_t n) {
    return __builtin_memset(s, c, n);
}

static inline int memcmp(const void* s1, const void* s2, size_t n) {
    return __builtin_memcmp(s1, s2, n);
}

static inline size_t strlen(const char* s) {
    return __builtin_strlen(s);
}

static inline char* strcpy(char* dest, const char* src) {
    return __builtin_strcpy(dest, src);
}

static inline char* strcat(char* dest, const char* src) {
    return __builtin_strcat(dest, src);
}

static inline int strcmp(const char* s1, const char* s2) {
    return __builtin_strcmp(s1, s2);
}

static inline int strncmp(const char* s1, const char* s2, size_t n) {
    return __builtin_strncmp(s1, s2, n);
}

#endif // TF_PSA_CRYPTO_COMPAT_STRING_H
