#ifndef TF_PSA_CRYPTO_COMPAT_SYS_AUXV_H
#define TF_PSA_CRYPTO_COMPAT_SYS_AUXV_H

// Linux auxv (辅助向量) 基本定义
// 用于运行时 CPU 特性检测

#ifndef AT_HWCAP
#define AT_HWCAP 16
#endif

#ifndef AT_HWCAP2
#define AT_HWCAP2 26
#endif

// HWCAP 位定义（ARM64）
#ifndef HWCAP_AES
#define HWCAP_AES (1 << 3)
#endif

#ifndef HWCAP_PMULL
#define HWCAP_PMULL (1 << 4)
#endif

#ifndef HWCAP_SHA2
#define HWCAP_SHA2 (1 << 6)
#endif

// 用于 getauxval() 函数声明
unsigned long getauxval(unsigned long type);

#endif // TF_PSA_CRYPTO_COMPAT_SYS_AUXV_H
