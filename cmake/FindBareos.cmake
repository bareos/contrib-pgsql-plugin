include(GNUInstallDirs)
list(APPEND SUFFIXES bareos)

find_file(LIBBAREOS_H_LOCATION bareos.h HINTS ${INCLUDE_DIR} PATH_SUFFIXES ${SUFFIXES} DOC "Location of the bareos header")
get_filename_component(LIBBAREOS_H_DIR ${LIBBAREOS_H_LOCATION} DIRECTORY)
set(LIBBAREOS_INCLUDE_DIR ${LIBBAREOS_H_DIR} CACHE PATH "bareos include dir")

list(APPEND SUFFIXES lib lib64 lib/bareos lib64/bareos)
set(BAREOS_PLUGIN_DIR ${CMAKE_INSTALL_LIBDIR}/bareos/plugins CACHE PATH "bareos plugins dir")

include(ParseLibtoolFile)
parse_libtool(FILE libbareos.la QUIET PREFIX LIBBAREOS_LA HINTS ${CMAKE_SYSTEM_PREFIX_PATH} PATH_SUFFIXES ${SUFFIXES} DOC "Location of the bareos lib file")

if (LIBBAREOS_LA_dlname)
    if (LIBBAREOS_LA_dlname MATCHES "([0-9]+.[0-9]+.[0-9]+)")
        set(BAREOS_VERSION ${CMAKE_MATCH_1})
    endif ()
endif ()

find_library(LIBBAREOS_LOCATION ${LIBBAREOS_LA_dlname} PATH_SUFFIXES ${SUFFIXES} DOC "Location of the bareos lib")

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Bareos
        FOUND_VAR Bareos_FOUND
        REQUIRED_VARS LIBBAREOS_LOCATION LIBBAREOS_H_DIR
        VERSION_VAR BAREOS_VERSION
        )

get_filename_component(LIBBAREOS_DIR ${LIBBAREOS_LOCATION} DIRECTORY)
if (NOT "${CMAKE_INSTALL_PREFIX}/${BAREOS_PLUGIN_DIR}" STREQUAL "${LIBBAREOS_DIR}/plugins")
    message(WARNING "${CMAKE_INSTALL_PREFIX}/${BAREOS_PLUGIN_DIR} != ${LIBBAREOS_DIR}/plugins")
endif ()

add_library(bareos IMPORTED SHARED GLOBAL)
set_target_properties(bareos PROPERTIES
        IMPORTED_LOCATION "${LIBBAREOS_LOCATION}"
        INTERFACE_INCLUDE_DIRECTORIES "${LIBBAREOS_INCLUDE_DIR}"
        INTERFACE_SYSTEM_INCLUDE_DIRECTORIES "${LIBBAREOS_INCLUDE_DIR}"
        INTERFACE_COMPILE_DEFINITIONS "${DEFINES}")
target_link_libraries(bareos INTERFACE ${LIBBAREOS_LA_LIBS})
