# Preamble ####################################################################
#
cmake_minimum_required(VERSION 3.20.0)
project(ImpactX VERSION 22.08)

include(${ImpactX_SOURCE_DIR}/cmake/ImpactXFunctions.cmake)

# In-source tree builds are messy and can screw up the build system.
# Avoid building at least in the same dir as the root dir:
if(CMAKE_BINARY_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    message(FATAL_ERROR "Building in-source is not supported! "
            "Create a build directory and remove "
            "${CMAKE_SOURCE_DIR}/CMakeCache.txt ${CMAKE_SOURCE_DIR}/CMakeFiles/")
endif()


# CMake policies ##############################################################
#
# AMReX 21.06+ supports CUDA_ARCHITECTURES with CMake 3.20+
# CMake 3.18+: CMAKE_CUDA_ARCHITECTURES
# https://cmake.org/cmake/help/latest/policy/CMP0104.html
#if(CMAKE_VERSION VERSION_LESS 3.20)
    if(POLICY CMP0104)
        cmake_policy(SET CMP0104 OLD)
    endif()
#endif()


# C++ Standard in Superbuilds #################################################
#
# This is the easiest way to push up a C++17 requirement for AMReX and
# openPMD-api until they increase their requirement.
set_cxx17_superbuild()


# CCache Support ##############################################################
#
# this is an optional tool that stores compiled object files; allows fast
# re-builds even with "make clean" in between. Mainly used to store AMReX
# objects
set_ccache()


# Output Directories ##########################################################
#
# temporary build directories
impactx_set_default_build_dirs()

# default installation directories (w/o Python)
impactx_set_default_install_dirs()


# Options and Variants ########################################################
#
include(CMakeDependentOption)
option(ImpactX_APP           "Build the ImpactX executable application"     ON)
option(ImpactX_LIB           "Build ImpactX as a library"                   OFF)
option(ImpactX_MPI           "Multi-node support (message-passing)"         ON)
option(ImpactX_OPENPMD       "openPMD I/O (HDF5, ADIOS)"                    OFF)
option(ImpactX_PYTHON        "Python bindings"                              OFF)

set(ImpactX_PRECISION_VALUES SINGLE DOUBLE)
set(ImpactX_PRECISION DOUBLE CACHE STRING "Floating point precision (SINGLE/DOUBLE)")
set_property(CACHE ImpactX_PRECISION PROPERTY STRINGS ${ImpactX_PRECISION_VALUES})
if(NOT ImpactX_PRECISION IN_LIST ImpactX_PRECISION_VALUES)
    message(FATAL_ERROR "ImpactX_PRECISION (${ImpactX_PRECISION}) must be one of ${ImpactX_PRECISION_VALUES}")
endif()

set(ImpactX_COMPUTE_VALUES NOACC OMP CUDA SYCL HIP)
set(ImpactX_COMPUTE OMP CACHE STRING "On-node, accelerated computing backend (NOACC/OMP/CUDA/SYCL/HIP)")
set_property(CACHE ImpactX_COMPUTE PROPERTY STRINGS ${ImpactX_COMPUTE_VALUES})
if(NOT ImpactX_COMPUTE IN_LIST ImpactX_COMPUTE_VALUES)
    message(FATAL_ERROR "ImpactX_COMPUTE (${ImpactX_COMPUTE}) must be one of ${ImpactX_COMPUTE_VALUES}")
endif()

option(ImpactX_MPI_THREAD_MULTIPLE "MPI thread-multiple support, i.e. for async_io" ON)
mark_as_advanced(ImpactX_MPI_THREAD_MULTIPLE)

option(ImpactX_ablastr_internal                  "Download & build ABLASTR" ON)
option(ImpactX_amrex_internal                    "Download & build AMReX" ON)
option(ImpactX_pyamrex_internal                  "Download & build pyAMReX" ON)

set(pyImpactX_VERSION_INFO "" CACHE STRING
    "PEP-440 conformant version (set by distutils)")

# change the default build type to Release (or RelWithDebInfo) instead of Debug
set_default_build_type("Release")

# Option to enable interprocedural optimization
# (also know as "link-time optimization" or "whole program optimization")
option(ImpactX_IPO "Compile ImpactX with interprocedural optimization (will take more time)" OFF)

# this defined the variable BUILD_TESTING which is ON by default
include(CTest)


# Dependencies ################################################################
#

# ABLASTR
#   builds ABLASTR from source (default) or finds an existing install
#   ABLASTR in turn builds AMReX from source (default) or finds an existing
#     install
include(${ImpactX_SOURCE_DIR}/cmake/dependencies/ABLASTR.cmake)
impactx_make_third_party_includes_system(WarpX::ablastr ablastr)

# Python
if(ImpactX_PYTHON)
    find_package(Python COMPONENTS Interpreter Development.Module REQUIRED)

    # default installation directories: Python
    impactx_set_default_install_dirs_python()

    # pybind11
    #   builds pybind11 from git (default), form local source or
    #   finds an existing install
    include(${ImpactX_SOURCE_DIR}/cmake/dependencies/pybind11.cmake)

    # pyAMReX
    include(${ImpactX_SOURCE_DIR}/cmake/dependencies/pyAMReX.cmake)
endif()


# Targets #####################################################################
#
if(ImpactX_PYTHON)
    set(ImpactX_LIB ON CACHE STRING "library" FORCE)
endif()
if(NOT ImpactX_APP AND NOT ImpactX_LIB)
    message(FATAL_ERROR "Need to build at least ImpactX app or "
                        "library/Python bindings")
endif()

# collect all objects for compilation
add_library(ImpactX OBJECT)
set(_ALL_TARGETS ImpactX)

# executable application
#   note: we currently avoid a dependency on a core library
#         for simpler usage, but could make this an option
if(ImpactX_APP)
    add_executable(app)
    add_executable(ImpactX::app ALIAS app)
    target_link_libraries(app PRIVATE ImpactX)
    set(_BUILDINFO_SRC app)
    list(APPEND _ALL_TARGETS app)
endif()

# link into a library (shared or static)
if(ImpactX_LIB)
    add_library(lib)
    add_library(ImpactX::lib ALIAS lib)
    target_link_libraries(lib PUBLIC ImpactX)
    set(_BUILDINFO_SRC lib)
    list(APPEND _ALL_TARGETS lib)

    set_target_properties(ImpactX lib PROPERTIES
        POSITION_INDEPENDENT_CODE ON
        WINDOWS_EXPORT_ALL_SYMBOLS ON
    )
endif()

# build Python module (this is always a shared library)
if(ImpactX_PYTHON)
    add_library(pyImpactX MODULE src/python/pyImpactX.cpp)
    add_library(ImpactX::pyImpactX ALIAS pyImpactX)
    target_link_libraries(pyImpactX PUBLIC lib)
    set(_BUILDINFO_SRC pyImpactX)
    list(APPEND _ALL_TARGETS pyImpactX)

    # set Python module properties
    set_target_properties(pyImpactX PROPERTIES
        # hide symbols for combining multiple pybind11 modules downstream & for
        # reduced binary size
        CXX_VISIBILITY_PRESET "hidden"
        CUDA_VISIBILITY_PRESET "hidden"
        # name of the pybind-generated python module, which is wrapped in another
        # fluffy front-end modules, so we can extend it with pure Python
        ARCHIVE_OUTPUT_NAME impactx_pybind
        LIBRARY_OUTPUT_NAME impactx_pybind
        # build output directories - mainly set to run tests from CMake & IDEs
        ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_PYTHON_OUTPUT_DIRECTORY}/impactx
        LIBRARY_OUTPUT_DIRECTORY ${CMAKE_PYTHON_OUTPUT_DIRECTORY}/impactx
        RUNTIME_OUTPUT_DIRECTORY ${CMAKE_PYTHON_OUTPUT_DIRECTORY}/impactx
        PDB_OUTPUT_DIRECTORY ${CMAKE_PYTHON_OUTPUT_DIRECTORY}/impactx
        COMPILE_PDB_OUTPUT_DIRECTORY ${CMAKE_PYTHON_OUTPUT_DIRECTORY}/impactx
    )
    if(EMSCRIPTEN)
        set_target_properties(pyImpactX PROPERTIES
            PREFIX "")
    else()
        pybind11_extension(pyImpactX)
    endif()
    if(NOT MSVC AND NOT ${CMAKE_BUILD_TYPE} MATCHES Debug|RelWithDebInfo)
        pybind11_strip(pyImpactX)
    endif()
endif()

# own headers
target_include_directories(ImpactX PUBLIC
    $<BUILD_INTERFACE:${ImpactX_SOURCE_DIR}/src>
    $<BUILD_INTERFACE:${ImpactX_BINARY_DIR}/src>
)

# if we include <AMReX_buildInfo.H> we will need to call:
include(AMReXBuildInfo)
generate_buildinfo(${_BUILDINFO_SRC} "${ImpactX_SOURCE_DIR}")
target_link_libraries(ImpactX PRIVATE buildInfo::${_BUILDINFO_SRC})
unset(_BUILDINFO_SRC)

# add sources
add_subdirectory(src)

# C++ properties: at least a C++17 capable compiler is needed
foreach(ImpactX_tgt IN LISTS _ALL_TARGETS)
    target_compile_features(${ImpactX_tgt} PUBLIC cxx_std_17)
endforeach()
set_target_properties(${_ALL_TARGETS} PROPERTIES
    CXX_EXTENSIONS OFF
    CXX_STANDARD_REQUIRED ON
)

# Interprocedural optimization
if(ImpactX_IPO)
    enable_IPO("${_ALL_TARGETS}")
endif()

# link dependencies
#     note: only PUBLIC because ImpactX is an OBJECT collection
target_link_libraries(ImpactX PUBLIC ImpactX::thirdparty::ablastr)
if(ImpactX_PYTHON)
    target_link_libraries(pyImpactX PRIVATE pybind11::module pybind11::lto pybind11::windows_extras)
endif()

if(ImpactX_OPENPMD)
    target_compile_definitions(ImpactX PUBLIC ImpactX_USE_OPENPMD)
    target_link_libraries(ImpactX PUBLIC openPMD::openPMD)
endif()

if(ImpactX_QED)
    target_compile_definitions(ImpactX PUBLIC ImpactX_QED)
    if(ImpactX_QED_TABLE_GEN)
        target_compile_definitions(ImpactX PUBLIC ImpactX_QED_TABLE_GEN)
    endif()
    target_link_libraries(ImpactX PUBLIC PXRMP_QED::PXRMP_QED)
endif()

# AMReX helper function: propagate CUDA specific target & source properties
if(ImpactX_COMPUTE STREQUAL CUDA)
    foreach(ImpactX_tgt IN LISTS _ALL_TARGETS)
        setup_target_for_cuda_compilation(${ImpactX_tgt})
    endforeach()
    if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.17)
        foreach(ImpactX_tgt IN LISTS _ALL_TARGETS)
            target_compile_features(${ImpactX_tgt} PUBLIC cuda_std_17)
        endforeach()
        set_target_properties(${_ALL_TARGETS} PROPERTIES
            CUDA_EXTENSIONS OFF
            CUDA_STANDARD_REQUIRED ON
        )
    endif()
endif()

# fancy binary name for build variants
impactx_set_binary_name()


# Defines #####################################################################
#
if(ImpactX_OPENPMD)
    target_compile_definitions(ImpactX PUBLIC ImpactX_USE_OPENPMD)
endif()
if(ImpactX_PYTHON)
    # for module __version__
    target_compile_definitions(pyImpactX PRIVATE
        PYIMPACTX_VERSION_INFO=${pyImpactX_VERSION_INFO})
endif()


# Warnings ####################################################################
#
set_cxx_warnings()


# Generate Configuration and .pc Files ########################################
#
get_source_version(ImpactX ${ImpactX_SOURCE_DIR})
configure_file(
    ${ImpactX_SOURCE_DIR}/src/ImpactXVersion.H.in
    ${ImpactX_BINARY_DIR}/src/ImpactXVersion.H
    @ONLY
)

# these files are used if ImpactX is installed and picked up by a downstream
# project (not needed yet)

#include(CMakePackageConfigHelpers)
#write_basic_package_version_file("ImpactXConfigVersion.cmake"
#    VERSION ${ImpactX_VERSION}
#    COMPATIBILITY SameMajorVersion
#)


# Installs ####################################################################
#

# headers, libraries and executables
set(ImpactX_INSTALL_TARGET_NAMES)
if(ImpactX_APP)
    list(APPEND ImpactX_INSTALL_TARGET_NAMES app)
endif()
if(ImpactX_LIB)
    list(APPEND ImpactX_INSTALL_TARGET_NAMES lib)
endif()
if(ImpactX_PYTHON)
    list(APPEND ImpactX_INSTALL_TARGET_NAMES pyImpactX)
endif()

install(TARGETS ${ImpactX_INSTALL_TARGET_NAMES}
    EXPORT ImpactXTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# simplified library alias
# this is currently expected by Python bindings
if(ImpactX_LIB)
    if(WIN32)
        set(mod_ext "dll")
    else()
        set(mod_ext "so")
    endif()
    if(IS_ABSOLUTE ${CMAKE_INSTALL_LIBDIR})
        set(ABS_INSTALL_LIB_DIR ${CMAKE_INSTALL_LIBDIR})
    else()
        set(ABS_INSTALL_LIB_DIR ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR})
    endif()
    install(CODE "file(CREATE_LINK
        $<TARGET_FILE_NAME:lib>
        ${ABS_INSTALL_LIB_DIR}/libImpactX.${mod_ext}
        COPY_ON_ERROR SYMBOLIC)")
endif()

# CMake package file for find_package(ImpactX::ImpactX) in depending projects
#install(EXPORT ImpactXTargets
#    FILE ImpactXTargets.cmake
#    NAMESPACE ImpactX::
#    DESTINATION ${ImpactX_INSTALL_CMAKEDIR}
#)
#install(
#    FILES
#        ${ImpactX_BINARY_DIR}/ImpactXConfig.cmake
#        ${ImpactX_BINARY_DIR}/ImpactXConfigVersion.cmake
#    DESTINATION ${ImpactX_INSTALL_CMAKEDIR}
#)


# pip helpers for the impactx package #########################################
#
if(ImpactX_PYTHON)
    set(PYINSTALLOPTIONS "" CACHE STRING
        "Additional parameters to pass to `pip install`")

    # add a prefix to custom targets so we do not collide if used as a subproject
    if(CMAKE_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR)
        set(_ImpactX_CUSTOM_TARGET_PREFIX_DEFAULT "")
    else()
        set(_ImpactX_CUSTOM_TARGET_PREFIX_DEFAULT "impactx_")
    endif()
    set(ImpactX_CUSTOM_TARGET_PREFIX "${_ImpactX_CUSTOM_TARGET_PREFIX_DEFAULT}"
        CACHE STRING "Prefix for custom targets")

    # build the wheel by re-using the lib library we build
    add_custom_target(${ImpactX_CUSTOM_TARGET_PREFIX}pip_wheel
        ${CMAKE_COMMAND} -E rm -f -r impactx-whl
        COMMAND
            ${CMAKE_COMMAND} -E env PYIMPACTX_LIBDIR=$<TARGET_FILE_DIR:pyImpactX>
                ${Python_EXECUTABLE} -m pip wheel -v --no-build-isolation --no-deps --wheel-dir=impactx-whl ${ImpactX_SOURCE_DIR}
        WORKING_DIRECTORY
            ${ImpactX_BINARY_DIR}
        DEPENDS
            pyImpactX
    )

    # this will also upgrade/downgrade dependencies, e.g., when the version of numpy changes
    if(ImpactX_MPI)
        set(pyImpactX_REQUIREMENT_FILE "requirements_mpi.txt")
    else()
        set(pyImpactX_REQUIREMENT_FILE "requirements.txt")
    endif()
    add_custom_target(${ImpactX_CUSTOM_TARGET_PREFIX}pip_install_requirements
        ${Python_EXECUTABLE} -m pip install ${PYINSTALLOPTIONS} -r "${ImpactX_SOURCE_DIR}/${pyImpactX_REQUIREMENT_FILE}"
        WORKING_DIRECTORY
            ${ImpactX_BINARY_DIR}
    )

    # if we do a superbuild, make sure we install pyAMReX via its custom install
    # target
    set(_EXTRA_INSTALL_DEPENDS)
    if(ImpactX_pyamrex_internal OR ImpactX_pyamrex_src)
        set(_EXTRA_INSTALL_DEPENDS pyamrex_pip_install)
    endif()

    # We force-install because in development, it is likely that the version of
    # the package does not change, but the code did change. We need --no-deps,
    # because otherwise pip would also force reinstall all dependencies.
    add_custom_target(${ImpactX_CUSTOM_TARGET_PREFIX}pip_install
        ${CMAKE_COMMAND} -E env IMPACTX_MPI=${ImpactX_MPI}
            ${Python_EXECUTABLE} -m pip install --force-reinstall --no-index --no-deps ${PYINSTALLOPTIONS} --find-links=impactx-whl impactx
        WORKING_DIRECTORY
            ${ImpactX_BINARY_DIR}
        DEPENDS
            pyImpactX
            ${ImpactX_CUSTOM_TARGET_PREFIX}pip_wheel ${ImpactX_CUSTOM_TARGET_PREFIX}pip_install_requirements
            ${_EXTRA_INSTALL_DEPENDS}
    )
endif()


# Tests #######################################################################
#
if(BUILD_TESTING)
    enable_testing()

    # examples
    if(ImpactX_APP)
        add_subdirectory(examples)
    endif()

    # unit tests
    if(ImpactX_PYTHON)
        # copy Python wrapper library to build directory
        add_custom_command(TARGET pyImpactX POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
                ${ImpactX_SOURCE_DIR}/src/python/impactx
                $<TARGET_FILE_DIR:pyImpactX>
        )
    endif()
    add_subdirectory(tests)
endif()


# Status Summary for Build Options ############################################
#
impactx_print_summary()
