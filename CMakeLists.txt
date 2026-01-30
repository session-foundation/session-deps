cmake_minimum_required(VERSION 3.18...3.31)

include_guard(GLOBAL)

# Versioning: if you only add things (and aren't breaking the top-level function), increment the
# second number.  Increment the first number if this is a breaking change: encountering different
# major versions within the submodules of the same project will be a fatal error.
set(session_deps_version 1.0)

# If different versions of this script gets loaded from different places we want to defer to the
# functions set in the most recent version as it may have fixes or new deps in it that an older
# version is missing.

get_property(_sdep_loaded_version GLOBAL PROPERTY _sdep_loaded_version)

if(_sdep_loaded_version)

    STRING(REGEX MATCH "^[0-9]+" our_major ${session_deps_version})
    STRING(REGEX MATCH "^[0-9]+" their_major ${_sdep_loaded_version})

    get_property(_sdep_loaded_file GLOBAL PROPERTY _sdep_loaded_file)

    if (NOT our_major EQUAL their_major)
        message(FATAL_ERROR "session-deps major version mismatch: ${CMAKE_CURRENT_LIST_FILE} v${session_deps_version} is incompatible with ${_sdep_loaded_file} v${_sdep_loaded_version}")
    endif()

    if(_sdep_loaded_version VERSION_GREATER_EQUAL session_deps_version)
        return()
    endif()

endif()

set_property(GLOBAL PROPERTY _sdep_loaded_version ${session_deps_version})
set_property(GLOBAL PROPERTY _sdep_loaded_file ${CMAKE_CURRENT_LIST_FILE})

set_property(GLOBAL PROPERTY _sdep_static_build_setup "")

include(StaticBuild.cmake)

function(session_dep libname minver)
    cmake_parse_arguments(PARSE_ARGV 1 sdep "" "TARGET" "WITH")

    if (NOT sdep_TARGET)
        set(sdep_TARGET ${libname})
    endif()

    set(build_static FALSE)
    if(SESSIONDEPS_STATIC OR SESSIONDEPS_${libname}_STATIC)
        set(build_static TRUE)
    endif()

    set(link_to)
    set(dep_ver)

    if(TARGET _session_dep_${libname})
        get_target_property(existing_version _session_dep_${libname} sessiondep_ver)
        if(existing_version EQUAL -1)
            # Already set up a static build for this dep so nothing to do, the existing target
            # should be good.
            return()
        elseif(build_static AND NOT existing_version EQUAL -1)
            message(INFO "Static ${libname} requested, but target is currently non-static; changing to static")
        elseif(existing_version VERSION_LESS minver)
            message(INFO "Previously found ${libname} dependency is too old (${existing_version} < ${minver}), switching to static")
        else()
            message(INFO "Using previously found sessiondep::${libname} system lib (${existing_version})")
            return()
        endif()

        set(build_static TRUE)
    elseif(NOT build_static)
        find_package(PkgConfig REQUIRED)
        string(MAKE_C_IDENTIFIER "sessiondep_${libname}_${minver}" DEP)
        pkg_check_modules(${DEP} IMPORTED_TARGET GLOBAL ${libname}>=${minver} ${sdep_WITH})
        if(${DEP}_FOUND)
            set(link_to PkgConfig::${DEP})
            set(dep_ver ${${DEP}_VERSION})
        else()
            set(build_static TRUE)
        endif()
    endif()

    if(build_static)
        if(NOT EXISTS "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/deps/${libname}.cmake")
            message(FATAL_ERROR "Build script ${libname}.cmake for static build not found in ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/deps!")
        endif()
        set(dep_ver -1) # -1 is used to indicate a local static build
        include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/deps/${libname}.cmake")
        set(link_to sessiondep_ext_${libname})
    endif()

    if(TARGET _session_dep_${libname})
        # We had a previous interface target and while we can't delete it we wipe out its current
        # linked libraries and put a new one on:
        set_target_properties(_session_dep_${libname} PROPERTIES INTERFACE_LINK_LIBRARIES "")
    else()
        add_library(_session_dep_${libname} INTERFACE)
        add_library(sessiondep::${sdep_TARGET} ALIAS _session_dep_${libname})
    endif()

    set_target_properties(_session_dep_${libname} PROPERTIES sessiondep_ver ${dep_ver})

endfunction()
