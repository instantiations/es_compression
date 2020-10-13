#*******************************************************************************
#  Copyright (c) 2020, Seth Berman (Instantiations, Inc). Please see the AUTHORS
#  file for details. All rights reserved. Use of this source code is governed by
#  a BSD-style license that can be found in the LICENSE file.
#
#  Contributors:
#     Seth Berman - initial version
#
#  Description:
#     This file covers the build instructions for supported compression libraries.
#
#     The layout of this file is logically organized as follows
#     - Windows Code Signing
#     - Versioning
#     - Options (i.e. Tests, Docs...)
#     - Platform/Compiler related settings
#     - Per-module build instructions
#
#  Build Instructions:
#
#  Windows
#     Visual Studio 19 64-bit
#     >mkdir build && cd build
#     >cmake .. -G"Visual Studio 16 2019" -A x64
#     >msbuild es_compression_blobs.sln /p:Configuration=Release /p:Platform=x64 /m
#     >ctest -C "Release"
#
#     Visual Studio 19 32-bit
#     >mkdir build && cd build
#     >cmake .. -G"Visual Studio 16 2019" -A Win32
#     >msbuild es_compression_blobs.sln /p:Configuration=Release /p:Platform=Win32 /m
#     >ctest -C "Release"
#
#     Visual Studio 17 64-bit
#     >mkdir build && cd build
#     >cmake .. -G"Visual Studio 15 2017 Win64"
#     >msbuild es_compression_blobs.sln /p:Configuration=Release /p:Platform=x64 /m
#     >ctest -C "Release"
#
#     Visual Studio 17 32-bit
#     >mkdir build && cd build
#     >cmake .. -G"Visual Studio 15 2017"
#     >msbuild es_compression_blobs.sln /p:Configuration=Release /p:Platform=Win32 /m
#     >ctest -C "Release"
#
#     Mingw-w64
#     >mkdir build && cd build
#     >cmake .. -G"MinGW Makefiles"
#     >mingw32-make docs
#
#  Linux
#     Linux 64-bit (or Linux 32-bit on a 32-bit Linux OS)
#     >mkdir build && cd build
#     >cmake .. -G"Unix Makefiles"
#     >mingw32-make
#     >make
#
#     Linux 32-bit (cross-compile on 64-bit machine)
#     >mkdir build && cd build
#     >cmake .. -DES_64BIT=OFF -G"Unix Makefiles"
#     >make
#
#*******************************************************************************/
cmake_minimum_required(VERSION 3.0..3.13)
project(es_compression_blobs)
message(STATUS "CMake version: " ${CMAKE_VERSION})
message(STATUS "CMake system name: " ${CMAKE_SYSTEM_NAME})

if (POLICY CMP0075)
    cmake_policy(SET CMP0075 NEW)
endif ()

#-- RelWithDebInfo (None Debug Release RelWithDebInfo MinSizeRel)
if (CMAKE_BUILD_TYPE STREQUAL "")
    set(DEFAULT_BUILD_TYPE "Debug")
    message(STATUS "CMake build type not specified. DEFAULT: ${DEFAULT_BUILD_TYPE}")
    set(CMAKE_BUILD_TYPE ${DEFAULT_BUILD_TYPE}
            CACHE STRING "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel" FORCE)
else ()
    message(STATUS "CMake build type: " ${CMAKE_BUILD_TYPE})
endif ()

#-- Do not allow in-source builds.
if (CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_CURRENT_BINARY_DIR)
    message(FATAL_ERROR
            "Please create a separate folder called 'build' and do the builds in there.\n"
            "Git/Mercurial will ignore $ROOT/build and we can keep things clean\n"
            "Example:\n"
            "  rm -rf CMakeFiles CMakeCache.txt\n"
            "  mkdir build\n"
            "  cd build\n"
            "  cmake ..")
endif ()

#------------------------------------------------------------------
# Windows Code Signing
#------------------------------------------------------------------
if (WIN32)
    #-- Instantiations Tools Repo. Only necessary for code-signing
    set(INST_TOOLS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../../common-devel)
    if (EXISTS ${INST_TOOLS_DIR}/cmake/modules/CodeSign.cmake)
        #-- Set the default cmake build module path
        #-- the code_sign_target is used here along with certs
        #-- so this is not something that is pushed up into Github
        #-- However, anyone should still be able to build unsigned libs
        set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH}
                ${INST_TOOLS_DIR}/cmake/modules
                ${INST_TOOLS_DIR}/cmake/macros)

        #-- Code Signing
        #-- option(SIGNCODE "Sign executables and dlls with digital certificate" ON)
        #-- Macro: code_sign_target(target)
        include(CodeSign)
    else ()
        message(STATUS "Skipping Code Signing")
        MACRO(code_sign_target target)
            #-- Take no action
        ENDMACRO()
    endif ()
endif ()

#------------------------------------------------------------------
# Libraries Version Settings
#------------------------------------------------------------------
#-- Today
string(TIMESTAMP ES_COMPRESSION_DATE "%m/%d/%y")
string(TIMESTAMP ES_COMPRESSION_YEAR "%Y")

#-- LZ4 Version: 1.9.2
set(LZ4_VERSION_MAJOR 1)
set(LZ4_VERSION_MINOR 9)
set(LZ4_VERSION_MOD 2)
#-- The period-delimited 3 position format (1.0.0)
set(LZ4_VERSION "${LZ4_VERSION_MAJOR}.${LZ4_VERSION_MINOR}.${LZ4_VERSION_MOD}")

#------------------------------------------------------------------
# Option Settings
#------------------------------------------------------------------

#------------------------------------------------------------------
# Output Settings
#------------------------------------------------------------------
set(DART_LIB_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../lib)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

#------------------------------------------------------------------
# Bitness Settings
#------------------------------------------------------------------
if (CMAKE_SIZEOF_VOID_P MATCHES 8)
    set(ES_BITS 64)
    if (${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
        set(ES_64BIT TRUE CACHE BOOL "Build 64-bit binaries")
    else ()
        set(ES_64BIT TRUE INTERNAL)
    endif ()
else ()
    set(ES_BITS 32)
endif ()

#------------------------------------------------------------------
# GCC Settings
#------------------------------------------------------------------
if (CMAKE_COMPILER_IS_GNUCC)
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -static-libgcc")
    if (UNIX AND NOT APPLE)
        if (ES_64BIT AND (${CMAKE_SYSTEM_NAME} STREQUAL "Linux"))
            set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} -fPIC")
            set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")
        elseif (CMAKE_SIZEOF_VOID_P MATCHES 8)
            # 32-bit binaries on 64-bit platform
            # Command for prepare platform eviropment:
            # sudo apt-get install g++-multilib libc6-dev-i386
            set(CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS} -m32")
            set(CMAKE_ASM_FLAGS "${CMAKE_C_FLAGS} -m32")
            set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -m32")
            set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS} -m32")
        endif ()
    endif ()
endif ()

#------------------------------------------------------------------
# MINGW Settings
#------------------------------------------------------------------
if (MINGW)
    #-- Do not rely on this being defined in mingw...it just happens to be defined when using
    #-- gnu standard...but not c standard
    add_definitions(-DWIN32)
    if (NOT ES_64BIT)
        set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--enable-stdcall-fixup")
    endif ()
endif ()

#------------------------------------------------------------------
# Microsoft Visual Studio Settings
#------------------------------------------------------------------
if (MSVC)
    list(APPEND ES_COMPRESSION_DEFS -D_CRT_SECURE_NO_WARNINGS)
    list(APPEND ES_COMPRESSION_DEFS -D_WINSOCK_DEPRECATED_NO_WARNINGS)
    list(APPEND ES_COMPRESSION_DEFS -D_CRT_NONSTDC_NO_DEPRECATE)

    #-- If using Microsoft's compiler, then replace the "/MD" flag for each
    #-- build type with "/MT" so we get static compilation
    foreach (flag_var
            CMAKE_C_FLAGS
            CMAKE_C_FLAGS_DEBUG
            CMAKE_C_FLAGS_RELEASE
            CMAKE_C_FLAGS_MINSIZEREL
            CMAKE_C_FLAGS_RELWITHDEBINFO
            CMAKE_CXX_FLAGS
            CMAKE_CXX_FLAGS_DEBUG
            CMAKE_CXX_FLAGS_RELEASE
            CMAKE_CXX_FLAGS_MINSIZEREL
            CMAKE_CXX_FLAGS_RELWITHDEBINFO)
        if (${flag_var} MATCHES "/MD")
            string(REGEX REPLACE "/MD" "/MT" msvc_flag_var "${${flag_var}}")
            set(${flag_var} ${msvc_flag_var})
        endif (${flag_var} MATCHES "/MD")
    endforeach ()

    #-- Disable generation of embedded manifest file...which is now the default
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /MANIFEST:NO")

    #-- Disable incremental linking...which is now the default
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /INCREMENTAL:NO")

    # Mark 32 bit executables large address aware so they can use > 2GB address space
    if ((CMAKE_SIZEOF_VOID_P MATCHES 4) OR (NOT ES_64BIT))
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /LARGEADDRESSAWARE")
    endif ()

endif ()

#------------------------------------------------------------------
# DEP & ASLR Settings
#------------------------------------------------------------------
if (MSVC)
    message(STATUS "Enabling DEP & ASLR")
    # All of these options are on by default for the latest MS compiler versions; still it's worth to keep them here.
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /DYNAMICBASE /NXCOMPAT")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /DYNAMICBASE /NXCOMPAT")
    set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} /DYNAMICBASE /NXCOMPAT")
    if (ES_64BIT)
        message(STATUS "Enabling high entropy ASLR")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /HIGHENTROPYVA")
        set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /HIGHENTROPYVA")
        set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} /HIGHENTROPYVA")
    endif ()
elseif (MINGW)
    message(STATUS "Enabling DEP & ASLR")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--dynamicbase -Wl,--nxcompat")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--dynamicbase -Wl,--nxcompat")
    set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -Wl,--dynamicbase -Wl,--nxcompat")
    if (ES_64BIT)
        message(STATUS "Enabling high entropy ASLR")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--high-entropy-va")
        set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--high-entropy-va")
        set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -Wl,--high-entropy-va")
    endif ()
elseif (WIN32)
    message(WARNING "****** DEP & ASLR are not enabled for this windows build system")
endif ()

#-- Prefix to be used for all libraries.
#-- Note: This is also referenced in es_compression:common/ffi/openlibrary.dart
set(ES_PREFIX es)

if (WIN32)
    set(ES_COMPRESSION_SUFFIX "win${ES_BITS}")
elseif (UNIX AND NOT APPLE)
    #-- Add unix flavor build defs
    if (${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
        set(ES_COMPRESSION_SUFFIX "linux${ES_BITS}")
    else ()
        message(FATAL_ERROR "${VM_TARGET_ARCH} is not supported")
    endif ()
elseif (APPLE)
    set(ES_COMPRESSION_SUFFIX "mac${ES_BITS}")
endif ()

#------------------------------------------------------------------
# LZ4 Library Build
#------------------------------------------------------------------
add_subdirectory(lz4)

