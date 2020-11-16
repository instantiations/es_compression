#*******************************************************************************
# Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
# file for details. All rights reserved. Use of this source code is governed by
# a BSD-style license that can be found in the LICENSE file.
#
#  Contributors:
#     Seth Berman - initial version
#
#  Description:
#     This file covers the build instructions for the brotli library.
#
#  Derivation:
#     This is derived from the CMakeLists.txt file in the the brotli project
#     https://github.com/google/brotli.git.
#
#     The modifications are for building one shared library instead of three.
#*******************************************************************************

if (NOT BROTLI_BUILD)
    return()
endif ()

#------------------------------------------------------------------
# 3rd Party Module: BROTLI
#------------------------------------------------------------------
project(BROTLI_BLOB C)

#------------------------------------------------------------------
# C Source Variables
#------------------------------------------------------------------
set(BROTLI_PROJ_NAME brotli)
set(BROTLI_LIB_NAME ${BROTLI_PROJ_NAME})
set(BROTLI_FULL_LIB_NAME ${ES_PREFIX}${BROTLI_LIB_NAME}-${ES_COMPRESSION_SUFFIX}${CMAKE_SHARED_LIBRARY_SUFFIX})

include(FetchContent)

#-- BROTLI_VERSION is in the main cmake file near the top.
FetchContent_Declare(
        ${BROTLI_PROJ_NAME}
        GIT_REPOSITORY https://github.com/google/brotli.git
        GIT_TAG v${BROTLI_VERSION}
)

#-- Fetch sources and populate vars if not already done.
FetchContent_GetProperties(${BROTLI_PROJ_NAME})
string(TOLOWER "${BROTLI_PROJ_NAME}" lcName)
if (NOT ${lcName}_POPULATED)
    # Fetch the content using previously declared details
    FetchContent_Populate(${BROTLI_PROJ_NAME})
endif ()
set(SOURCE_DIR ${${lcName}_SOURCE_DIR})

#-- Build the lz4 shared library
if (WIN32)
    #-- Configure windows sources
    configure_file(
            ${CMAKE_CURRENT_SOURCE_DIR}/esbrotli.def.in
            ${CMAKE_CURRENT_BINARY_DIR}/esbrotli.def)
    configure_file(
            ${CMAKE_CURRENT_SOURCE_DIR}/esbrotli.rc.in
            ${CMAKE_CURRENT_BINARY_DIR}/esbrotli.rc)

    #-- Add windows sources
    set(BROTLI_SOURCES ${BROTLI_SOURCES}
            ${CMAKE_CURRENT_BINARY_DIR}/esbrotli.def
            ${CMAKE_CURRENT_BINARY_DIR}/esbrotli.rc)

elseif (UNIX)
    #-- Required by Solaris
    set(CMAKE_C_FLAGS "-std=c99")
    if ((CMAKE_SIZEOF_VOID_P MATCHES 8) AND NOT ES_64BIT)
        # 32-bit binaries on 64-bit platform
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -m32")
    endif ()
endif ()

# Parse version information from common/version.h. Normally we would
# define these values here and write them out to configuration file(s)
# (i.e., config.h), but in this case we parse them from
# common/version.h to be less intrusive.
function(hex_to_dec HEXADECIMAL DECIMAL)
    string(TOUPPER "${HEXADECIMAL}" _tail)
    set(_decimal 0)
    string(LENGTH "${_tail}" _tail_length)
    while (_tail_length GREATER 0)
        math(EXPR _decimal "${_decimal} * 16")
        string(SUBSTRING "${_tail}" 0 1 _digit)
        string(SUBSTRING "${_tail}" 1 -1 _tail)
        if (_digit STREQUAL "A")
            math(EXPR _decimal "${_decimal} + 10")
        elseif (_digit STREQUAL "B")
            math(EXPR _decimal "${_decimal} + 11")
        elseif (_digit STREQUAL "C")
            math(EXPR _decimal "${_decimal} + 12")
        elseif (_digit STREQUAL "D")
            math(EXPR _decimal "${_decimal} + 13")
        elseif (_digit STREQUAL "E")
            math(EXPR _decimal "${_decimal} + 14")
        elseif (_digit STREQUAL "F")
            math(EXPR _decimal "${_decimal} + 15")
        else()
            math(EXPR _decimal "${_decimal} + ${_digit}")
        endif()
        string(LENGTH "${_tail}" _tail_length)
    endwhile()
    set(${DECIMAL} ${_decimal} PARENT_SCOPE)
endfunction(hex_to_dec)

# Version information
file(STRINGS "${SOURCE_DIR}/c/common/version.h" _brotli_version_line REGEX "^#define BROTLI_VERSION (0x[0-9a-fA-F]+)$")
string(REGEX REPLACE "^#define BROTLI_VERSION 0x([0-9a-fA-F]+)$" "\\1" _brotli_version_hex "${_brotli_version_line}")
hex_to_dec("${_brotli_version_hex}" _brotli_version)
math(EXPR BROTLI_VERSION_MAJOR "${_brotli_version} >> 24")
math(EXPR BROTLI_VERSION_MINOR "(${_brotli_version} >> 12) & 4095")
math(EXPR BROTLI_VERSION_PATCH "${_brotli_version} & 4095")
set(BROTLI_VERSION "${BROTLI_VERSION_MAJOR}.${BROTLI_VERSION_MINOR}.${BROTLI_VERSION_PATCH}")
mark_as_advanced(BROTLI_VERSION BROTLI_VERSION_MAJOR BROTLI_VERSION_MINOR BROTLI_VERSION_PATCH)

# ABI Version information
file(STRINGS "${SOURCE_DIR}/c/common/version.h" _brotli_abi_info_line REGEX "^#define BROTLI_ABI_VERSION (0x[0-9a-fA-F]+)$")
string(REGEX REPLACE "^#define BROTLI_ABI_VERSION 0x([0-9a-fA-F]+)$" "\\1" _brotli_abi_info_hex "${_brotli_abi_info_line}")
hex_to_dec("${_brotli_abi_info_hex}" _brotli_abi_info)
math(EXPR BROTLI_ABI_CURRENT "${_brotli_abi_info} >> 24")
math(EXPR BROTLI_ABI_REVISION "(${_brotli_abi_info} >> 12) & 4095")
math(EXPR BROTLI_ABI_AGE "${_brotli_abi_info} & 4095")
math(EXPR BROTLI_ABI_COMPATIBILITY "${BROTLI_ABI_CURRENT} - ${BROTLI_ABI_AGE}")
mark_as_advanced(BROTLI_ABI_CURRENT BROTLI_ABI_REVISION BROTLI_ABI_AGE BROTLI_ABI_COMPATIBILITY)

if (ENABLE_SANITIZER)
    set(CMAKE_C_FLAGS " ${CMAKE_C_FLAGS} -fsanitize=${ENABLE_SANITIZER}")
    set(CMAKE_CXX_FLAGS " ${CMAKE_CXX_FLAGS} -fsanitize=${ENABLE_SANITIZER}")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=${ENABLE_SANITIZER}")

    # By default, brotli depends on undefined behavior, but setting
    # BROTLI_BUILD_PORTABLE should result in a build which does not.
    if(ENABLE_SANITIZER STREQUAL "undefined")
        add_definitions(-DBROTLI_BUILD_PORTABLE)
    endif()
endif ()

include(CheckFunctionExists)
set(LIBM_LIBRARY)
CHECK_FUNCTION_EXISTS(log2 LOG2_RES)
if(NOT LOG2_RES)
    set(orig_req_libs "${CMAKE_REQUIRED_LIBRARIES}")
    set(CMAKE_REQUIRED_LIBRARIES "${CMAKE_REQUIRED_LIBRARIES};m")
    CHECK_FUNCTION_EXISTS(log2 LOG2_LIBM_RES)
    if(LOG2_LIBM_RES)
        set(LIBM_LIBRARY "m")
        add_definitions(-DBROTLI_HAVE_LOG2=1)
    else()
        add_definitions(-DBROTLI_HAVE_LOG2=0)
    endif()

    set(CMAKE_REQUIRED_LIBRARIES "${orig_req_libs}")
    unset(LOG2_LIBM_RES)
    unset(orig_req_libs)
else()
    add_definitions(-DBROTLI_HAVE_LOG2=1)
endif()
unset(LOG2_RES)

set(BROTLI_INCLUDE_DIRS "${SOURCE_DIR}/c/include")
mark_as_advanced(BROTLI_INCLUDE_DIRS)

set(BROTLI_LIBRARIES_CORE brotlienc brotlidec brotlicommon)
set(BROTLI_LIBRARIES ${BROTLI_LIBRARIES_CORE} ${LIBM_LIBRARY})
mark_as_advanced(BROTLI_LIBRARIES)

if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    add_definitions(-DOS_LINUX)
elseif (${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD")
    add_definitions(-DOS_FREEBSD)
elseif (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    add_definitions(-DOS_MACOSX)
endif ()

function(transform_sources_list INPUT_FILE OUTPUT_FILE)
    file(READ ${INPUT_FILE} TEXT)
    string(REGEX REPLACE "\\\\\n" "~continuation~" TEXT ${TEXT})
    string(REGEX REPLACE "([a-zA-Z_][a-zA-Z0-9_]*)[\t ]*=[\t ]*([^\n]*)" "SET(\\1 \\2)" TEXT ${TEXT})
    string(REGEX REPLACE "([ \t\r\n]+)c/" "\\1${SOURCE_DIR}/c/" TEXT ${TEXT})
    string(REPLACE "~continuation~" "\n" TEXT ${TEXT})
    file(WRITE ${OUTPUT_FILE} ${TEXT})
endfunction()

transform_sources_list("${SOURCE_DIR}/scripts/sources.lst" "${CMAKE_CURRENT_BINARY_DIR}/sources.lst.cmake")
include("${CMAKE_CURRENT_BINARY_DIR}/sources.lst.cmake")

if (WIN32)
    #-- Configure windows sources
    configure_file(
            ${CMAKE_CURRENT_SOURCE_DIR}/esbrotli.rc.in
            ${CMAKE_CURRENT_BINARY_DIR}/esbrotli.rc)
    configure_file(
            ${CMAKE_CURRENT_SOURCE_DIR}/esbrotli.def.in
            ${CMAKE_CURRENT_BINARY_DIR}/esbrotli.def)

    #-- Add windows sources
    set(BROTLI_RC_SOURCES ${BROTLI_RC_SOURCES}
            ${CMAKE_CURRENT_BINARY_DIR}/esbrotli.rc
            ${CMAKE_CURRENT_BINARY_DIR}/esbrotli.def)
endif ()

include_directories(${SOURCE_DIR}/c/common)

#-- Build the shared library
add_library(${BROTLI_LIB_NAME} SHARED ${BROTLI_COMMON_C} ${BROTLI_DEC_C} ${BROTLI_ENC_C} ${BROTLI_RC_SOURCES})
code_sign_target(${BROTLI_LIB_NAME})
target_link_libraries(${BROTLI_LIB_NAME} ${LIBM_LIBRARY})
set_property(TARGET ${BROTLI_LIB_NAME} APPEND PROPERTY INCLUDE_DIRECTORIES ${BROTLI_INCLUDE_DIRS})
set_property(TARGET ${BROTLI_LIB_NAME} APPEND PROPERTY INTERFACE_INCLUDE_DIRECTORIES "${BROTLI_INCLUDE_DIRS}")
set_target_properties(${BROTLI_LIB_NAME} PROPERTIES
        VERSION "${BROTLI_ABI_COMPATIBILITY}.${BROTLI_ABI_AGE}.${BROTLI_ABI_REVISION}"
        SOVERSION "${BROTLI_ABI_COMPATIBILITY}"
        NO_SONAME TRUE
        POSITION_INDEPENDENT_CODE TRUE)
set_target_properties(${BROTLI_LIB_NAME} PROPERTIES PREFIX es)
set_target_properties(${BROTLI_LIB_NAME} PROPERTIES OUTPUT_NAME "${BROTLI_LIB_NAME}-${ES_COMPRESSION_SUFFIX}")

#-- Copy the shared library to its appropriate blob location in the dart project
if (BROTLI_INSTALL)
    add_custom_command(TARGET ${BROTLI_LIB_NAME}
            POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy
            ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${CMAKE_CFG_INTDIR}/${BROTLI_FULL_LIB_NAME}
            ${DART_LIB_DIR}/src/${BROTLI_PROJ_NAME}/blobs/${BROTLI_FULL_LIB_NAME})
endif ()