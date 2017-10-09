list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")
cmake_minimum_required(VERSION 3.6)
project(bareos-filedaemon-pgsql VERSION 2.2.0.1)

set(CMAKE_CXX_STANDARD 11)
find_package(PostgreSQL REQUIRED)
find_package(Bareos REQUIRED)

set(SOURCES
        keylist.c
        keylist.h
        parseconfig.c
        parseconfig.h
        pgsql-archlog.c
        pgsql-fd.c
        pgsql-restore.c
        pgsqllib.c
        pgsqllib.h
        pluglib.c
        pluglib.h
        utils.c
        utils.h)
foreach (F ${SOURCES})
    if (F MATCHES ".c$")
        set_source_files_properties(${F} PROPERTIES LANGUAGE CXX)
    endif ()
endforeach ()
add_library(pgsql-fd MODULE
        pgsql-fd.c
        keylist.c keylist.h
        parseconfig.c parseconfig.h
        pluglib.c pluglib.h
        utils.c utils.h
        pgsql-tables.sql pgsql-grants.sql pgsql.conf
        )
set_target_properties(pgsql-fd PROPERTIES PREFIX "")
target_link_libraries(pgsql-fd PUBLIC PQ bareos)

add_executable(pgsql-archlog pgsql-archlog.c parseconfig.c keylist.c pgsqllib.c utils.c pluglib.c)
target_link_libraries(pgsql-archlog PUBLIC PQ bareos)

add_executable(pgsql-restore pgsql-restore.c parseconfig.c keylist.c pgsqllib.c utils.c pluglib.c)
target_link_libraries(pgsql-restore PUBLIC PQ bareos)

get_filename_component ( RPATH ${LIBBAREOS_LA} DIRECTORY )
set_target_properties ( pgsql-restore pgsql-archlog pgsql-fd PROPERTIES INSTALL_RPATH "${RPATH}" )

install(TARGETS pgsql-fd pgsql-archlog pgsql-restore LIBRARY DESTINATION ${BAREOS_PLUGIN_DIR} RUNTIME DESTINATION sbin)
install(FILES pgsql.conf DESTINATION etc/bareos/ RENAME pgsql.conf.example)

list(APPEND CPACK_SOURCE_IGNORE_FILES "/cmake-build.*/")
list(APPEND CPACK_SOURCE_IGNORE_FILES "/.git/")
list(APPEND CPACK_SOURCE_IGNORE_FILES "/.idea/")
set(CPACK_PACKAGE_VERSION_MAJOR ${bareos-filedaemon-pgsql_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${bareos-filedaemon-pgsql_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${bareos-filedaemon-pgsql_VERSION_PATCH})
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "PostgreSQL online backup and recovery plugin (c) Inteos Sp. z o.o.")
set(CPACK_BINARY_TGZ ON)
set(CPACK_BINARY_RPM ON)
set(CPACK_BINARY_STGZ OFF)
set(CPACK_BINARY_TZ OFF)
set(CPACK_SOURCE_TGZ ON)
set(CPACK_SOURCE_ZTGZ OFF)
set(CPACK_SOURCE_TBZ2 OFF)
set(CPACK_SOURCE_TXZ OFF)
set(CPACK_SOURCE_TZ OFF)
set(CPACK_PROJECT_CONFIG_FILE ${CMAKE_BINARY_DIR}/CPack.cmake)
include(CPack)
configure_file(CPack.cmake.in CPack.cmake @ONLY)
