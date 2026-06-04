const std = @import("std");

// Mbed TLS Linux ARM 交叉编译配置
// 在 Windows 上使用 Zig 交叉编译到 Linux ARM32/ARM64
// 优化：ReleaseSmall

pub fn build(b: *std.Build) void {
    // 使用 ReleaseSmall 优化
    const optimize = std.builtin.OptimizeMode.ReleaseSmall;

    // 定义 tfpsacrypto（密码学核心库）源文件
    const src_tfpsacrypto_core = [_][]const u8{
        // Core PSA Crypto API 实现
        "tf-psa-crypto/core/psa_crypto.c",
        "tf-psa-crypto/core/psa_crypto_client.c",
        "tf-psa-crypto/core/psa_crypto_random.c",
        "tf-psa-crypto/core/psa_crypto_slot_management.c",
        "tf-psa-crypto/core/psa_crypto_storage.c",
        "tf-psa-crypto/core/psa_its_file.c",
        "tf-psa-crypto/core/psa_util.c",
        "tf-psa-crypto/core/tf_psa_crypto_config.c",
        "tf-psa-crypto/core/tf_psa_crypto_version.c",
    };

    const src_tfpsacrypto_builtin = [_][]const u8{
        // 对称密码算法
        "tf-psa-crypto/drivers/builtin/src/aes.c",
        "tf-psa-crypto/drivers/builtin/src/aesce.c",
        "tf-psa-crypto/drivers/builtin/src/aesni.c",
        "tf-psa-crypto/drivers/builtin/src/aria.c",
        "tf-psa-crypto/drivers/builtin/src/camellia.c",
        "tf-psa-crypto/drivers/builtin/src/chacha20.c",
        "tf-psa-crypto/drivers/builtin/src/chacha20_neon.c",
        "tf-psa-crypto/drivers/builtin/src/block_cipher.c",
        "tf-psa-crypto/drivers/builtin/src/cipher.c",
        "tf-psa-crypto/drivers/builtin/src/cipher_wrap.c",
        "tf-psa-crypto/drivers/builtin/src/ccm.c",
        "tf-psa-crypto/drivers/builtin/src/gcm.c",
        "tf-psa-crypto/drivers/builtin/src/chachapoly.c",

        // 哈希算法
        "tf-psa-crypto/drivers/builtin/src/md5.c",
        "tf-psa-crypto/drivers/builtin/src/sha1.c",
        "tf-psa-crypto/drivers/builtin/src/sha256.c",
        "tf-psa-crypto/drivers/builtin/src/sha512.c",
        "tf-psa-crypto/drivers/builtin/src/sha3.c",
        "tf-psa-crypto/drivers/builtin/src/ripemd160.c",

        // MAC 算法
        "tf-psa-crypto/drivers/builtin/src/cmac.c",
        "tf-psa-crypto/drivers/builtin/src/hmac_drbg.c",
        "tf-psa-crypto/drivers/builtin/src/poly1305.c",

        // 公钥密码学
        "tf-psa-crypto/drivers/builtin/src/rsa.c",
        "tf-psa-crypto/drivers/builtin/src/rsa_alt_helpers.c",
        "tf-psa-crypto/drivers/builtin/src/ecp.c",
        "tf-psa-crypto/drivers/builtin/src/ecp_curves.c",
        "tf-psa-crypto/drivers/builtin/src/ecp_curves_new.c",
        "tf-psa-crypto/drivers/builtin/src/ecdsa.c",
        "tf-psa-crypto/drivers/builtin/src/ecjpake.c",

        // 大整数运算
        "tf-psa-crypto/drivers/builtin/src/bignum.c",
        "tf-psa-crypto/drivers/builtin/src/bignum_core.c",
        "tf-psa-crypto/drivers/builtin/src/bignum_mod.c",
        "tf-psa-crypto/drivers/builtin/src/bignum_mod_raw.c",

        // 随机数生成
        "tf-psa-crypto/drivers/builtin/src/entropy.c",
        "tf-psa-crypto/drivers/builtin/src/entropy_poll.c",
        "tf-psa-crypto/drivers/builtin/src/ctr_drbg.c",

        // PSA 包装器
        "tf-psa-crypto/drivers/builtin/src/psa_crypto_aead.c",
        "tf-psa-crypto/drivers/builtin/src/psa_crypto_cipher.c",
        "tf-psa-crypto/drivers/builtin/src/psa_crypto_ecp.c",
        "tf-psa-crypto/drivers/builtin/src/psa_crypto_ffdh.c",
        "tf-psa-crypto/drivers/builtin/src/psa_crypto_hash.c",
        "tf-psa-crypto/drivers/builtin/src/psa_crypto_mac.c",
        "tf-psa-crypto/drivers/builtin/src/psa_crypto_pake.c",
        "tf-psa-crypto/drivers/builtin/src/psa_crypto_rsa.c",
        "tf-psa-crypto/drivers/builtin/src/psa_crypto_xof.c",
        "tf-psa-crypto/drivers/builtin/src/psa_util_internal.c",
    };

    // 定义 mbedx509（X.509 证书处理）源文件
    const src_x509 = [_][]const u8{
        "library/mbedtls_config.c",
        "library/pkcs7.c",
        "library/x509.c",
        "library/x509_create.c",
        "library/x509_crl.c",
        "library/x509_crt.c",
        "library/x509_csr.c",
        "library/x509_oid.c",
        "library/x509write.c",
        "library/x509write_crt.c",
        "library/x509write_csr.c",
    };

    // 定义 mbedtls（TLS 协议）源文件
    const src_tls = [_][]const u8{
        "library/debug.c",
        "library/mps_reader.c",
        "library/mps_trace.c",
        "library/net_sockets.c",
        "library/ssl_cache.c",
        "library/ssl_ciphersuites.c",
        "library/ssl_client.c",
        "library/ssl_cookie.c",
        "library/ssl_msg.c",
        "library/ssl_ticket.c",
        "library/ssl_tls.c",
        "library/ssl_tls12_client.c",
        "library/ssl_tls12_server.c",
        "library/ssl_tls13_keys.c",
        "library/ssl_tls13_server.c",
        "library/ssl_tls13_client.c",
        "library/ssl_tls13_generic.c",
        "library/timing.c",
        "library/version.c",
    };

    // Linux ARM64 交叉编译
    buildLinuxArm64(b, optimize, &src_tfpsacrypto_core, &src_tfpsacrypto_builtin, &src_x509, &src_tls);

    // Linux ARM32 交叉编译
    buildLinuxArm32(b, optimize, &src_tfpsacrypto_core, &src_tfpsacrypto_builtin, &src_x509, &src_tls);

    // 创建构建步骤
    const all_step = b.step("all", "Build all Linux ARM platforms (ARM64 + ARM32)");
    all_step.dependOn(b.getInstallStep());
}

fn buildLinuxArm64(
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
    src_tfpsacrypto_core: []const []const u8,
    src_tfpsacrypto_builtin: []const []const u8,
    src_x509: []const []const u8,
    src_tls: []const []const u8,
) void {
    // 使用 Zig 的交叉编译功能，使用 musl libc
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .aarch64,
        .os_tag = .linux,
        .abi = .musl,
    });

    // 构建链接顺序：tfpsacrypto → mbedx509 → mbedtls

    // 1. 构建 tfpsacrypto（密码学核心库）
    const tfpsacrypto = b.addLibrary(.{
        .name = "tfpsacrypto_linux_arm64",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupCompileOptions(tfpsacrypto, b, src_tfpsacrypto_core, src_tfpsacrypto_builtin);
    b.installArtifact(tfpsacrypto);

    // 2. 构建 mbedx509（X.509 证书处理）
    const mbedx509 = b.addLibrary(.{
        .name = "mbedx509_linux_arm64",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupX509CompileOptions(mbedx509, b, src_x509);
    mbedx509.root_module.linkLibrary(tfpsacrypto);
    b.installArtifact(mbedx509);

    // 3. 构建 mbedtls（TLS 协议）
    const mbedtls = b.addLibrary(.{
        .name = "mbedtls_linux_arm64",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupTLSCompileOptions(mbedtls, b, src_tls);
    mbedtls.root_module.linkLibrary(tfpsacrypto);
    mbedtls.root_module.linkLibrary(mbedx509);
    b.installArtifact(mbedtls);
}

fn buildLinuxArm32(
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
    src_tfpsacrypto_core: []const []const u8,
    src_tfpsacrypto_builtin: []const []const u8,
    src_x509: []const []const u8,
    src_tls: []const []const u8,
) void {
    // 使用 Zig 的交叉编译功能，使用 musl libc
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .arm,
        .os_tag = .linux,
        .abi = .musleabihf,
    });

    // 构建链接顺序：tfpsacrypto → mbedx509 → mbedtls

    // 1. 构建 tfpsacrypto（密码学核心库）
    const tfpsacrypto = b.addLibrary(.{
        .name = "tfpsacrypto_linux_arm32",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupCompileOptions(tfpsacrypto, b, src_tfpsacrypto_core, src_tfpsacrypto_builtin);
    b.installArtifact(tfpsacrypto);

    // 2. 构建 mbedx509（X.509 证书处理）
    const mbedx509 = b.addLibrary(.{
        .name = "mbedx509_linux_arm32",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupX509CompileOptions(mbedx509, b, src_x509);
    mbedx509.root_module.linkLibrary(tfpsacrypto);
    b.installArtifact(mbedx509);

    // 3. 构建 mbedtls（TLS 协议）
    const mbedtls = b.addLibrary(.{
        .name = "mbedtls_linux_arm32",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupTLSCompileOptions(mbedtls, b, src_tls);
    mbedtls.root_module.linkLibrary(tfpsacrypto);
    mbedtls.root_module.linkLibrary(mbedx509);
    b.installArtifact(mbedtls);
}

// 为 tfpsacrypto 库设置编译选项（包含所有源文件）
fn setupCompileOptions(
    lib: *std.Build.Step.Compile,
    b: *std.Build,
    src_core: []const []const u8,
    src_builtin: []const []const u8,
) void {
    const mod = lib.root_module;

    // 添加包含路径
    mod.addIncludePath(b.path("include"));
    mod.addIncludePath(b.path("library"));
    mod.addIncludePath(b.path("tf-psa-crypto/include"));
    mod.addIncludePath(b.path("tf-psa-crypto/core"));
    mod.addIncludePath(b.path("tf-psa-crypto/core/compat"));
    mod.addIncludePath(b.path("tf-psa-crypto/dispatch")); // psa_crypto_driver_wrappers
    mod.addIncludePath(b.path("tf-psa-crypto/platform")); // threading_internal.h
    mod.addIncludePath(b.path("tf-psa-crypto/utilities")); // constant_time_internal.h
    mod.addIncludePath(b.path("tf-psa-crypto/drivers/builtin/include"));
    mod.addIncludePath(b.path("tf-psa-crypto/drivers/builtin/src"));
    mod.addIncludePath(b.path("tf-psa-crypto/extras"));

    // 添加 ECP 和加密配置
    mod.addCMacro("MBEDTLS_BIGNUM_C", "1");
    mod.addCMacro("MBEDTLS_ECP_C", "1");
    mod.addCMacro("MBEDTLS_ECP_DP_SECP256R1_ENABLED", "1");
    mod.addCMacro("MBEDTLS_ECP_DP_SECP384R1_ENABLED", "1");

    // PSA 算法支持
    mod.addCMacro("PSA_WANT_ALG_SHA_256", "1");
    mod.addCMacro("PSA_WANT_ALG_SHA_512", "1");

    // 添加核心源文件
    for (src_core) |src| {
        mod.addCSourceFile(.{
            .file = b.path(src),
            .flags = &.{ "-std=c99" },
        });
    }

    // 添加 builtin 驱动源文件
    for (src_builtin) |src| {
        mod.addCSourceFile(.{
            .file = b.path(src),
            .flags = &.{ "-std=c99" },
        });
    }
}

// 为 mbedx509 库设置编译选项
fn setupX509CompileOptions(
    lib: *std.Build.Step.Compile,
    b: *std.Build,
    sources: []const []const u8,
) void {
    const mod = lib.root_module;

    // 添加包含路径
    mod.addIncludePath(b.path("include"));
    mod.addIncludePath(b.path("library"));
    mod.addIncludePath(b.path("tf-psa-crypto/include"));
    mod.addIncludePath(b.path("tf-psa-crypto/core"));
    mod.addIncludePath(b.path("tf-psa-crypto/core/compat"));
    mod.addIncludePath(b.path("tf-psa-crypto/dispatch")); // psa_crypto_driver_wrappers
    mod.addIncludePath(b.path("tf-psa-crypto/platform")); // threading_internal.h
    mod.addIncludePath(b.path("tf-psa-crypto/utilities")); // constant_time_internal.h
    mod.addIncludePath(b.path("tf-psa-crypto/drivers/builtin/include"));
    mod.addIncludePath(b.path("tf-psa-crypto/drivers/builtin/src"));
    mod.addIncludePath(b.path("tf-psa-crypto/extras"));

    // 添加 ECP 和加密配置
    mod.addCMacro("MBEDTLS_BIGNUM_C", "1");
    mod.addCMacro("MBEDTLS_ECP_C", "1");
    mod.addCMacro("MBEDTLS_ECP_DP_SECP256R1_ENABLED", "1");
    mod.addCMacro("MBEDTLS_ECP_DP_SECP384R1_ENABLED", "1");

    // PSA 算法支持
    mod.addCMacro("PSA_WANT_ALG_SHA_256", "1");
    mod.addCMacro("PSA_WANT_ALG_SHA_512", "1");

    // 添加源文件
    for (sources) |src| {
        mod.addCSourceFile(.{
            .file = b.path(src),
            .flags = &.{ "-std=c99" },
        });
    }
}

// 为 mbedtls 库设置编译选项
fn setupTLSCompileOptions(
    lib: *std.Build.Step.Compile,
    b: *std.Build,
    sources: []const []const u8,
) void {
    const mod = lib.root_module;

    // 添加包含路径
    mod.addIncludePath(b.path("include"));
    mod.addIncludePath(b.path("library"));
    mod.addIncludePath(b.path("tf-psa-crypto/include"));
    mod.addIncludePath(b.path("tf-psa-crypto/core"));
    mod.addIncludePath(b.path("tf-psa-crypto/core/compat"));
    mod.addIncludePath(b.path("tf-psa-crypto/dispatch")); // psa_crypto_driver_wrappers
    mod.addIncludePath(b.path("tf-psa-crypto/platform")); // threading_internal.h
    mod.addIncludePath(b.path("tf-psa-crypto/utilities")); // constant_time_internal.h
    mod.addIncludePath(b.path("tf-psa-crypto/drivers/builtin/include"));
    mod.addIncludePath(b.path("tf-psa-crypto/drivers/builtin/src"));
    mod.addIncludePath(b.path("tf-psa-crypto/extras"));

    // 添加 ECP 和加密配置
    mod.addCMacro("MBEDTLS_BIGNUM_C", "1");
    mod.addCMacro("MBEDTLS_ECP_C", "1");
    mod.addCMacro("MBEDTLS_ECP_DP_SECP256R1_ENABLED", "1");
    mod.addCMacro("MBEDTLS_ECP_DP_SECP384R1_ENABLED", "1");

    // PSA 算法支持
    mod.addCMacro("PSA_WANT_ALG_SHA_256", "1");
    mod.addCMacro("PSA_WANT_ALG_SHA_512", "1");

    // 添加源文件
    for (sources) |src| {
        mod.addCSourceFile(.{
            .file = b.path(src),
            .flags = &.{ "-std=c99" },
        });
    }
}
