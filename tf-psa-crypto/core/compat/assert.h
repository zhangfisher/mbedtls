#ifndef TF_PSA_CRYPTO_COMPAT_ASSERT_H
#define TF_PSA_CRYPTO_COMPAT_ASSERT_H

// 简化的 assert 定义
#ifdef NDEBUG
#define assert(condition) ((void)0)
#else
#define assert(condition) do { if (!(condition)) { *((volatile int*)0) = 0; } } while(0)
#endif

#endif // TF_PSA_CRYPTO_COMPAT_ASSERT_H
