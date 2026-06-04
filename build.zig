const std = @import("std");

// Mbed TLS 多平台交叉编译配置
// 支持平台：Windows x86-64, Linux ARM32/ARM64
// 优化：ReleaseSmall

// 平台枚举
const Platform = enum {
    windows,
    linux_arm64,
    linux_arm32,
    linux_x64_musl,
    linux_x64_gnu,
};

// 构建配置
const BuildConfig = struct {
    platforms: []const Platform,
    webrtc: bool,
};

// 解析平台字符串
fn parsePlatformString(allocator: std.mem.Allocator, platform_str: []const u8) ![]const Platform {
    var platforms = std.ArrayList(Platform).initCapacity(allocator, 5) catch return error.OutOfMemory;

    if (std.mem.eql(u8, platform_str, "all")) {
        // 构建所有平台
        try platforms.appendSlice(allocator, &.{
            .windows,
            .linux_arm64,
            .linux_arm32,
            .linux_x64_musl,
            .linux_x64_gnu,
        });
    } else {
        // 解析用户指定的平台（逗号分隔）
        var iter = std.mem.splitScalar(u8, platform_str, ',');
        while (iter.next()) |platform_name| {
            const trimmed = std.mem.trim(u8, platform_name, " ");
            if (std.mem.eql(u8, trimmed, "windows")) {
                try platforms.append(allocator, .windows);
            } else if (std.mem.eql(u8, trimmed, "linux-arm64")) {
                try platforms.append(allocator, .linux_arm64);
            } else if (std.mem.eql(u8, trimmed, "linux-arm32")) {
                try platforms.append(allocator, .linux_arm32);
            } else if (std.mem.eql(u8, trimmed, "linux-x64-musl")) {
                try platforms.append(allocator, .linux_x64_musl);
            } else if (std.mem.eql(u8, trimmed, "linux-x64-gnu")) {
                try platforms.append(allocator, .linux_x64_gnu);
            } else if (trimmed.len > 0) {
                std.log.warn("Unknown platform: {s}", .{trimmed});
            }
        }
    }

    return platforms.toOwnedSlice(allocator);
}

// 安装公共API头文件到 zig-out/include
fn installPublicHeaders(b: *std.Build) void {
    // 安装 Mbed TLS 公共 API 头文件
    const mbedtls_headers = b.addInstallDirectory(.{
        .source_dir = b.path("include/mbedtls"),
        .install_dir = .{ .custom = "include/mbedtls" },
        .install_subdir = "",
    });

    // 安装 PSA 密码学 API 头文件（从 tf-psa-crypto/include/psa）
    const psa_headers_step = b.addInstallDirectory(.{
        .source_dir = b.path("tf-psa-crypto/include/psa"),
        .install_dir = .{ .custom = "include/psa" },
        .install_subdir = "",
    });

    // 确保在主构建步骤中执行
    b.getInstallStep().dependOn(&mbedtls_headers.step);
    b.getInstallStep().dependOn(&psa_headers_step.step);
}

pub fn build(b: *std.Build) void {
    // 解析命令行选项
    const platform_option = b.option(
        []const u8,
        "platform",
        "Target platform(s): windows, linux-arm64, linux-arm32, linux-x64-musl, linux-x64-gnu, or all (comma-separated)",
    ) orelse "all";

    const webrtc_option = b.option(
        bool,
        "webrtc",
        "Build WebRTC optimized versions",
    ) orelse false;

    // 解析平台列表
    const config = BuildConfig{
        .platforms = parsePlatformString(b.allocator, platform_option) catch |err| {
            std.log.err("Failed to parse platform string: {s}", .{@errorName(err)});
            return;
        },
        .webrtc = webrtc_option,
    };
    defer b.allocator.free(config.platforms);

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

    // 根据配置构建对应平台
    for (config.platforms) |platform| {
        switch (platform) {
            .windows => {
                if (config.webrtc) {
                    buildWindowsX64WebRTC(b);
                } else {
                    buildWindowsX64(b, optimize, &src_tfpsacrypto_core, &src_tfpsacrypto_builtin, &src_x509, &src_tls);
                }
            },
            .linux_arm64 => {
                if (config.webrtc) {
                    buildLinuxArm64WebRTC(b);
                } else {
                    buildLinuxArm64(b, optimize, &src_tfpsacrypto_core, &src_tfpsacrypto_builtin, &src_x509, &src_tls);
                }
            },
            .linux_arm32 => {
                if (config.webrtc) {
                    buildLinuxArm32WebRTC(b);
                } else {
                    buildLinuxArm32(b, optimize, &src_tfpsacrypto_core, &src_tfpsacrypto_builtin, &src_x509, &src_tls);
                }
            },
            .linux_x64_musl => {
                if (config.webrtc) {
                    buildLinuxX64MuslWebRTC(b);
                } else {
                    buildLinuxX64Musl(b, optimize, &src_tfpsacrypto_core, &src_tfpsacrypto_builtin, &src_x509, &src_tls);
                }
            },
            .linux_x64_gnu => {
                if (config.webrtc) {
                    buildLinuxX64GnuWebRTC(b);
                } else {
                    buildLinuxX64Gnu(b, optimize, &src_tfpsacrypto_core, &src_tfpsacrypto_builtin, &src_x509, &src_tls);
                }
            },
        }
    }

    // 复制公共API头文件到 zig-out/include
    installPublicHeaders(b);

    // 创建构建步骤
    createPlatformBuildSteps(b);
}

fn buildWindowsX64(
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
    src_tfpsacrypto_core: []const []const u8,
    src_tfpsacrypto_builtin: []const []const u8,
    src_x509: []const []const u8,
    src_tls: []const []const u8,
) void {
    // Windows x86-64 本地构建
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .windows,
        .abi = .gnu,
    });

    // 构建链接顺序：tfpsacrypto → mbedx509 → mbedtls

    // 1. 构建 tfpsacrypto（密码学核心库）
    const tfpsacrypto = b.addLibrary(.{
        .name = "tfpsacrypto_windows_x64",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupWindowsCompileOptions(tfpsacrypto, b, src_tfpsacrypto_core, src_tfpsacrypto_builtin);
    b.installArtifact(tfpsacrypto);

    // 2. 构建 mbedx509（X.509 证书处理）
    const mbedx509 = b.addLibrary(.{
        .name = "mbedx509_windows_x64",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupWindowsX509CompileOptions(mbedx509, b, src_x509);
    mbedx509.root_module.linkLibrary(tfpsacrypto);
    b.installArtifact(mbedx509);

    // 3. 构建 mbedtls（TLS 协议）
    const mbedtls = b.addLibrary(.{
        .name = "mbedtls_windows_x64",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupWindowsTLSCompileOptions(mbedtls, b, src_tls);
    mbedtls.root_module.linkLibrary(tfpsacrypto);
    mbedtls.root_module.linkLibrary(mbedx509);
    b.installArtifact(mbedtls);
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

    // Windows 平台定义
    mod.addCMacro("_WIN32", "1");
    mod.addCMacro("_WIN64", "1");

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

    // Windows 平台定义
    mod.addCMacro("_WIN32", "1");
    mod.addCMacro("_WIN64", "1");

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

    // Windows 平台定义
    mod.addCMacro("_WIN32", "1");
    mod.addCMacro("_WIN64", "1");

    // 添加源文件
    for (sources) |src| {
        mod.addCSourceFile(.{
            .file = b.path(src),
            .flags = &.{ "-std=c99" },
        });
    }
}

// 为 Windows 平台 tfpsacrypto 库设置编译选项
fn setupWindowsCompileOptions(
    lib: *std.Build.Step.Compile,
    b: *std.Build,
    src_core: []const []const u8,
    src_builtin: []const []const u8,
) void {
    const mod = lib.root_module;

    // 添加包含路径（包含 core/compat 但避免宏重定义）
    mod.addIncludePath(b.path("include"));
    mod.addIncludePath(b.path("library"));
    mod.addIncludePath(b.path("tf-psa-crypto/include"));
    mod.addIncludePath(b.path("tf-psa-crypto/core"));
    mod.addIncludePath(b.path("tf-psa-crypto/core/compat")); // Windows 也使用兼容层
    mod.addIncludePath(b.path("tf-psa-crypto/dispatch"));
    mod.addIncludePath(b.path("tf-psa-crypto/platform"));
    mod.addIncludePath(b.path("tf-psa-crypto/utilities"));
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

    // Windows 平台定义
    mod.addCMacro("_WIN32", "1");
    mod.addCMacro("_WIN64", "1");

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

// 为 Windows 平台 mbedx509 库设置编译选项（不使用兼容层）
fn setupWindowsX509CompileOptions(
    lib: *std.Build.Step.Compile,
    b: *std.Build,
    sources: []const []const u8,
) void {
    const mod = lib.root_module;

    // 添加包含路径（包含 core/compat）
    mod.addIncludePath(b.path("include"));
    mod.addIncludePath(b.path("library"));
    mod.addIncludePath(b.path("tf-psa-crypto/include"));
    mod.addIncludePath(b.path("tf-psa-crypto/core"));
    mod.addIncludePath(b.path("tf-psa-crypto/core/compat"));
    mod.addIncludePath(b.path("tf-psa-crypto/dispatch"));
    mod.addIncludePath(b.path("tf-psa-crypto/platform"));
    mod.addIncludePath(b.path("tf-psa-crypto/utilities"));
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

    // Windows 平台定义
    mod.addCMacro("_WIN32", "1");
    mod.addCMacro("_WIN64", "1");

    // 添加源文件
    for (sources) |src| {
        mod.addCSourceFile(.{
            .file = b.path(src),
            .flags = &.{ "-std=c99" },
        });
    }
}

// 为 Windows 平台 mbedtls 库设置编译选项（不使用兼容层）
fn setupWindowsTLSCompileOptions(
    lib: *std.Build.Step.Compile,
    b: *std.Build,
    sources: []const []const u8,
) void {
    const mod = lib.root_module;

    // 添加包含路径（包含 core/compat）
    mod.addIncludePath(b.path("include"));
    mod.addIncludePath(b.path("library"));
    mod.addIncludePath(b.path("tf-psa-crypto/include"));
    mod.addIncludePath(b.path("tf-psa-crypto/core"));
    mod.addIncludePath(b.path("tf-psa-crypto/core/compat"));
    mod.addIncludePath(b.path("tf-psa-crypto/dispatch"));
    mod.addIncludePath(b.path("tf-psa-crypto/platform"));
    mod.addIncludePath(b.path("tf-psa-crypto/utilities"));
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

    // Windows 平台定义
    mod.addCMacro("_WIN32", "1");
    mod.addCMacro("_WIN64", "1");

    // 添加源文件
    for (sources) |src| {
        mod.addCSourceFile(.{
            .file = b.path(src),
            .flags = &.{ "-std=c99" },
        });
    }
}

// ============================================
// WebRTC 专用构建函数
// ============================================

// WebRTC 专用密码学源文件列表（移除不常用算法）
const src_tfpsacrypto_builtin_webrtc = [_][]const u8{
    // 对称密码算法 - 保留 WebRTC 常用的
    "tf-psa-crypto/drivers/builtin/src/aes.c",
    // 移除不常用算法: aria.c, camellia.c
    // 硬件加速按需保留 - 这里暂时移除以优化大小
    // "tf-psa-crypto/drivers/builtin/src/aesce.c",
    // "tf-psa-crypto/drivers/builtin/src/aesni.c",
    "tf-psa-crypto/drivers/builtin/src/chacha20.c",
    // "tf-psa-crypto/drivers/builtin/src/chacha20_neon.c",
    "tf-psa-crypto/drivers/builtin/src/block_cipher.c",
    "tf-psa-crypto/drivers/builtin/src/cipher.c",
    "tf-psa-crypto/drivers/builtin/src/cipher_wrap.c",
    "tf-psa-crypto/drivers/builtin/src/ccm.c",
    "tf-psa-crypto/drivers/builtin/src/gcm.c",
    "tf-psa-crypto/drivers/builtin/src/chachapoly.c",

    // 哈希算法 - 只保留 WebRTC 必需的
    // 移除已弃用和不常用: md5.c, ripemd160.c, sha1.c, sha3.c
    "tf-psa-crypto/drivers/builtin/src/sha256.c",
    "tf-psa-crypto/drivers/builtin/src/sha512.c",

    // MAC 算法 - 只保留 WebRTC 必需的
    // 移除不常用: cmac.c, hmac_drbg.c (已有 CTR_DRBG)
    "tf-psa-crypto/drivers/builtin/src/poly1305.c",

    // 公钥密码学 - 保留 WebRTC 必需的
    "tf-psa-crypto/drivers/builtin/src/rsa.c",
    "tf-psa-crypto/drivers/builtin/src/rsa_alt_helpers.c",
    "tf-psa-crypto/drivers/builtin/src/ecp.c",
    // 只保留一个椭圆曲线实现 (ecp_curves.c)
    // ecp_curves_new.c 通过条件编译排除
    "tf-psa-crypto/drivers/builtin/src/ecp_curves.c",
    "tf-psa-crypto/drivers/builtin/src/ecdsa.c",
    // 移除不常用: ecjpake.c

    // 大整数运算
    "tf-psa-crypto/drivers/builtin/src/bignum.c",
    "tf-psa-crypto/drivers/builtin/src/bignum_core.c",
    "tf-psa-crypto/drivers/builtin/src/bignum_mod.c",
    "tf-psa-crypto/drivers/builtin/src/bignum_mod_raw.c",

    // 随机数生成 - 只保留 CTR_DRBG
    "tf-psa-crypto/drivers/builtin/src/entropy.c",
    "tf-psa-crypto/drivers/builtin/src/entropy_poll.c",
    "tf-psa-crypto/drivers/builtin/src/ctr_drbg.c",

    // PSA 包装器 - 只保留 WebRTC 必需的
    "tf-psa-crypto/drivers/builtin/src/psa_crypto_aead.c",
    "tf-psa-crypto/drivers/builtin/src/psa_crypto_cipher.c",
    "tf-psa-crypto/drivers/builtin/src/psa_crypto_ecp.c",
    "tf-psa-crypto/drivers/builtin/src/psa_crypto_hash.c",
    "tf-psa-crypto/drivers/builtin/src/psa_crypto_mac.c",
    "tf-psa-crypto/drivers/builtin/src/psa_crypto_rsa.c",
    // 移除不常用: psa_crypto_ffdh.c, psa_crypto_pake.c, psa_crypto_xof.c
    "tf-psa-crypto/drivers/builtin/src/psa_util_internal.c",
};

// 为 WebRTC 配置编译选项（裁剪不需要的功能）
fn setupWebRTCConfig(mod: *std.Build.Module) void {
    // WebRTC禁用调试功能
    mod.addCMacro("MBEDTLS_DEBUG_C", "0");
}

fn buildWindowsX64WebRTC(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .windows,
        .abi = .gnu,
    });
    const optimize = std.builtin.OptimizeMode.ReleaseSmall;

    // 定义源文件列表（内联以避免传递参数）
    const src_tfpsacrypto_core = [_][]const u8{
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

    const src_x509_webrtc = [_][]const u8{
        "library/mbedtls_config.c",
        "library/x509.c",
        "library/x509_oid.c",
    };

    const src_tls_webrtc = [_][]const u8{
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

    // 构建 WebRTC 专用 tfpsacrypto
    const tfpsacrypto = b.addLibrary(.{
        .name = "tfpsacrypto_windows_x64_webrtc",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupWindowsCompileOptions(tfpsacrypto, b, &src_tfpsacrypto_core, &src_tfpsacrypto_builtin_webrtc);
    setupWebRTCConfig(tfpsacrypto.root_module);
    b.installArtifact(tfpsacrypto);

    // 构建 WebRTC 专用 mbedx509（最小化）
    const mbedx509 = b.addLibrary(.{
        .name = "mbedx509_windows_x64_webrtc",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupWindowsX509CompileOptions(mbedx509, b, &src_x509_webrtc);
    setupWebRTCConfig(mbedx509.root_module);
    mbedx509.root_module.linkLibrary(tfpsacrypto);
    b.installArtifact(mbedx509);

    // 构建 WebRTC 专用 mbedtls
    const mbedtls = b.addLibrary(.{
        .name = "mbedtls_windows_x64_webrtc",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupWindowsTLSCompileOptions(mbedtls, b, &src_tls_webrtc);
    setupWebRTCConfig(mbedtls.root_module);
    mbedtls.root_module.linkLibrary(tfpsacrypto);
    mbedtls.root_module.linkLibrary(mbedx509);
    b.installArtifact(mbedtls);
}

fn buildLinuxArm64WebRTC(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .aarch64,
        .os_tag = .linux,
        .abi = .musl,
    });
    const optimize = std.builtin.OptimizeMode.ReleaseSmall;

    // 定义源文件列表
    const src_tfpsacrypto_core = [_][]const u8{
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

    const src_x509_webrtc = [_][]const u8{
        "library/mbedtls_config.c",
        "library/x509.c",
        "library/x509_oid.c",
    };

    const src_tls_webrtc = [_][]const u8{
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

    // 构建 WebRTC 专用 tfpsacrypto
    const tfpsacrypto = b.addLibrary(.{
        .name = "tfpsacrypto_linux_arm64_webrtc",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupCompileOptions(tfpsacrypto, b, &src_tfpsacrypto_core, &src_tfpsacrypto_builtin_webrtc);
    setupWebRTCConfig(tfpsacrypto.root_module);
    b.installArtifact(tfpsacrypto);

    // 构建 WebRTC 专用 mbedx509
    const mbedx509 = b.addLibrary(.{
        .name = "mbedx509_linux_arm64_webrtc",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupX509CompileOptions(mbedx509, b, &src_x509_webrtc);
    setupWebRTCConfig(mbedx509.root_module);
    mbedx509.root_module.linkLibrary(tfpsacrypto);
    b.installArtifact(mbedx509);

    // 构建 WebRTC 专用 mbedtls
    const mbedtls = b.addLibrary(.{
        .name = "mbedtls_linux_arm64_webrtc",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupTLSCompileOptions(mbedtls, b, &src_tls_webrtc);
    setupWebRTCConfig(mbedtls.root_module);
    mbedtls.root_module.linkLibrary(tfpsacrypto);
    mbedtls.root_module.linkLibrary(mbedx509);
    b.installArtifact(mbedtls);
}

fn buildLinuxArm32WebRTC(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .arm,
        .os_tag = .linux,
        .abi = .musleabihf,
    });
    const optimize = std.builtin.OptimizeMode.ReleaseSmall;

    // 定义源文件列表
    const src_tfpsacrypto_core = [_][]const u8{
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

    const src_x509_webrtc = [_][]const u8{
        "library/mbedtls_config.c",
        "library/x509.c",
        "library/x509_oid.c",
    };

    const src_tls_webrtc = [_][]const u8{
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

    // 构建 WebRTC 专用 tfpsacrypto
    const tfpsacrypto = b.addLibrary(.{
        .name = "tfpsacrypto_linux_arm32_webrtc",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupCompileOptions(tfpsacrypto, b, &src_tfpsacrypto_core, &src_tfpsacrypto_builtin_webrtc);
    setupWebRTCConfig(tfpsacrypto.root_module);
    b.installArtifact(tfpsacrypto);

    // 构建 WebRTC 专用 mbedx509
    const mbedx509 = b.addLibrary(.{
        .name = "mbedx509_linux_arm32_webrtc",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupX509CompileOptions(mbedx509, b, &src_x509_webrtc);
    setupWebRTCConfig(mbedx509.root_module);
    mbedx509.root_module.linkLibrary(tfpsacrypto);
    b.installArtifact(mbedx509);

    // 构建 WebRTC 专用 mbedtls
    const mbedtls = b.addLibrary(.{
        .name = "mbedtls_linux_arm32_webrtc",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupTLSCompileOptions(mbedtls, b, &src_tls_webrtc);
    setupWebRTCConfig(mbedtls.root_module);
    mbedtls.root_module.linkLibrary(tfpsacrypto);
    mbedtls.root_module.linkLibrary(mbedx509);
    b.installArtifact(mbedtls);
}

// ============================================
// Linux x86-64 构建函数
// ============================================

fn buildLinuxX64Musl(
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
    src_tfpsacrypto_core: []const []const u8,
    src_tfpsacrypto_builtin: []const []const u8,
    src_x509: []const []const u8,
    src_tls: []const []const u8,
) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .linux,
        .abi = .musl,
    });

    // 构建链接顺序：tfpsacrypto → mbedx509 → mbedtls

    // 1. 构建 tfpsacrypto（密码学核心库）
    const tfpsacrypto = b.addLibrary(.{
        .name = "tfpsacrypto_linux_x64_musl",
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
        .name = "mbedx509_linux_x64_musl",
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
        .name = "mbedtls_linux_x64_musl",
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

fn buildLinuxX64Gnu(
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
    src_tfpsacrypto_core: []const []const u8,
    src_tfpsacrypto_builtin: []const []const u8,
    src_x509: []const []const u8,
    src_tls: []const []const u8,
) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .linux,
        .abi = .gnu,
    });

    // 构建链接顺序：tfpsacrypto → mbedx509 → mbedtls

    // 1. 构建 tfpsacrypto（密码学核心库）
    const tfpsacrypto = b.addLibrary(.{
        .name = "tfpsacrypto_linux_x64_gnu",
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
        .name = "mbedx509_linux_x64_gnu",
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
        .name = "mbedtls_linux_x64_gnu",
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

// ============================================
// Linux x86-64 WebRTC 专用构建函数
// ============================================

fn buildLinuxX64MuslWebRTC(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .linux,
        .abi = .musl,
    });
    const optimize = std.builtin.OptimizeMode.ReleaseSmall;

    // 定义源文件列表
    const src_tfpsacrypto_core = [_][]const u8{
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

    const src_x509_webrtc = [_][]const u8{
        "library/mbedtls_config.c",
        "library/x509.c",
        "library/x509_oid.c",
    };

    const src_tls_webrtc = [_][]const u8{
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

    // 构建 WebRTC 专用 tfpsacrypto
    const tfpsacrypto = b.addLibrary(.{
        .name = "tfpsacrypto_linux_x64_musl_webrtc",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupCompileOptions(tfpsacrypto, b, &src_tfpsacrypto_core, &src_tfpsacrypto_builtin_webrtc);
    setupWebRTCConfig(tfpsacrypto.root_module);
    b.installArtifact(tfpsacrypto);

    // 构建 WebRTC 专用 mbedx509
    const mbedx509 = b.addLibrary(.{
        .name = "mbedx509_linux_x64_musl_webrtc",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupX509CompileOptions(mbedx509, b, &src_x509_webrtc);
    setupWebRTCConfig(mbedx509.root_module);
    mbedx509.root_module.linkLibrary(tfpsacrypto);
    b.installArtifact(mbedx509);

    // 构建 WebRTC 专用 mbedtls
    const mbedtls = b.addLibrary(.{
        .name = "mbedtls_linux_x64_musl_webrtc",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupTLSCompileOptions(mbedtls, b, &src_tls_webrtc);
    setupWebRTCConfig(mbedtls.root_module);
    mbedtls.root_module.linkLibrary(tfpsacrypto);
    mbedtls.root_module.linkLibrary(mbedx509);
    b.installArtifact(mbedtls);
}

fn buildLinuxX64GnuWebRTC(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .linux,
        .abi = .gnu,
    });
    const optimize = std.builtin.OptimizeMode.ReleaseSmall;

    // 定义源文件列表
    const src_tfpsacrypto_core = [_][]const u8{
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

    const src_x509_webrtc = [_][]const u8{
        "library/mbedtls_config.c",
        "library/x509.c",
        "library/x509_oid.c",
    };

    const src_tls_webrtc = [_][]const u8{
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

    // 构建 WebRTC 专用 tfpsacrypto
    const tfpsacrypto = b.addLibrary(.{
        .name = "tfpsacrypto_linux_x64_gnu_webrtc",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupCompileOptions(tfpsacrypto, b, &src_tfpsacrypto_core, &src_tfpsacrypto_builtin_webrtc);
    setupWebRTCConfig(tfpsacrypto.root_module);
    b.installArtifact(tfpsacrypto);

    // 构建 WebRTC 专用 mbedx509
    const mbedx509 = b.addLibrary(.{
        .name = "mbedx509_linux_x64_gnu_webrtc",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupX509CompileOptions(mbedx509, b, &src_x509_webrtc);
    setupWebRTCConfig(mbedx509.root_module);
    mbedx509.root_module.linkLibrary(tfpsacrypto);
    b.installArtifact(mbedx509);

    // 构建 WebRTC 专用 mbedtls
    const mbedtls = b.addLibrary(.{
        .name = "mbedtls_linux_x64_gnu_webrtc",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupTLSCompileOptions(mbedtls, b, &src_tls_webrtc);
    setupWebRTCConfig(mbedtls.root_module);
    mbedtls.root_module.linkLibrary(tfpsacrypto);
    mbedtls.root_module.linkLibrary(mbedx509);
    b.installArtifact(mbedtls);
}

// ============================================
// 平台构建步骤创建函数
// ============================================

fn createPlatformBuildSteps(b: *std.Build) void {
    // 创建所有构建步骤
    const windows_step = b.step("windows", "Build Windows x86-64 platform");
    const linux_arm64_step = b.step("linux-arm64", "Build Linux ARM64 platform");
    const linux_arm32_step = b.step("linux-arm32", "Build Linux ARM32 platform");
    const linux_x64_musl_step = b.step("linux-x64-musl", "Build Linux x86-64 musl platform");
    const linux_x64_gnu_step = b.step("linux-x64-gnu", "Build Linux x86-64 gnu platform");

    // WebRTC版本步骤
    const windows_webrtc_step = b.step("windows-webrtc", "Build Windows x86-64 WebRTC optimized");
    const linux_arm64_webrtc_step = b.step("linux-arm64-webrtc", "Build Linux ARM64 WebRTC optimized");
    const linux_arm32_webrtc_step = b.step("linux-arm32-webrtc", "Build Linux ARM32 WebRTC optimized");
    const linux_x64_musl_webrtc_step = b.step("linux-x64-musl-webrtc", "Build Linux x86-64 musl WebRTC optimized");
    const linux_x64_gnu_webrtc_step = b.step("linux-x64-gnu-webrtc", "Build Linux x86-64 gnu WebRTC optimized");

    // 设置install步骤依赖所有平台步骤
    const install_step = b.getInstallStep();
    install_step.dependOn(windows_step);
    install_step.dependOn(linux_arm64_step);
    install_step.dependOn(linux_arm32_step);
    install_step.dependOn(linux_x64_musl_step);
    install_step.dependOn(linux_x64_gnu_step);

    // 添加WebRTC步骤依赖
    install_step.dependOn(windows_webrtc_step);
    install_step.dependOn(linux_arm64_webrtc_step);
    install_step.dependOn(linux_arm32_webrtc_step);
    install_step.dependOn(linux_x64_musl_webrtc_step);
    install_step.dependOn(linux_x64_gnu_webrtc_step);

    // 创建默认all步骤描述
    const all_step = b.step("all", "Build all platforms (Windows x64 + Linux ARM64/ARM32 + Linux x86-64 musl/gnu)");
    all_step.dependOn(b.getInstallStep());
}
