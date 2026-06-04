#ifndef TF_PSA_CRYPTO_COMPAT_STDIO_H
#define TF_PSA_CRYPTO_COMPAT_STDIO_H

#include <stddef.h>
#include <stdarg.h>

// 基本类型定义（FILE 类型，避免与系统定义冲突）
#ifndef FILE_DEFINED
#define FILE_DEFINED
typedef int FILE;
#endif

// 文件定位常量
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2

// 基本类型限制（使用 ifndef 防止重定义）
#ifndef LONG_MAX
#define LONG_MAX 2147483647L
#endif
#ifndef LONG_MIN
#define LONG_MIN (-2147483647L - 1)
#endif

// I/O 函数声明（简化版本，Zig 内置编译器会提供实现）
int snprintf(char *str, size_t size, const char *format, ...);
int sscanf(const char *str, const char *format, ...);
int printf(const char *format, ...);
int fprintf(FILE *stream, const char *format, ...);

FILE* fopen(const char *filename, const char *mode);
int fclose(FILE *stream);
size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream);
size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream);
int fseek(FILE *stream, long offset, int whence);
long ftell(FILE *stream);
void setbuf(FILE *stream, char *buffer);
int fflush(FILE *stream);
int ferror(FILE *stream);
char* fgets(char *str, int n, FILE *stream);

// 文件操作函数
int remove(const char *filename);
int rename(const char *oldpath, const char *newpath);

#endif // TF_PSA_CRYPTO_COMPAT_STDIO_H
