/* mbedtls ECP configuration for Zig build */
#ifndef MBEDTLS_ECP_CONFIG_H
#define MBEDTLS_ECP_CONFIG_H

/* 启用基本椭圆曲线支持以满足 MBEDTLS_ECP_MAX_BITS 定义要求 */
#define MBEDTLS_ECP_C
#define MBEDTLS_ECP_DP_SECP256R1_ENABLED
#define MBEDTLS_ECP_DP_SECP384R1_ENABLED

#endif /* MBEDTLS_ECP_CONFIG_H */
