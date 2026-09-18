cmake_minimum_required(VERSION 3.18)

project(session-deps-test LANGUAGES C CXX)

# A project that exists only to build every dependency we ship a recipe for, so that CI notices a
# recipe that has rotted -- an upstream that moved its tarball, a configure option that went away, a
# new platform it never built on -- rather than the next project to need it finding out.
#
# The dependency list is globbed rather than written down: a recipe that is added without being
# listed here would otherwise be exactly the kind of thing that goes untested.

include(${CMAKE_CURRENT_LIST_DIR}/../Deps.cmake)

# This only makes sense as a static build; with system libraries it would test nothing of ours.
set(BUILD_STATIC_DEPS ON CACHE BOOL "" FORCE)

# Deps that genuinely cannot build on the platform being tested, if any turn up.  This comes from
# the CI job rather than living here so that a skip is visible in the one job that needs it instead
# of quietly switching off coverage everywhere.
set(SKIP_DEPS "" CACHE STRING "Dependency recipes to skip, e.g. -DSKIP_DEPS='libunbound;icu-io'")

file(GLOB dep_recipes RELATIVE ${CMAKE_CURRENT_LIST_DIR}/../deps ${CMAKE_CURRENT_LIST_DIR}/../deps/*.cmake)

set(dep_targets)
set(dep_defines)
foreach(recipe IN LISTS dep_recipes)
    string(REGEX REPLACE "\\.cmake$" "" dep "${recipe}")

    # Not a dependency: the shared machinery every recipe uses.
    if(dep STREQUAL "StaticBuild")
        continue()
    endif()
    if(dep IN_LIST SKIP_DEPS)
        message(STATUS "session-deps test: skipping ${dep} (in SKIP_DEPS)")
        continue()
    endif()

    # Version 0: BUILD_STATIC_DEPS means no system package is consulted, so the minimum a caller
    # would ask for is irrelevant here -- we want to build the recipe whatever it produces.
    session_dep(${dep} 0)
    list(APPEND dep_targets sessiondep::${dep})

    string(TOUPPER "${dep}" dep_define)
    string(MAKE_C_IDENTIFIER "${dep_define}" dep_define)
    list(APPEND dep_defines HAVE_DEP_${dep_define})
endforeach()

list(LENGTH dep_targets dep_count)
message(STATUS "session-deps test: building ${dep_count} dependencies")

# The sources call into each library that was built, which is what makes the linker resolve
# anything at all: a static archive nothing references contributes no members, so linking by itself
# would be satisfied by a library whose symbols are missing entirely.  HAVE_DEP_* tells them which
# libraries are present, so SKIP_DEPS drops the calls along with the library.
add_executable(deps-test main.cpp)
target_link_libraries(deps-test PRIVATE ${dep_targets})
target_compile_definitions(deps-test PRIVATE ${dep_defines})
# The rest of our code is C++20, so that is what these headers need to be usable from.
target_compile_features(deps-test PRIVATE cxx_std_20)

if(MINGW)
    # mingw links its own runtime as DLLs by default, which a cross-built binary then cannot find:
    # they live in the cross toolchain's directories, not next to the executable.  Statically linking
    # them makes this runnable (under wine, or on Windows) without arranging a DLL search path.
    target_link_options(deps-test PRIVATE -static)
endif()
