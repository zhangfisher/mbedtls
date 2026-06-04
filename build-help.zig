const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.printAll(
        \\Mbed TLS Zig Build System - Platform-Specific Builds
        \\
        \\Usage: zig build <platform> [options]
        \\
        \\Available Platforms:
        \\  windows          Build Windows x86-64 platform
        \\  linux-arm64      Build Linux ARM64 platform
        \\  linux-arm32      Build Linux ARM32 platform
        \\  linux-x64-musl    Build Linux x86-64 musl platform
        \\  linux-x64-gnu    Build Linux x86-64 gnu platform
        \\
        \\Options:
        \\  --webrtc          Build WebRTC optimized versions (smaller, trimmed features)
        \\
        \\Examples:
        \\  zig build windows              Build only Windows platform
        \\  zig build linux-arm32 --webrtc  Build Linux ARM32 WebRTC version
        \\  zig build                        Build all platforms (default)
        \\
        \\Build Artifacts:
        \\  Libraries are installed to: zig-out/lib/
        \\  Standard versions:  mbedtls_*, mbedx509_*, tfpsacrypto_*
        \\  WebRTC versions:     *_webrtc.* (smaller, optimized for WebRTC)
        \\
    );
}
