#*******************************************************************************
# Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
# file for details. All rights reserved. Use of this source code is governed by
# a BSD-style license that can be found in the LICENSE file.
#
#  Contributors:
#     Seth Berman - initial version
#
#  Description:
#     This file covers the build instructions for the zstd (ZStandard) library.
#*******************************************************************************

if (NOT ZSTD_BUILD)
    return()
endif ()

#------------------------------------------------------------------
# 3rd Party Module: ZSTD
#------------------------------------------------------------------
project(ZSTD_BLOB C)

#------------------------------------------------------------------
# C Source Variables
#------------------------------------------------------------------
set(ZSTD_PROJ_NAME zstd)
set(ZSTD_LIB_NAME ${ZSTD_PROJ_NAME})
set(ZSTD_FULL_LIB_NAME ${ES_PREFIX}${ZSTD_LIB_NAME}-${ES_COMPRESSION_SUFFIX}${CMAKE_SHARED_LIBRARY_SUFFIX})

include(FetchContent)

#-- ZSTD_VERSION is in the main cmake file near the top.
FetchContent_Declare(
        ${ZSTD_PROJ_NAME}
        GIT_REPOSITORY https://github.com/facebook/zstd.git
        GIT_TAG v${ZSTD_VERSION}
)

#-- Fetch sources and populate vars if not already done.
FetchContent_GetProperties(${ZSTD_PROJ_NAME})
string(TOLOWER "${ZSTD_PROJ_NAME}" lcName)
if (NOT ${lcName}_POPULATED)
    # Fetch the content using previously declared details
    FetchContent_Populate(${ZSTD_PROJ_NAME})
endif ()

#-- Set the zstd source files
set(LIBRARY_DIR ${${lcName}_SOURCE_DIR}/lib)
set(ZSTD_SOURCES
        ${LIBRARY_DIR}/common/debug.c
        ${LIBRARY_DIR}/common/entropy_common.c
        ${LIBRARY_DIR}/common/error_private.c
        ${LIBRARY_DIR}/common/fse_decompress.c
        ${LIBRARY_DIR}/common/pool.c
        ${LIBRARY_DIR}/common/threading.c
        ${LIBRARY_DIR}/common/xxhash.c
        ${LIBRARY_DIR}/common/zstd_common.c
        ${LIBRARY_DIR}/compress/fse_compress.c
        ${LIBRARY_DIR}/compress/hist.c
        ${LIBRARY_DIR}/compress/huf_compress.c
        ${LIBRARY_DIR}/compress/zstdmt_compress.c
        ${LIBRARY_DIR}/compress/zstd_compress.c
        ${LIBRARY_DIR}/compress/zstd_compress_literals.c
        ${LIBRARY_DIR}/compress/zstd_compress_sequences.c
        ${LIBRARY_DIR}/compress/zstd_compress_superblock.c
        ${LIBRARY_DIR}/compress/zstd_double_fast.c
        ${LIBRARY_DIR}/compress/zstd_fast.c
        ${LIBRARY_DIR}/compress/zstd_lazy.c
        ${LIBRARY_DIR}/compress/zstd_ldm.c
        ${LIBRARY_DIR}/compress/zstd_opt.c
        ${LIBRARY_DIR}/decompress/huf_decompress.c
        ${LIBRARY_DIR}/decompress/zstd_ddict.c
        ${LIBRARY_DIR}/decompress/zstd_decompress.c
        ${LIBRARY_DIR}/decompress/zstd_decompress_block.c
        ${LIBRARY_DIR}/dictBuilder/cover.c
        ${LIBRARY_DIR}/dictBuilder/divsufsort.c
        ${LIBRARY_DIR}/dictBuilder/fastcover.c
        ${LIBRARY_DIR}/dictBuilder/zdict.c
        ${LIBRARY_DIR}/deprecated/zbuff_common.c
        ${LIBRARY_DIR}/deprecated/zbuff_compress.c
        ${LIBRARY_DIR}/deprecated/zbuff_decompress.c)

set(ZSTD_HEADERS
        ${LIBRARY_DIR}/zstd.h
        ${LIBRARY_DIR}/common/bitstream.h
        ${LIBRARY_DIR}/common/compiler.h
        ${LIBRARY_DIR}/common/cpu.h
        ${LIBRARY_DIR}/common/debug.h
        ${LIBRARY_DIR}/common/error_private.h
        ${LIBRARY_DIR}/common/fse.h
        ${LIBRARY_DIR}/common/huf.h
        ${LIBRARY_DIR}/common/mem.h
        ${LIBRARY_DIR}/common/pool.h
        ${LIBRARY_DIR}/common/threading.h
        ${LIBRARY_DIR}/common/zstd_errors.h
        ${LIBRARY_DIR}/common/zstd_internal.h
        ${LIBRARY_DIR}/compress/hist.h
        ${LIBRARY_DIR}/compress/zstdmt_compress.h
        ${LIBRARY_DIR}/compress/zstd_compress_internal.h
        ${LIBRARY_DIR}/compress/zstd_compress_literals.h
        ${LIBRARY_DIR}/compress/zstd_compress_sequences.h
        ${LIBRARY_DIR}/compress/zstd_compress_superblock.h
        ${LIBRARY_DIR}/compress/zstd_double_fast.h
        ${LIBRARY_DIR}/compress/zstd_fast.h
        ${LIBRARY_DIR}/compress/zstd_lazy.h
        ${LIBRARY_DIR}/compress/zstd_ldm.h
        ${LIBRARY_DIR}/compress/zstd_opt.h
        ${LIBRARY_DIR}/decompress/zstd_ddict.h
        ${LIBRARY_DIR}/decompress/zstd_decompress_block.h
        ${LIBRARY_DIR}/decompress/zstd_decompress_internal.h
        ${LIBRARY_DIR}/dictBuilder/zdict.h
        ${LIBRARY_DIR}/dictBuilder/cover.h
        ${LIBRARY_DIR}/deprecated/zbuff.h)

include_directories(${LIBRARY_DIR}
        ${LIBRARY_DIR}/common
        ${LIBRARY_DIR}/compress
        ${LIBRARY_DIR}/decompress
        ${LIBRARY_DIR}/dictBuilder)

#-- Build the lz4 shared library
if (WIN32)
    #-- Configure windows sources
    configure_file(
            ${CMAKE_CURRENT_SOURCE_DIR}/eszstd.def.in
            ${CMAKE_CURRENT_BINARY_DIR}/eszstd.def)
    configure_file(
            ${CMAKE_CURRENT_SOURCE_DIR}/eszstd.rc.in
            ${CMAKE_CURRENT_BINARY_DIR}/eszstd.rc)

    #-- Add windows sources
    set(ZSTD_SOURCES ${ZSTD_SOURCES}
            ${CMAKE_CURRENT_BINARY_DIR}/eszstd.def
            ${CMAKE_CURRENT_BINARY_DIR}/eszstd.rc)

elseif (UNIX)
    #-- Required by Solaris
    set(CMAKE_C_FLAGS "-std=c99")
    if ((CMAKE_SIZEOF_VOID_P MATCHES 8) AND NOT ES_64BIT)
        # 32-bit binaries on 64-bit platform
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -m32")
    endif ()
endif ()

#-- Build the shared library
add_library(${ZSTD_LIB_NAME} SHARED ${ZSTD_SOURCES})
set_property(TARGET ${ZSTD_LIB_NAME} APPEND PROPERTY COMPILE_DEFINITIONS "ZSTD_MULTITHREAD")
code_sign_target(${ZSTD_LIB_NAME})
set_target_properties(${ZSTD_LIB_NAME} PROPERTIES PREFIX es)
set_target_properties(${ZSTD_LIB_NAME} PROPERTIES OUTPUT_NAME "${ZSTD_LIB_NAME}-${ES_COMPRESSION_SUFFIX}")
if (UNIX)
    find_package(Threads)
    target_link_libraries(${ZSTD_LIB_NAME} ${CMAKE_THREAD_LIBS_INIT})
endif ()

#-- Copy the shared library to its appropriate blob location in the dart project
if (ZSTD_INSTALL)
    add_custom_command(TARGET ${ZSTD_LIB_NAME}
            POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy
            ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${CMAKE_CFG_INTDIR}/${ZSTD_FULL_LIB_NAME}
            ${DART_LIB_DIR}/src/${ZSTD_PROJ_NAME}/blobs/${ZSTD_FULL_LIB_NAME})
endif ()