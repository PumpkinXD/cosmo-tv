# CMake toolchain for Cosmopolitan Libc
#
# One file for both architectures: the only thing that differs is the compiler
# name, and that is derived from $ENV{ARCH} which tv/Makefile exports per arch.
# Architecture-specific details (ape.lds vs aarch64.lds, -fportcosmo, page size,
# libcxx paths) are injected by cosmocross, so CMake never needs to know them.
#
# Handled entirely by tv/Makefile through environment variables, because the
# toolchain file is re-read during every try_compile and env vars are inherited:
#   ARCH  CC  CXX  AR  RANLIB  COSMOS  COSMOCC

# makes tvision take the if(NOT WIN32) branch that looks for ncursesw/tinfow
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR "$ENV{ARCH}")

set(CMAKE_C_COMPILER   "$ENV{CC}"  CACHE FILEPATH "")
set(CMAKE_CXX_COMPILER "$ENV{CXX}" CACHE FILEPATH "")
set(CMAKE_AR           "$ENV{AR}"     CACHE FILEPATH "")
set(CMAKE_RANLIB       "$ENV{RANLIB}" CACHE FILEPATH "")

# CMake must not link and run a probe binary; APE needs binfmt_misc to execute
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# tvision calls TEST_BIG_ENDIAN. On CMake >= 3.20 these variables short-circuit
# it, skipping the probe entirely — both targets are little-endian.
set(CMAKE_C_BYTE_ORDER   LITTLE_ENDIAN)
set(CMAKE_CXX_BYTE_ORDER LITTLE_ENDIAN)

# search only the sysroot, never the host — otherwise find_library happily
# returns /usr/lib/libncursesw.so and linking dies much later
set(CMAKE_FIND_ROOT_PATH "$ENV{COSMOS}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")

set(CMAKE_PREFIX_PATH "$ENV{COSMOS}")
set(CMAKE_INSTALL_PREFIX "$ENV{COSMOS}" CACHE PATH "")

# tvision asks for cxx_std_14; cosmocross compiles GNU dialect
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS ON)

set(BUILD_SHARED_LIBS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE OFF)
