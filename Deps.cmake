cmake_minimum_required(VERSION 3.18...3.31)

include_guard(GLOBAL)

# Versioning: if you only add things (and aren't breaking the top-level function), increment the
# second number.  Increment the first number if this is a breaking change: encountering different
# major versions within the submodules of the same project will be a fatal error.
#
# If different versions of this script gets loaded from different places we want to defer to the
# functions set in the most recent version as it may have fixes or new deps in it that an older
# version is missing, and so we let later versions overwrite the functions of earlier versions.
set(session_deps_version 1.1)

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

option(BUILD_STATIC_DEPS "Forcing building all dependencies statically" OFF)

function(session_dep libname minver)
    option(BUILD_STATIC_${libname} "Force building dependency ${libname} statically" OFF)

    cmake_parse_arguments(PARSE_ARGV 1 sdep "" "" "WITH")

    if (sdep_WITH)
        message(VERBOSE "Checking for dependency (${libname};${sdep_WITH})>=${minver}")
    else()
        message(VERBOSE "Checking for dependency ${libname}>=${minver}")
    endif()

    # We don't actually load this unless we end up needing the static build, but check it here
    # regardless so that we can't accidentally specify things that don't have build scripts but
    # happen to work on the local build system.
    if(NOT EXISTS "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/deps/${libname}.cmake")
        message(FATAL_ERROR "Build script ${libname}.cmake for static build not found in ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/deps!")
    endif()

    set(build_static FALSE)
    if(BUILD_STATIC_DEPS OR BUILD_STATIC_${libname})
        set(build_static TRUE)
    endif()

    set(dep_ver)

    set(libnames ${libname} ${sdep_WITH})
    set(targets)
    foreach(n IN LISTS libnames)
        list(APPEND targets _session_dep_${n})
    endforeach()
    set(link_to)  # Will be filled in to correspond to the above lists

    set(have_all_targets TRUE)
    foreach(t IN LISTS targets)
        if(NOT TARGET ${t})
            set(have_all_targets FALSE)
            break()
        endif()
    endforeach()

    if(have_all_targets)
        get_target_property(existing_version _session_dep_${libname} sessiondep_ver)
        if(existing_version EQUAL -1)
            # Already set up a static build for this dep so nothing to do, the existing target
            # should be good.
            return()
        elseif(build_static AND NOT existing_version EQUAL -1)
            message(VERBOSE "Static ${libname} requested, but target is currently non-static; changing to static")
            set(build_static TRUE)
        elseif(existing_version VERSION_LESS minver)
            message(VERBOSE "Previously found ${libname} dependency (${existing_version}) is too old (>=${minver} required), switching to static")
            set(build_static TRUE)
        else()
            message(VERBOSE "Using previously found ${libname} system lib (${existing_version})")
            return()
        endif()
    endif()

    if(NOT build_static)
        find_package(PkgConfig REQUIRED)
        foreach(n IN LISTS libnames)
            string(MAKE_C_IDENTIFIER "sessiondep_${n}_${minver}" DEP)
            pkg_check_modules(${DEP} IMPORTED_TARGET GLOBAL ${n}>=${minver})
            if(${DEP}_FOUND)
                message(STATUS "Found ${n} ${${DEP}_VERSION} (>= required ${minver})")
                list(APPEND link_to PkgConfig::${DEP})
                if("${dep_ver}" STREQUAL "")
                    set(dep_ver ${${DEP}_VERSION})
                endif()
            else()
                set(build_static TRUE)
                message(STATUS "Did not find ${n}>=${minver}; falling back to static build")
                break()
            endif()
        endforeach()
    endif()

    if(build_static)
        set(link_to)  # In case it was partially filled while checking extra deps, above
        set(dep_ver -1) # -1 is used to indicate a local static build

        include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/deps/StaticBuild.cmake")
        include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/deps/${libname}.cmake")

        foreach(t IN LISTS libname sdep_WITH)
            if(NOT TARGET sessiondep_ext_${t})
                message(FATAL_ERROR "Internal error: deps/${libname}.cmake static build script did not produce the requested ${t} depency target")
            endif()
            list(APPEND link_to sessiondep_ext_${t})
        endforeach()
    endif()

    foreach(lib tgt lnk IN ZIP_LISTS libnames targets link_to)
        if(TARGET ${tgt})
            # If this target already
            # exists then it most likely means one call was satisfied by system deps, but some other
            # call elsewhere in the project wasn't satisfied, and so we need to replace the original
            # with the static target.
            #
            # CMake targets cannot be deleted, but they *can* be altered, so that's what we do: we
            # wipe out its current linked targets, and replace it with the new one.
            set_target_properties(${tgt} PROPERTIES INTERFACE_LINK_LIBRARIES "")
        else()
            add_library(${tgt} INTERFACE)
            add_library(sessiondep::${lib} ALIAS ${tgt})
        endif()
        target_link_libraries(${tgt} INTERFACE ${lnk})
    endforeach()

    set_target_properties(_session_dep_${libname} PROPERTIES sessiondep_ver ${dep_ver})

endfunction()


option(DEPS_FORCE_SUBMODULE "For building all submodule dependencies instead of looking for system libraries" OFF)
function(sessiondep_or_submodule libname minver subdir target)
    option(DEPS_FORCE_${libname}_SUBMODULE "force using ${libname} submodule" OFF)

    if(TARGET ${target})
        message(FATAL_ERROR "sessiondep_or_submodule cannot create dependency target ${target}: target already exists")
    endif()

    set(tgt _session_dep_${libname})
    string(MAKE_C_IDENTIFIER "sessiondep_${libname}_${minver}" DEP)
    if(NOT BUILD_STATIC_DEPS AND NOT DEPS_FORCE_SUBMODULE AND NOT DEPS_FORCE_${libname}_SUBMODULE)
        find_package(PkgConfig REQUIRED)
        pkg_check_modules(${DEP} ${libname}>=${minver} IMPORTED_TARGET GLOBAL)
    endif()
    if(${DEP}_FOUND)
        add_library(${tgt} INTERFACE)
        if(NOT TARGET PkgConfig::${DEP} AND CMAKE_VERSION VERSION_LESS "3.21")
            # Work around cmake bug 22180 (PkgConfig::THING not set if no flags needed)
        else()
            target_link_libraries(${tgt} INTERFACE PkgConfig::${DEP})
        endif()
        add_library(${target} ALIAS ${tgt})
        message(STATUS "Found system ${libname} ${${DEP}_VERSION}")
    else()
        message(STATUS "using ${libname} submodule")
        add_subdirectory(${subdir} EXCLUDE_FROM_ALL)

        if(NOT TARGET ${target})
            message(FATAL_ERROR "Subdirectory ${subdir} did not produce the required ${target} target!")
        endif()
    endif()
endfunction()


option(SUBMODULE_CHECK "Enables checking that vendored submodules are up to date" ON)

function(check_submodule relative_path)
    find_package(Git)
    if(NOT GIT_FOUND)
        get_property(_sdep_submodule_warned_nogit GLOBAL PROPERTY _sdep_submodule_warned_nogit)
        if(NOT _sdep_submodule_warned_nogit)
            message(WARNING "Git was not found; submodule checks disabled")
            set_property(GLOBAL PROPERTY _sdep_submodule_warned_nogit TRUE)
        endif()
        return()
    endif()

    cmake_parse_arguments(PARSE_ARGV 1 arg "" "WORKING_DIRECTORY" "")

    if(NOT arg_WORKING_DIRECTORY)
        set(arg_WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
    endif()

    file(RELATIVE_PATH display_path "${PROJECT_SOURCE_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}/${relative_path}")
    execute_process(COMMAND git rev-parse "HEAD" WORKING_DIRECTORY "${arg_WORKING_DIRECTORY}/${relative_path}" OUTPUT_VARIABLE localHead)
    execute_process(COMMAND git rev-parse "HEAD:./${relative_path}" WORKING_DIRECTORY "${arg_WORKING_DIRECTORY}" OUTPUT_VARIABLE checkedHead)
    string(COMPARE EQUAL "${localHead}" "${checkedHead}" upToDate)
    if (upToDate)
        message(STATUS "Submodule '${display_path}' is up-to-date")
    elseif(SUBMODULE_CHECK)
        message(FATAL_ERROR "Submodule '${display_path}' is not up-to-date (${localHead} ${checkedHead}). Please update with\ngit submodule update --init --recursive\nor run cmake with -DSUBMODULE_CHECK=OFF")
    else()
        message(WARNING "Submodule '${display_path}' is not up-to-date")
    endif()

    # Extra arguments check nested submodules
    foreach(submod IN LISTS arg_UNPARSED_ARGUMENTS)
        check_submodule("${submod}" WORKING_DIRECTORY "${relative_path}")
    endforeach()
endfunction ()


set(SESSIONDEPS_CMAKE_MODS ${CMAKE_BINARY_DIR}/mod-overrides CACHE PATH "Path where sessiondep_find_package_override writes cmake override files")

# Creates a FindXXX.cmake in the module search path, typically loaded with static build items, so
# that later calls to find_package(XXX) will load from there instead of trying to load a system one.
#
# For an example see the usage in deps/gnutls.cmake.
function(sessiondep_override_find_package NAME VERSION INCLUDE_DIR LIBRARY LIBRARIES)
    get_property(_sdep_applied_modpath_override GLOBAL PROPERTY _sdep_applied_modpath_override)
    if(NOT _sdep_applied_modpath_override)
        file(MAKE_DIRECTORY ${SESSIONDEPS_CMAKE_MODS})
        list(INSERT CMAKE_MODULE_PATH 0 ${SESSIONDEPS_CMAKE_MODS})
        set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}" CACHE INTERNAL "Global sessiondep override for Find modules" FORCE)
        set_property(GLOBAL PROPERTY _sdep_applied_modpath_override TRUE)
    endif()

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/deps/FindXXX.cmake.template
        ${SESSIONDEPS_CMAKE_MODS}/Find${NAME}.cmake
        @ONLY)
endfunction()
