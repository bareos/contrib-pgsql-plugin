if ( NOT LIBPQ_H_LOCATION OR NOT LIBPQ_LOCATION )
  find_file ( PG_CONFIG pg_config DOC "Location of the pg_config executable" )
  if ( PG_CONFIG )
    execute_process ( COMMAND ${PG_CONFIG} --includedir --includedir-server
                      OUTPUT_VARIABLE INCLUDE_DIR
                      RESULT_VARIABLE EXIT_CODE
                      OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET )
    execute_process ( COMMAND ${PG_CONFIG} --libdir
                      OUTPUT_VARIABLE LIB_DIR
                      RESULT_VARIABLE EXIT_CODE
                      OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET )
    execute_process ( COMMAND ${PG_CONFIG} --version
                      OUTPUT_VARIABLE VER
                      RESULT_VARIABLE EXIT_CODE
                      OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET )
    if ( ${EXIT_CODE} EQUAL 0 )
      string ( REGEX MATCH "[0-9]+.[0-9]+.[0-9]+" PG_VERSION ${VER} )
      set ( LIBPQ_VERSION ${PG_VERSION} CACHE STRING "libpq version" FORCE )
    endif ()
    string ( REGEX REPLACE "\n" ";" INCLUDE_DIR ${INCLUDE_DIR} )
  endif ()
  if ( NOT INCLUDE_DIR OR NOT LIB_DIR )
    file ( GLOB DIRS /Library/PostgreSQL/* )
    foreach ( D ${DIRS} )
      list ( APPEND HINTS ${D} )
    endforeach ()
    file ( GLOB DIRS /opt/local/include/postgresql* )
    foreach ( D ${DIRS} )
      list ( APPEND HINTS ${D} )
    endforeach ()
    list ( APPEND SUFFIXES /include/postgresql/server/ )
    list ( APPEND SUFFIXES /server/ )
    set ( INCLUDE_DIR ${DIRS} )
    set ( LIB_DIR ${DIRS} )
  endif ()
  find_file ( LIBPQ_H_LOCATION libpq-fe.h HINTS ${INCLUDE_DIR} PATH_SUFFIXES ${SUFFIXES} DOC "Location of the pq lib header" )
  find_library ( LIBPQ_LOCATION pq HINTS ${LIB_DIR} PATH_SUFFIXES "/lib" DOC "Location of the pq lib" )
  get_filename_component ( LIBPQ_INCLUDE_DIR ${LIBPQ_H_LOCATION} DIRECTORY )
  set ( LIBPQ_INCLUDE_DIR ${LIBPQ_INCLUDE_DIR} CACHE PATH "libpq include dir" FORCE )
endif ()
include ( CMakePushCheckState )
include ( CheckCXXSourceCompiles )
include ( CheckCXXSourceRuns )

cmake_push_check_state ( RESET )
set ( CMAKE_REQUIRED_INCLUDES ${LIBPQ_INCLUDE_DIR} )
check_cxx_source_compiles ( "
#include <libpq-fe.h>
int main() {
  (void)PGRES_SINGLE_TUPLE;
}
" LIBPQ_HAS_PGRES_SINGLE_TUPLE )
if ( LIBPQ_HAS_PGRES_SINGLE_TUPLE )
  list ( APPEND DEFINES LIBPQ_HAS_PGRES_SINGLE_TUPLE )
endif ()
check_cxx_source_compiles ( "
#include <libpq-fe.h>
int main() {
  (void)PGRES_POLLING_ACTIVE;
}
" LIBPQ_HAS_PGRES_POLLING_ACTIVE )
if ( LIBPQ_HAS_PGRES_POLLING_ACTIVE )
  list ( APPEND DEFINES LIBPQ_HAS_PGRES_POLLING_ACTIVE )
endif ()
set ( CMAKE_REQUIRED_LIBRARIES ${LIBPQ_LOCATION} )
check_cxx_source_runs ( "
#include <libpq-fe.h>
int main() {
  return PQconninfoParse( \"postgresql://localhost\", NULL ) ? 0 : 1;
}" LIBPQ_SUPPORTS_URL )
if ( LIBPQ_SUPPORTS_URL )
  list ( APPEND DEFINES LIBPQ_SUPPORTS_URL )
endif ()
cmake_pop_check_state ()

include ( FindPackageHandleStandardArgs )
find_package_handle_standard_args ( PostgreSQL
                                    FOUND_VAR PostgreSQL_FOUND
                                    REQUIRED_VARS LIBPQ_LOCATION LIBPQ_H_LOCATION
                                    VERSION_VAR PG_VERSION
                                    )

add_library ( PQ IMPORTED SHARED GLOBAL )
set_target_properties ( PQ PROPERTIES
                        IMPORTED_LOCATION "${LIBPQ_LOCATION}"
                        INTERFACE_INCLUDE_DIRECTORIES "${LIBPQ_INCLUDE_DIR}"
                        INTERFACE_SYSTEM_INCLUDE_DIRECTORIES "${LIBPQ_INCLUDE_DIR}"
                        INTERFACE_COMPILE_DEFINITIONS "${DEFINES}" )
