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

file(GLOB CommonSources ${LIBRARY_DIR}/common/*.c)
file(GLOB CompressSources ${LIBRARY_DIR}/compress/*.c)
file(GLOB DecompressSources ${LIBRARY_DIR}/decompress/*.c)
file(GLOB DictBuilderSources ${LIBRARY_DIR}/dictBuilder/*.c)
file(GLOB DeprecatedSources ${LIBRARY_DIR}/deprecated/*.c)
set(ZSTD_SOURCES
        ${CommonSources}
        ${CompressSources}
        ${DecompressSources}
        ${DictBuilderSources}
        ${DeprecatedSources})

file(GLOB CommonHeaders ${LIBRARY_DIR}/common/*.h)
file(GLOB CompressHeaders ${LIBRARY_DIR}/compress/*.h)
file(GLOB DecompressHeaders ${LIBRARY_DIR}/decompress/*.h)
file(GLOB DictBuilderHeaders ${LIBRARY_DIR}/dictBuilder/*.h)
file(GLOB DeprecatedHeaders ${LIBRARY_DIR}/deprecated/*.h)
set(ZSTD_HEADERS
        ${LIBRARY_DIR}/zstd.h
        ${CommonHeaders}
        ${CompressHeaders}
        ${DecompressHeaders}
        ${DictBuilderHeaders}
        ${DeprecatedHeaders})

include_directories(${LIBRARY_DIR}
        ${LIBRARY_DIR}/common
        ${LIBRARY_DIR}/compress
        ${LIBRARY_DIR}/decompress
        ${LIBRARY_DIR}/dictBuilder
        ${LIBRARY_DIR}/deprecated)

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
add_library(${ZSTD_LIB_NAME} SHARED ${ZSTD_HEADERS} ${ZSTD_SOURCES})
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
