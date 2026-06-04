#ifndef TF_PSA_CRYPTO_COMPAT_STDINT_H
#define TF_PSA_CRYPTO_COMPAT_STDINT_H

// 直接定义所有基本整数类型（避免与系统头文件冲突）
#ifndef UINT8_MAX
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;
typedef unsigned long long uint64_t;

typedef signed char int8_t;
typedef signed short int16_t;
typedef signed int int32_t;
typedef signed long long int64_t;
#endif

// 定义指针大小相关的类型和宏（使用条件检查避免重定义）
#ifndef UINTPTR_MAX
#if defined(__aarch64__) || defined(__x86_64__) || defined(_M_X64) || defined(_M_ARM64)
// 64位系统
typedef unsigned long long uintptr_t;
typedef long long intptr_t;
typedef long long intmax_t;
typedef unsigned long long uintmax_t;
#define UINTPTR_MAX 0xffffffffffffffffull
#define INTPTR_MAX 0x7fffffffffffffffll
#define INTPTR_MIN (-INTPTR_MAX - 1)
#define INTMAX_MAX 0x7fffffffffffffffll
#define UINTMAX_MAX 0xffffffffffffffffull
#elif defined(__arm__) || defined(__i386__) || defined(_M_X86) || defined(_M_IX86)
// 32位系统
typedef unsigned int uintptr_t;
typedef int intptr_t;
typedef long long intmax_t;
typedef unsigned long long uintmax_t;
#define UINTPTR_MAX 0xffffffffu
#define INTPTR_MAX 0x7fffffff
#define INTPTR_MIN (-INTPTR_MAX - 1)
#define INTMAX_MAX 0x7fffffffffffffffll
#define UINTMAX_MAX 0xffffffffffffffffull
#else
// 默认64位
typedef unsigned long long uintptr_t;
typedef long long intptr_t;
typedef long long intmax_t;
typedef unsigned long long uintmax_t;
#define UINTPTR_MAX 0xffffffffffffffffull
#define INTPTR_MAX 0x7fffffffffffffffll
#define INTPTR_MIN (-INTPTR_MAX - 1)
#define INTMAX_MAX 0x7fffffffffffffffll
#define UINTMAX_MAX 0xffffffffffffffffull
#endif
#endif

// 定义 SIZE_MAX（size_t 的最大值）
#ifndef SIZE_MAX
#if defined(__aarch64__) || defined(__x86_64__) || defined(_M_X64) || defined(_M_ARM64)
#define SIZE_MAX 0xffffffffffffffffull
#elif UINTPTR_MAX == 0xffffffffffffffffull
#define SIZE_MAX 0xffffffffffffffffull
#else
#define SIZE_MAX 0xffffffffu
#endif
#endif

#endif // TF_PSA_CRYPTO_COMPAT_STDINT_H
