const std = @import("std");

// Mbed TLS Linux ARM 交叉编译配置
// 在 Windows 上使用 Zig 交叉编译到 Linux ARM32/ARM64
// 优化：ReleaseSmall

pub fn build(b: *std.Build) void {
    // 使用 ReleaseSmall 优化
    const optimize = std.builtin.OptimizeMode.ReleaseSmall;

    // 定义源文件组
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
    buildLinuxArm64(b, optimize, &src_x509, &src_tls);

    // Linux ARM32 交叉编译
    buildLinuxArm32(b, optimize, &src_x509, &src_tls);

    // 创建构建步骤
    const all_step = b.step("all", "Build all Linux ARM platforms (ARM64 + ARM32)");
    all_step.dependOn(b.getInstallStep());
}

fn buildLinuxArm64(
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
    src_x509: []const []const u8,
    src_tls: []const []const u8,
) void {
    // 使用 Zig 的交叉编译功能，使用 musl libc
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .aarch64,
        .os_tag = .linux,
        .abi = .musl,
    });

    // 构建 mbedx509
    const mbedx509 = b.addLibrary(.{
        .name = "mbedx509_linux_arm64",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupCompileOptions(mbedx509, b, src_x509);
    b.installArtifact(mbedx509);

    // 构建 mbedtls
    const mbedtls = b.addLibrary(.{
        .name = "mbedtls_linux_arm64",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupCompileOptions(mbedtls, b, src_tls);
    mbedtls.root_module.linkLibrary(mbedx509);
    b.installArtifact(mbedtls);
}

fn buildLinuxArm32(
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
    src_x509: []const []const u8,
    src_tls: []const []const u8,
) void {
    // 使用 Zig 的交叉编译功能，使用 musl libc
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .arm,
        .os_tag = .linux,
        .abi = .musleabihf,
    });

    // 构建 mbedx509
    const mbedx509 = b.addLibrary(.{
        .name = "mbedx509_linux_arm32",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupCompileOptions(mbedx509, b, src_x509);
    b.installArtifact(mbedx509);

    // 构建 mbedtls
    const mbedtls = b.addLibrary(.{
        .name = "mbedtls_linux_arm32",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });

    setupCompileOptions(mbedtls, b, src_tls);
    mbedtls.root_module.linkLibrary(mbedx509);
    b.installArtifact(mbedtls);
}

fn setupCompileOptions(
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
    mod.addIncludePath(b.path("tf-psa-crypto/core/compat")); // 兼容性头文件目录
    mod.addIncludePath(b.path("tf-psa-crypto/drivers/builtin/include"));
    mod.addIncludePath(b.path("tf-psa-crypto/drivers/builtin/src")); // psa_util_internal.h 位置
    mod.addIncludePath(b.path("tf-psa-crypto/extras")); // pk_internal.h 位置

    // 添加 ECP 配置作为编译器定义
    mod.addCMacro("MBEDTLS_ECP_C", "1");
    mod.addCMacro("MBEDTLS_ECP_DP_SECP256R1_ENABLED", "1");
    mod.addCMacro("MBEDTLS_ECP_DP_SECP384R1_ENABLED", "1");

    // 添加源文件，使用更多编译选项
    for (sources) |src| {
        mod.addCSourceFile(.{
            .file = b.path(src),
            .flags = &.{
                "-std=c99",
                "-Iinclude",
                "-Ilibrary",
                "-Itf-psa-crypto/include",
                "-Itf-psa-crypto/core",
            },
        });
    }
}