# Set C++17 for the whole build if not otherwise requested
#
# This is the easiest way to push up a C++17 requirement for AMReX and
# openPMD-api until they increase their requirement.
#
macro(set_cxx17_superbuild)
    if(NOT DEFINED CMAKE_CXX_STANDARD)
        set(CMAKE_CXX_STANDARD 17)
    endif()
    if(NOT DEFINED CMAKE_CXX_EXTENSIONS)
        set(CMAKE_CXX_EXTENSIONS OFF)
    endif()
    if(NOT DEFINED CMAKE_CXX_STANDARD_REQUIRED)
        set(CMAKE_CXX_STANDARD_REQUIRED ON)
    endif()

    if(NOT DEFINED CMAKE_CUDA_STANDARD)
        set(CMAKE_CUDA_STANDARD 17)
    endif()
    if(NOT DEFINED CMAKE_CUDA_EXTENSIONS)
        set(CMAKE_CUDA_EXTENSIONS OFF)
    endif()
    if(NOT DEFINED CMAKE_CUDA_STANDARD_REQUIRED)
        set(CMAKE_CUDA_STANDARD_REQUIRED ON)
    endif()
endmacro()


# find the CCache tool and use it if found
#
macro(set_ccache)
    find_program(CCACHE_PROGRAM ccache)
    if(CCACHE_PROGRAM)
        set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
        if(ImpactX_COMPUTE STREQUAL CUDA)
            set(CMAKE_CUDA_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
        endif()
        message(STATUS "Found CCache: ${CCACHE_PROGRAM}")
    else()
        message(STATUS "Could NOT find CCache")
    endif()
    mark_as_advanced(CCACHE_PROGRAM)
endmacro()


# set names and paths of temporary build directories
# the defaults in CMake are sub-ideal for historic reasons, lets make them more
# Unix-ish and portable.
#
macro(impactx_set_default_build_dirs)
    if(NOT CMAKE_ARCHIVE_OUTPUT_DIRECTORY)
        set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
                CACHE PATH "Build directory for archives")
        mark_as_advanced(CMAKE_ARCHIVE_OUTPUT_DIRECTORY)
    endif()
    if(NOT CMAKE_LIBRARY_OUTPUT_DIRECTORY)
        set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
                CACHE PATH "Build directory for libraries")
        mark_as_advanced(CMAKE_LIBRARY_OUTPUT_DIRECTORY)
    endif()
    if(NOT CMAKE_RUNTIME_OUTPUT_DIRECTORY)
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
                CACHE PATH "Build directory for binaries")
        mark_as_advanced(CMAKE_RUNTIME_OUTPUT_DIRECTORY)
    endif()
    if(NOT CMAKE_PYTHON_OUTPUT_DIRECTORY)
        set(CMAKE_PYTHON_OUTPUT_DIRECTORY
            "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/site-packages"
            CACHE PATH "Build directory for python modules"
        )
    endif()
endmacro()


# set names and paths of install directories
# the defaults in CMake are sub-ideal for historic reasons, lets make them more
# Unix-ish and portable.
#
macro(impactx_set_default_install_dirs)
    if(CMAKE_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR)
        include(GNUInstallDirs)
        if(NOT CMAKE_INSTALL_CMAKEDIR)
            set(CMAKE_INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake"
                    CACHE PATH "CMake config package location for installed targets")
            if(WIN32)
                set(CMAKE_INSTALL_LIBDIR Lib
                        CACHE PATH "Object code libraries")
                set_property(CACHE CMAKE_INSTALL_CMAKEDIR PROPERTY VALUE "cmake")
            endif()
            mark_as_advanced(CMAKE_INSTALL_CMAKEDIR)
        endif()
    endif()

    if(WIN32)
        set(ImpactX_INSTALL_CMAKEDIR "${CMAKE_INSTALL_CMAKEDIR}")
    else()
        set(ImpactX_INSTALL_CMAKEDIR "${CMAKE_INSTALL_CMAKEDIR}/ImpactX")
    endif()
endmacro()


# set names and paths for Python modules
# this needs to be slightly delayed until we found Python and know its
# major and minor version number
#
macro(impactx_set_default_install_dirs_python)
    if(CMAKE_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR)
        # Python install and build output dirs
        if(NOT CMAKE_INSTALL_PYTHONDIR)
            if(WIN32)
                set(CMAKE_INSTALL_PYTHONDIR_DEFAULT
                    "${CMAKE_INSTALL_LIBDIR}/site-packages"
                )
            else()
                set(CMAKE_INSTALL_PYTHONDIR_DEFAULT
                    "${CMAKE_INSTALL_LIBDIR}/python${Python_VERSION_MAJOR}.${Python_VERSION_MINOR}/site-packages"
                )
            endif()
            set(CMAKE_INSTALL_PYTHONDIR "${CMAKE_INSTALL_PYTHONDIR_DEFAULT}"
                CACHE STRING "Location for installed python package"
            )
        endif()
    endif()
endmacro()


# function to set the PYTHONPATH on a test
# this avoids that we need to install our python packages to run ctest
#
function(impactx_test_set_pythonpath test_name)
    if(WIN32)
        string(REPLACE ";" "\\;" WIN_PYTHONPATH "$ENV{PYTHONPATH}")
        string(REGEX REPLACE "/" "\\\\" WIN_PYTHON_OUTPUT_DIRECTORY ${CMAKE_PYTHON_OUTPUT_DIRECTORY})
        set_property(TEST ${test_name}
            APPEND PROPERTY ENVIRONMENT "PYTHONPATH=${WIN_PYTHON_OUTPUT_DIRECTORY}\;${WIN_PYTHONPATH}"
        )
    else()
        set_property(TEST ${test_name}
            APPEND PROPERTY ENVIRONMENT "PYTHONPATH=${CMAKE_PYTHON_OUTPUT_DIRECTORY}:$ENV{PYTHONPATH}"
        )
    endif()
endfunction()


# change the default CMAKE_BUILD_TYPE
# the default in CMake is Debug for historic reasons
#
macro(set_default_build_type default_build_type)
    if(CMAKE_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR)
        set(CMAKE_CONFIGURATION_TYPES "Release;Debug;MinSizeRel;RelWithDebInfo")
        if(NOT CMAKE_BUILD_TYPE)
            set(CMAKE_BUILD_TYPE ${default_build_type}
                CACHE STRING
                "Choose the build type, e.g. Release, Debug, or RelWithDebInfo." FORCE)
            set_property(CACHE CMAKE_BUILD_TYPE
                PROPERTY STRINGS ${CMAKE_CONFIGURATION_TYPES})
        endif()
        if(NOT CMAKE_BUILD_TYPE IN_LIST CMAKE_CONFIGURATION_TYPES)
            message(WARNING "CMAKE_BUILD_TYPE '${CMAKE_BUILD_TYPE}' is not one of "
                    "${CMAKE_CONFIGURATION_TYPES}. Is this a typo?")
        endif()
    endif()
endmacro()


# Set CXX
# Note: this is a bit legacy and one should use CMake TOOLCHAINS instead.
#
macro(set_cxx_warnings)
    # On Windows, Clang -Wall aliases -Weverything; default is /W3
    if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" AND NOT WIN32)
        # list(APPEND CMAKE_CXX_FLAGS "-fsanitize=address") # address, memory, undefined
        # set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=address")
        # set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -fsanitize=address")
        # set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -fsanitize=address")

        # note: might still need a
        #   export LD_PRELOAD=libclang_rt.asan.so
        # or on Debian 9 with Clang 6.0
        #   export LD_PRELOAD=/usr/lib/llvm-6.0/lib/clang/6.0.0/lib/linux/libclang_rt.asan-x86_64.so:
        #                     /usr/lib/llvm-6.0/lib/clang/6.0.0/lib/linux/libclang_rt.ubsan_minimal-x86_64.so
        # at runtime when used with symbol-hidden code (e.g. pybind11 module)

        #set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Weverything")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic -Wshadow -Woverloaded-virtual -Wextra-semi -Wunreachable-code")
    elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic -Wshadow -Woverloaded-virtual -Wunreachable-code")
    elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
        # Warning C4503: "decorated name length exceeded, name was truncated"
        # Symbols longer than 4096 chars are truncated (and hashed instead)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -wd4503")
        # Yes, you should build against the same C++ runtime and with same
        # configuration (Debug/Release). MSVC does inconvenient choices for their
        # developers, so be it. (Our Windows-users use conda-forge builds, which
        # are consistent.)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -wd4251")
    endif ()
endmacro()

# Enables interprocedural optimization for a list of targets
#
function(enable_IPO all_targets_list)
    include(CheckIPOSupported)
    check_ipo_supported(RESULT is_IPO_available)
    if(is_IPO_available)
        foreach(tgt IN ITEMS ${all_targets_list})
            set_target_properties(${tgt} PROPERTIES INTERPROCEDURAL_OPTIMIZATION TRUE)
        endforeach()
    else()
        message(FATAL_ERROR "Interprocedural optimization is not available, set ImpactX_IPO=OFF")
    endif()
endfunction()


# Take an <imported_target> and expose it as INTERFACE target with
# ImpactX::thirdparty::<propagated_name> naming and SYSTEM includes.
#
function(impactx_make_third_party_includes_system imported_target propagated_name)
    add_library(ImpactX::thirdparty::${propagated_name} INTERFACE IMPORTED)
    target_link_libraries(ImpactX::thirdparty::${propagated_name} INTERFACE ${imported_target})

    if(TARGET ${imported_target})
        get_target_property(imported_target_type ${imported_target} TYPE)
        if(NOT imported_target_type STREQUAL INTERFACE_LIBRARY)
            get_target_property(ALL_INCLUDES ${imported_target} INCLUDE_DIRECTORIES)
            if(ALL_INCLUDES)
                set_target_properties(ImpactX::thirdparty::${propagated_name} PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "")
                target_include_directories(ImpactX::thirdparty::${propagated_name} SYSTEM INTERFACE ${ALL_INCLUDES})
            endif()
        endif()
    endif()
endfunction()


# Set a feature-based binary name for the ImpactX executable and create a generic
# ImpactX symlink to it. Only sets options relevant for users (see summary).
#
function(impactx_set_binary_name)
    set(ImpactX_bin_names)
    if(ImpactX_APP)
        list(APPEND ImpactX_bin_names app)
    endif()
    if(ImpactX_LIB)
        list(APPEND ImpactX_bin_names shared)
    endif()
    foreach(tgt IN LISTS _ALL_TARGETS)
        set_target_properties(${tgt} PROPERTIES OUTPUT_NAME "impactx")

        if(ImpactX_MPI)
            set_property(TARGET ${tgt} APPEND_STRING PROPERTY OUTPUT_NAME ".MPI")
        else()
            set_property(TARGET ${tgt} APPEND_STRING PROPERTY OUTPUT_NAME ".NOMPI")
        endif()

        set_property(TARGET ${tgt} APPEND_STRING PROPERTY OUTPUT_NAME ".${ImpactX_COMPUTE}")

        if(ImpactX_PRECISION STREQUAL "DOUBLE")
            set_property(TARGET ${tgt} APPEND_STRING PROPERTY OUTPUT_NAME ".DP")
        else()
            set_property(TARGET ${tgt} APPEND_STRING PROPERTY OUTPUT_NAME ".SP")
        endif()

        #if(ImpactX_ASCENT)
        #    set_property(TARGET ${tgt} APPEND_STRING PROPERTY OUTPUT_NAME ".ASCENT")
        #endif()

        if(ImpactX_OPENPMD)
            set_property(TARGET ${tgt} APPEND_STRING PROPERTY OUTPUT_NAME ".OPMD")
        endif()

        #if(ImpactX_SENSEI)
        #    set_property(TARGET ${tgt} APPEND_STRING PROPERTY OUTPUT_NAME ".SENSEI")
        #endif()


        if(CMAKE_BUILD_TYPE MATCHES "Debug")
            set_property(TARGET ${tgt} APPEND_STRING PROPERTY OUTPUT_NAME ".DEBUG")
        endif()
    endforeach()

    if(ImpactX_APP)
        # alias to the latest build, because using the full name is often confusing
        add_custom_command(TARGET app POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E create_symlink
                $<TARGET_FILE_NAME:app>
                ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/impactx
        )
    endif()
    if(ImpactX_LIB)
        if(WIN32)
            set(mod_ext "dll")
        else()
            set(mod_ext "so")
        endif()
        add_custom_command(TARGET lib POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E create_symlink
                $<TARGET_FILE_NAME:lib>
                $<TARGET_FILE_DIR:lib>/libimpactx.${mod_ext}
        )
    endif()
endfunction()


# Set an MPI_TEST_EXE variable for test runs which runs num_ranks
# ranks. On some systems, you might need to use the a specific
# mpiexec wrapper, e.g. on Summit (ORNL) pass the hint
# -DMPIEXEC_EXECUTABLE=$(which jsrun) to run ctest.
#
function(configure_mpiexec num_ranks)
    # OpenMPI root guard: https://github.com/open-mpi/ompi/issues/4451
    if("$ENV{USER}" STREQUAL "root")
        # calling even --help as root will abort and warn on stderr
        execute_process(COMMAND ${MPIEXEC_EXECUTABLE} --help
            ERROR_VARIABLE MPIEXEC_HELP_TEXT
            OUTPUT_STRIP_TRAILING_WHITESPACE)
            if(${MPIEXEC_HELP_TEXT} MATCHES "^.*allow-run-as-root.*$")
                set(MPI_ALLOW_ROOT --allow-run-as-root)
            endif()
    endif()
    set(MPI_TEST_EXE
        ${MPIEXEC_EXECUTABLE}
        ${MPI_ALLOW_ROOT}
        ${MPIEXEC_NUMPROC_FLAG} ${num_ranks}
        PARENT_SCOPE
    )
endfunction()


# FUNCTION: get_source_version
#
# Retrieves source version info and sets internal cache variables
# ${NAME}_GIT_VERSION and ${NAME}_PKG_VERSION
#
function(get_source_version NAME SOURCE_DIR)
    find_package(Git QUIET)
    set(_tmp "")

    # Try to inquire software version from git
    if(EXISTS ${SOURCE_DIR}/.git AND ${GIT_FOUND})
        execute_process(COMMAND git describe --abbrev=12 --dirty --always --tags
            WORKING_DIRECTORY ${SOURCE_DIR}
            OUTPUT_VARIABLE _tmp)
        string( STRIP "${_tmp}" _tmp)
    endif()

    # Is there a CMake project version?
    # For deployed releases that build from tarballs, this is what we want to pick
    if(NOT _tmp AND ${NAME}_VERSION)
        set(_tmp "${${NAME}_VERSION}-nogit")
    endif()

    set(${NAME}_GIT_VERSION "${_tmp}" CACHE INTERNAL "")
    unset(_tmp)
endfunction ()


# Prints a summary of ImpactX options at the end of the CMake configuration
#
function(impactx_print_summary)
    message("")
    message("ImpactX build configuration:")
    message("  Version: ${ImpactX_VERSION} (${ImpactX_GIT_VERSION})")
    message("  C++ Compiler: ${CMAKE_CXX_COMPILER_ID} "
                            "${CMAKE_CXX_COMPILER_VERSION} "
                            "${CMAKE_CXX_COMPILER_WRAPPER}")
    message("    ${CMAKE_CXX_COMPILER}")
    message("")
    message("  Installation prefix: ${CMAKE_INSTALL_PREFIX}")
    message("        bin: ${CMAKE_INSTALL_BINDIR}")
    message("        lib: ${CMAKE_INSTALL_LIBDIR}")
    message("    include: ${CMAKE_INSTALL_INCLUDEDIR}")
    message("      cmake: ${ImpactX_INSTALL_CMAKEDIR}")
    if(ImpactX_PYTHON)
        message("     python: ${CMAKE_INSTALL_PYTHONDIR}")
    endif()
    message("")
    set(BLD_TYPE_UNKNOWN "")
    if(CMAKE_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR AND
       NOT CMAKE_BUILD_TYPE IN_LIST CMAKE_CONFIGURATION_TYPES)
        set(BLD_TYPE_UNKNOWN " (unknown type, check warning)")
    endif()
    message("  Build type: ${CMAKE_BUILD_TYPE}${BLD_TYPE_UNKNOWN}")
    set(LIB_TYPE "")
    if(ImpactX_LIB)
        if(BUILD_SHARED_LIBS)
            set(LIB_TYPE " (shared)")
        else()
            set(LIB_TYPE " (static)")
        endif()
    endif()
    #message("  Testing: ${BUILD_TESTING}")
    message("  Build options:")
    message("    APP: ${ImpactX_APP}")
    #message("    ASCENT: ${ImpactX_ASCENT}")
    message("    COMPUTE: ${ImpactX_COMPUTE}")
    message("    IPO/LTO: ${ImpactX_IPO}")
    message("    LIB: ${ImpactX_LIB}${LIB_TYPE}")
    message("    MPI: ${ImpactX_MPI}")
    if(MPI)
        message("    MPI (thread multiple): ${ImpactX_MPI_THREAD_MULTIPLE}")
    endif()
    message("    PRECISION: ${ImpactX_PRECISION}")
    message("    PYTHON: ${ImpactX_PYTHON}")
    message("    OPENPMD: ${ImpactX_OPENPMD}")
    #message("    SENSEI: ${ImpactX_SENSEI}")
    message("")
endfunction()
