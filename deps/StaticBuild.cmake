# cmake helpers used to do a full static build, downloading and building all dependencies.

include_guard(GLOBAL)

set(LOCAL_MIRROR "" CACHE STRING "local mirror path/URL for lib downloads")

include(ExternalProject)

set(DEPS_DESTDIR ${CMAKE_BINARY_DIR}/static-deps)
set(DEPS_SOURCEDIR ${CMAKE_BINARY_DIR}/static-deps-sources)
set(DEPS_CMAKE_MODS ${DEPS_DESTDIR}/cmake-static-modules)
file(MAKE_DIRECTORY ${DEPS_CMAKE_MODS})
list(INSERT CMAKE_MODULE_PATH 0 ${DEPS_CMAKE_MODS})

include_directories(BEFORE SYSTEM ${DEPS_DESTDIR}/include)

file(MAKE_DIRECTORY ${DEPS_DESTDIR}/include)

set(deps_cc "${CMAKE_C_COMPILER}")
set(deps_cxx "${CMAKE_CXX_COMPILER}")
if(CMAKE_C_COMPILER_LAUNCHER)
  set(deps_cc "${CMAKE_C_COMPILER_LAUNCHER} ${deps_cc}")
endif()
if(CMAKE_CXX_COMPILER_LAUNCHER)
  set(deps_cxx "${CMAKE_CXX_COMPILER_LAUNCHER} ${deps_cxx}")
endif()


function(sessiondep_expand_urls output source_file)
  set(expanded)
  foreach(mirror ${ARGN})
    list(APPEND expanded "${mirror}/${source_file}")
  endforeach()
  set(${output} "${expanded}" PARENT_SCOPE)
endfunction()


# Add a static imported target for a single library.  If the static build produces just one library
# then this can be the final `libsession_ext_PKG` target.  For a multi-library output you need
# one of these calls per produced output, and then use `sessiondep_bundle()` to produce the
# final required target from multiple targets.
#
# After a sessiondep_build_external(mypkg ...) that produces a single static library lib/libmypkg.a
# you would typically call this as follows to produce the proper target needed for satisfy a static
# dep:
#
#     sessiondep_static_target(sessiondep_ext_mypkg mypkg libmypkg.a)
#
# For a multi-lib static build producing lib/libmypkg.a and lib/libmypkg-foo.a, there are two
# options.  The first is just to export a single target that links to everything; to do that use
# something like:
#
#     sessiondep_static_target(mypkg_base mypkg libmypkg.a)
#     sessiondep_static_target(mypkg_foo mypkg libmypkg-foo.a)
#     sessiondep_bundle(mypkg mypkg_base mypkg_foo)
#
# which will expose a single sessiondep::mypkg target that links to both libraries.
#
# However if these are independent and can be linked separately (typically with independent
# pkgconfig files), you may not want such a bundle so that the program can choose with components it
# links to.  See deps/nettle.cmake and deps/libngtcp2.cmake for examples of this.
#
# You can append other cmake target dependencies (e.g. `sessiondep::xyz`) after the static library
# filename to set up the proper cmake dependency chain.
function(sessiondep_static_target target ext_target libname)
  add_library(${target} STATIC IMPORTED GLOBAL)
  add_dependencies(${target} sessiondep_${ext_target}_external)
  set_target_properties(${target} PROPERTIES
    IMPORTED_LOCATION ${DEPS_DESTDIR}/lib/${libname}
  )
  if (ARGN)
    target_link_libraries(${target} INTERFACE ${ARGN})
  endif()
endfunction()


# For static builds that link to multiple targets, this helper function is provided to combine them;
# see example above.
#
# The first argument, `name`, should be the same as the script filename (e.g. "libngtcp2" for
# deps/libngtcp2.cmake).  `sessiondep_ext_` will be prepended to the target name automatically.  Any
# remaining arguments are cmake targets to link to the created interface.
function(sessiondep_bundle name)
    add_library(sessiondep_ext_${name} INTERFACE)
    target_link_libraries(sessiondep_ext_${name} INTERFACE ${ARGN})
endfunction()


# Creates a FindXXX.cmake in the module search path, typically loaded with static build items, so
# that later calls to find_package(XXX) will load from there instead of trying to load a system one.
#
# For an example see the usage in deps/gnutls.cmake.
function(sessiondep_find_package_override NAME VERSION INCLUDE_DIR LIBRARY LIBRARIES)
    configure_file(${CMAKE_CURRENT_LIST_DIR}/FindXXX.cmake.template
        ${DEPS_CMAKE_MODS}/Find${NAME}.cmake
        @ONLY)
endfunction()



set(cross_host "")
set(cross_rc "")
if(CMAKE_CROSSCOMPILING)
  set(cross_host "--host=${ARCH_TRIPLET}")
  if (ARCH_TRIPLET MATCHES mingw AND CMAKE_RC_COMPILER)
    set(cross_rc "WINDRES=${CMAKE_RC_COMPILER}")
  endif()
endif()
if(ANDROID)
  set(android_toolchain_suffix linux-android)
  set(android_compiler_suffix linux-android23)
  if(CMAKE_ANDROID_ARCH_ABI MATCHES x86_64)
    set(android_machine x86_64)
    set(cross_host "--host=x86_64-linux-android")
    set(android_compiler_prefix x86_64)
    set(android_compiler_suffix linux-android23)
    set(android_toolchain_prefix x86_64)
    set(android_toolchain_suffix linux-android)
  elseif(CMAKE_ANDROID_ARCH_ABI MATCHES x86)
    set(android_machine x86)
    set(cross_host "--host=i686-linux-android")
    set(android_compiler_prefix i686)
    set(android_compiler_suffix linux-android23)
    set(android_toolchain_prefix i686)
    set(android_toolchain_suffix linux-android)
  elseif(CMAKE_ANDROID_ARCH_ABI MATCHES armeabi-v7a)
    set(android_machine arm)
    set(cross_host "--host=armv7a-linux-androideabi")
    set(android_compiler_prefix armv7a)
    set(android_compiler_suffix linux-androideabi23)
    set(android_toolchain_prefix arm)
    set(android_toolchain_suffix linux-androideabi)
  elseif(CMAKE_ANDROID_ARCH_ABI MATCHES arm64-v8a)
    set(android_machine arm64)
    set(cross_host "--host=aarch64-linux-android")
    set(android_compiler_prefix aarch64)
    set(android_compiler_suffix linux-android23)
    set(android_toolchain_prefix aarch64)
    set(android_toolchain_suffix linux-android)
  else()
    message(FATAL_ERROR "unknown android arch: ${CMAKE_ANDROID_ARCH_ABI}")
  endif()
  set(deps_cc "${CMAKE_ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/${android_compiler_prefix}-${android_compiler_suffix}-clang")
  set(deps_cxx "${CMAKE_ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/${android_compiler_prefix}-${android_compiler_suffix}-clang++")
  set(deps_ld "${CMAKE_ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/${android_compiler_prefix}-${android_toolchain_suffix}-ld")
  set(deps_ranlib "${CMAKE_ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/${android_toolchain_prefix}-${android_toolchain_suffix}-ranlib")
  set(deps_ar "${CMAKE_ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/${android_toolchain_prefix}-${android_toolchain_suffix}-ar")
endif()

set(deps_CFLAGS "-O2")
set(deps_CXXFLAGS "-O2")

set(default_lto ON)
if(WIN32)
    set(default_lto OFF)
endif()
option(SESSIONDEPS_LTO "Use LTO for static dependency builds, where supported" ${default_lto})
if(SESSIONDEPS_LTO)
  set(deps_CFLAGS "${deps_CFLAGS} -flto")
endif()

if(APPLE)
  set(deps_CFLAGS "${deps_CFLAGS} -mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}")
  set(deps_CXXFLAGS "${deps_CXXFLAGS} -mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}")
endif()



if("${CMAKE_GENERATOR}" STREQUAL "Unix Makefiles")
  set(_make $(MAKE))
else()
  set(_make make)
endif()


# Builds a target; takes the target name (e.g. "readline") and builds it in an external project with
# target name suffixed with `_external`.  Its upper-case value is used to get the download details
# (from the variables set above).  The following options are supported and passed through to
# ExternalProject_Add if specified.  If omitted, these defaults are used:
set(build_def_DEPENDS "")
set(build_def_PATCH_COMMAND "")
set(build_def_CONFIGURE_COMMAND ./configure ${cross_host} --disable-shared --prefix=${DEPS_DESTDIR} --with-pic
    "CC=${deps_cc}" "CXX=${deps_cxx}" "CFLAGS=${deps_CFLAGS}" "CXXFLAGS=${deps_CXXFLAGS}" ${cross_rc})
set(build_def_BUILD_COMMAND ${_make})
set(build_def_INSTALL_COMMAND ${_make} install)
set(build_def_BUILD_BYPRODUCTS ${DEPS_DESTDIR}/lib/lib___TARGET___.a ${DEPS_DESTDIR}/include/___TARGET___.h)

function(sessiondep_build_external target)
  set(options DEPENDS PATCH_COMMAND CONFIGURE_COMMAND BUILD_COMMAND INSTALL_COMMAND BUILD_BYPRODUCTS)
  cmake_parse_arguments(PARSE_ARGV 1 arg "" "" "${options}")
  foreach(o ${options})
    if(NOT DEFINED arg_${o})
      set(arg_${o} ${build_def_${o}})
    endif()
  endforeach()
  string(REPLACE ___TARGET___ ${target} arg_BUILD_BYPRODUCTS "${arg_BUILD_BYPRODUCTS}")


  if(arg_CONFIGURE_COMMAND MATCHES "^DEFAULT_CMAKE")
      string(REGEX REPLACE "^DEFAULT_CMAKE(;?)" "CMAKE_ARGS;-DCMAKE_INSTALL_PREFIX=${DEPS_DESTDIR}\\1" configure "${arg_CONFIGURE_COMMAND}")
      set(build "")
      set(install "")
  else()
    set(configure CONFIGURE_COMMAND ${arg_CONFIGURE_COMMAND})
    set(build BUILD_COMMAND ${arg_BUILD_COMMAND})
    set(install INSTALL_COMMAND ${arg_INSTALL_COMMAND})
  endif()

  set(no_idiotic_extract)
  if(NOT CMAKE_VERSION VERSION_LESS 3.24)
    # CMake 3.24 ExternalProject changed the default to "don't extract timestamps" by default that
    # wipes out all the timestamps of extracted packages, breaking pretty much all autotools
    # packages.  That's a exceptionally brilliant default for an "external project" builder, thanks
    # so much CMake!  (see cmake issue #24003)
    set(no_idiotic_extract DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
  endif()

  # For any sessiondep::TGT things we have listed in DEPENDS we have to convert to the raw name (if
  # it exists), because in the sessiondep::TGT form cmake helpfully just assumes things are built
  # instantly, because god forbid cmake adds a feature without massive gotchas.
  set(fixed_depends)
  foreach(dep IN LISTS arg_DEPENDS)
      if(dep MATCHES "^sessiondep::(.*)")
          set(tgt "sessiondep_${CMAKE_MATCH_1}_external")
          if(TARGET ${tgt})
              list(APPEND fixed_depends "sessiondep_${CMAKE_MATCH_1}_external")
          else()
              message(DEBUG "${tgt} not found for ${dep}, probably a secondary target?")
          endif()
      else()
          list(APPEND fixed_depends "${dep}")
      endif()
  endforeach()

  string(TOUPPER "${target}" prefix)

  if(NOT ${prefix}_SOURCE)
      message(FATAL_ERROR "Unable to build ${target}: ${prefix}_SOURCE not set")
  endif()

  sessiondep_expand_urls(urls ${${prefix}_SOURCE} ${${prefix}_MIRROR})
  ExternalProject_Add("sessiondep_${target}_external"
    DEPENDS ${fixed_depends}
    BUILD_IN_SOURCE ON
    PREFIX ${DEPS_SOURCEDIR}
    URL ${urls}
    URL_HASH ${${prefix}_HASH}
    ${no_idiotic_extract}
    DOWNLOAD_NO_PROGRESS ON
    PATCH_COMMAND ${arg_PATCH_COMMAND}
    ${configure}
    ${build}
    ${install}
    BUILD_BYPRODUCTS ${arg_BUILD_BYPRODUCTS}
  )
endfunction()
