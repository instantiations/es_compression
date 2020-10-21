#*******************************************************************************
# Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
# file for details. All rights reserved. Use of this source code is governed by
# a BSD-style license that can be found in the LICENSE file.
#
#  Contributors:
#     Seth Berman - initial version
#
#  Description:
#     This file covers the build instructions for the lz4 library.
#*******************************************************************************

if (NOT LZ4_BUILD)
    return()
endif ()

#------------------------------------------------------------------
# 3rd Party Module: LZ4
#------------------------------------------------------------------
project(LZ4_BLOB C)

#------------------------------------------------------------------
# C Source Variables
#------------------------------------------------------------------
set(LZ4_PROJ_NAME lz4)
set(LZ4_LIB_NAME ${LZ4_PROJ_NAME})
set(LZ4_FULL_LIB_NAME ${ES_PREFIX}${LZ4_LIB_NAME}-${ES_COMPRESSION_SUFFIX}${CMAKE_SHARED_LIBRARY_SUFFIX})

include(FetchContent)

#-- LZ4_VERSION is in the main cmake file near the top.
FetchContent_Declare(
        ${LZ4_PROJ_NAME}
        GIT_REPOSITORY https://github.com/lz4/lz4.git
        GIT_TAG v${LZ4_VERSION}
)

#-- Fetch sources and populate vars if not already done.
FetchContent_GetProperties(${LZ4_PROJ_NAME})
string(TOLOWER "${LZ4_PROJ_NAME}" lcName)
if (NOT ${lcName}_POPULATED)
    # Fetch the content using previously declared details
    FetchContent_Populate(${LZ4_PROJ_NAME})
endif ()
set(SOURCE_DIR ${${lcName}_SOURCE_DIR})

#-- Set the lz4 source files
include_directories(${${lcName}_SOURCE_DIR}/lib)
set(LZ4_SOURCES
        ${SOURCE_DIR}/lib/lz4.h
        ${SOURCE_DIR}/lib/lz4.c
        ${SOURCE_DIR}/lib/lz4hc.h
        ${SOURCE_DIR}/lib/lz4hc.c
        ${SOURCE_DIR}/lib/lz4frame.h
        ${SOURCE_DIR}/lib/lz4frame.c
        ${SOURCE_DIR}/lib/xxhash.h
        ${SOURCE_DIR}/lib/xxhash.c)

#-- Build the lz4 shared library
if (WIN32)
    #-- Configure windows sources
    configure_file(
            ${CMAKE_CURRENT_SOURCE_DIR}/eslz4.def.in
            ${CMAKE_CURRENT_BINARY_DIR}/eslz4.def)
    configure_file(
            ${CMAKE_CURRENT_SOURCE_DIR}/eslz4.rc.in
            ${CMAKE_CURRENT_BINARY_DIR}/eslz4.rc)

    #-- Add windows sources
    set(LZ4_SOURCES ${LZ4_SOURCES}
            ${CMAKE_CURRENT_BINARY_DIR}/eslz4.def
            ${CMAKE_CURRENT_BINARY_DIR}/eslz4.rc)

elseif (UNIX)
    #-- Required by Solaris
    set(CMAKE_C_FLAGS "-std=c99")
    if ((CMAKE_SIZEOF_VOID_P MATCHES 8) AND NOT ES_64BIT)
        # 32-bit binaries on 64-bit platform
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -m32")
    endif ()
endif ()

#-- Build the shared library
add_library(${LZ4_LIB_NAME} SHARED ${LZ4_SOURCES})
code_sign_target(${LZ4_LIB_NAME})
set_target_properties(${LZ4_LIB_NAME} PROPERTIES PREFIX es)
set_target_properties(${LZ4_LIB_NAME} PROPERTIES OUTPUT_NAME "${LZ4_LIB_NAME}-${ES_COMPRESSION_SUFFIX}")

#-- Copy the shared library to its appropriate blob location in the dart project
if (LZ4_INSTALL)
    add_custom_command(TARGET ${LZ4_LIB_NAME}
            POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy
            ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${CMAKE_CFG_INTDIR}/${LZ4_FULL_LIB_NAME}
            ${DART_LIB_DIR}/src/${LZ4_PROJ_NAME}/blobs/${LZ4_FULL_LIB_NAME})
endif ()