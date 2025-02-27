# AOCL

This repository provides a simple build system for building individual AOCL libraries and creating a single binary for integration. The purpose of this project is to optimize CPU libraries for AMD processors.

**NOTE:**
This library will have one or more individual AOCL libraries based on user configurations. This repository will help users configure which libraries are part of the AOCL unified library.

## Table of Contents

- [AOCL](#aocl)
  - [Table of Contents](#table-of-contents)
  - [Project structure](#project-structure)
  - [Build and Install](#build-and-install)
    - [Dependencies](#dependencies)
    - [Getting Started](#getting-started)
      - [Checkout the Latest Code](#checkout-the-latest-code)
      - [Configure](#configure)
      - [Build](#build)
      - [Install](#install)
  - [List of Build Options](#list-of-build-options)
  - [Integration with Other Projects](#integration-with-other-projects)
    - [CMake](#cmake)
    - [Make](#make)

## Project Structure

The project is structured as follows:

- `aocl_blis_build.cmake`: CMake script for building AOCL-BLAS.
- `aocl_compression_build.cmake`: CMake script for building AOCL-COMPRESSION.
- `aocl_crypto_build.cmake`: CMake script for building AOCL-CRYPTO.
- `aocl_libflame_build.cmake`: CMake script for building AOCL-LAPACK.
- `aocl_libm_build.cmake`: CMake script for building AOCL-LIBM.
- `aocl_sparse_build.cmake`: CMake script for building AOCL-SPARSE.
- `aocl_utils_build.cmake`: CMake script for building AOCL-UTILS.
- `CMakeLists.txt`: Main CMake script for the AOCL project.
- `CMakePresets.json`: CMake presets for different build configurations.
- `Readme.md`: This README file.
- `presets/`: Directory containing preset configurations for different platforms.

## Build and Install

### Dependencies

#### Windows

- CMake 3.26 or higher
- Visual Studio 16 2019 or Visual Studio 17 2022
- Git
- LLVM (for OpenMP and Clang Compiler tool-chain)
- OpenSSL (3.1.3 is the minimum supported version, and max is 3.3.0)

#### Linux

- CMake 3.26 or higher
- GCC or Clang
- Git
- OpenSSL (3.1.3 is the minimum supported version, and max is 3.3.0)

### Getting Started

Same commands can be used on both Linux and Windows. The only difference is the environment setup. The default compiler and generator used will be the platform defaults.

For specific compiler and generator, use the following command:

#### Ninja and Unix Makefiles Generators

```console
cmake .. -G "Unix Makefiles" -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang
```

**Note: Replace the compiler (clang) and generator (Unix Makefiles) with the required one.**

#### Visual Studio Generator

```console
cmake .. -G "Visual Studio 16 2019" -TClangCl
```

#### Checkout the Latest Code

```console
git clone https://github.amd.com/AOCL/aocl.git
cd aocl
```

or

```console
git clone git@github.amd.com:AOCL/aocl.git
cd aocl
```

#### Configure

```console
cmake -B build -DCMAKE_INSTALL_PREFIX=install_dir
```

#### Build

```console
cmake --build build --config release -j
```

#### Install

```console
cmake --install build --config release
```

This command creates:

1. The necessary header files in the `<Install Path>/include` folder.
2. Static and dynamic library files corresponding to the AOCL library. Link with these libraries based on the functionality required.

**Note:**
1. This command creates a `<Install Path>/lib/` directory for the binaries.
2. Rightly update the include path and library path in the project to link with the installed libraries, or use `LD_LIBRARY_PATH` to point to the installed library path (`PATH` environment variable in Windows).

## List of Build Options

```console
Build Flags                             Description                                             Default         Alternate Values
--------------------------------------------------------------------------------------------------------------
BUILD_SHARED_LIBS                       Build using shared libraries                            ON              OFF
ENABLE_AOCL_UTILS                       Check if we need to include AOCL-Utils into AOCL         ON              OFF
                                        unified library
ENABLE_AOCL_BLAS                        Check if we need to include AOCL-BLAS into AOCL          OFF             ON
                                        unified library
ENABLE_AOCL_LAPACK                      Check if we need to include AOCL-LAPACK into AOCL        OFF             ON
                                        unified library
ENABLE_AOCL_SPARSE                      Check if we need to include AOCL-Sparse into AOCL        OFF             ON
                                        unified library
ENABLE_AOCL_CRYPTO                      Check if we need to include AOCL-Crypto into AOCL        OFF             ON
                                        unified library
ENABLE_AOCL_LIBM                        Check if we need to include AOCL-LibM into AOCL          OFF             ON
                                        unified library
ENABLE_AOCL_COMPRESSION                 Check if we need to include AOCL-Compression into AOCL   OFF             ON
                                        unified library
ENABLE_MULTITHREADING                   Check if we need to enable multithreading                OFF             ON
ENABLE_CBLAS                            Check if we need to enable AOCL-BLAS CBLAS interface     ON              OFF
ENABLE_AMD_FLAGS                        Check if we need to enable amd flags for AOCL-LAPACK     OFF             ON
                                        library build
ENABLE_AMD_AOCC_FLAGS                   Check if we need to enable amd aocc flags for AOCL       OFF             ON
                                        LAPACK library build
ENABLE_TRSM_PREINVERSION                Check if we need to enable trsm preinversion             ON              OFF
ENABLE_ILP64                            Check if we need to enable ILP64                         OFF             ON
ENABLE_BLAS_EXT_GEMMT                   Check if we need to enable blas external gemmt for       ON              OFF
                                        AOCL-LAPACK library build
```

## Integration with Other Projects

Following are the build systems to integrate a library/application with AOCL:

### CMake

In the CMake file, use the following:

```cmake
TARGET_INCLUDE_DIRECTORIES(target PRIVATE path/to/libaocl/include)
TARGET_LINK_LIBRARIES(target PRIVATE path/to/libaocl/binaries)
```

### Make

In the compiler flags of the Makefile, use the following:

```make
CFLAGS += -Ipath/to/libaocl/include
LDFLAGS += -Lpath/to/libaocl/binaries -laocl
```
