# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the Mbed TLS repository with Zig build system integration. Mbed TLS is a C library implementing X.509 certificate manipulation and TLS/DTLS protocols. The project includes:

- **C library core**: `library/` (TLS, X.509, SSL implementations)
- **Headers**: `include/mbedtls/` (public API)
- **Zig bindings**: `src/` (Zig wrapper module)
- **Submodules**: `framework/` and `tf-psa-crypto/` (PSA Cryptography API)

## Build Commands

### CMake Build (Primary)
```bash
# Standard build (requires submodules initialized)
mkdir build && cd build
cmake ..
cmake --build .

# Run tests
ctest

# Build with shared libraries
cmake -DUSE_SHARED_MBEDTLS_LIBRARY=On ..
```

### Zig Build
```bash
# Build the Zig module/executable
zig build

# Run Zig tests
zig build test

# Run the Zig executable
zig build run
```

### Test Execution
```bash
# Basic CMake tests
cd build && ctest

# Comprehensive test suite (requires Unix shell + OpenSSL)
tests/ssl-opt.sh
tests/compat.sh
tests/scripts/all.sh
```

## Architecture

### Library Dependency Chain
```
libmbedtls (TLS)
    ↓
libmbedx509 (X.509)
    ↓
libtfpsacrypto (Crypto, also as libmbedcrypto)
```

Link order matters for some linkers: `-lmbedtls -lmbedx509 -ltfpsacrypto`

### Module Structure

**Zig Integration**:
- `build.zig` defines Zig build steps and module configuration
- `src/root.zig` is the Zig module entry point (public API surface)
- `src/main.zig` provides a CLI interface
- The Zig module is exposed as "mbedtls" for consumers

**C Library Organization**:
- `library/` contains all C source files
- `include/mbedtls/` contains public headers
- `tf-psa-crypto/` provides PSA Crypto API implementation
- Configuration: `include/mbedtls/mbedtls_config.h` and `tf-psa-crypto/include/psa/crypto_config.h`

### Submodules

The repository contains two Git submodules that must be initialized:
```bash
git submodule update --init --recursive
```

## Configuration

- **TLS/X.509 options**: `include/mbedtls/mbedtls_config.h`
- **Crypto options**: `tf-psa-crypto/include/psa/crypto_config.h`
- **Programmatic config**: `scripts/config.py --help`

## Development Branch Requirements

The development branch requires generating files not included in git:
```bash
# Install Python dependencies
python3 -m pip install --user -r scripts/basic.requirements.txt

# Generate all files
framework/scripts/make_generated_files.py

# Or let CMake auto-generate on non-Windows
```

## Important Files

- `CMakeLists.txt` - Main CMake build configuration
- `build.zig` - Zig build system integration
- `BRANCHES.md` - Branch maintenance policy
- `CONTRIBUTING.md` - Contribution guidelines (requires DCO sign-off)
- `ChangeLog.d/` - Unreleased changelog entries

## Build Types

Available CMake build types:
- `Release` - Optimized (default)
- `Debug` - Debug symbols, no optimization
- `Coverage` - Code coverage + debug info
- `ASan`/`ASanDbg` - AddressSanitizer
- `MemSan`/`MemSanDbg` - MemorySanitizer
- `Check` - Warnings as errors
- `TSan`/`TSanDbg` - ThreadSanitizer

## License

Dual licensed: Apache-2.0 OR GPL-2.0-or-later. All contributions require DCO sign-off (`Signed-off-by:` line in commits).
