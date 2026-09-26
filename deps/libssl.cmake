set(LIBSSL_VERSION 3.5.8)
set(LIBSSL_MIRROR https://github.com/openssl/openssl/releases/download/openssl-${LIBSSL_VERSION})
set(LIBSSL_SOURCE openssl-${LIBSSL_VERSION}.tar.gz)
set(LIBSSL_HASH SHA256=a8f84a39918ec6415ce765d9b429d313ba97b8143169c172e734b9514464f5b2)


# OpenSSL takes its target from POSIX::uname() rather than an autotools-style --host, and offers no
# way to redirect that guess, so a cross build has to name the target itself; left to guess it picks
# up the build host and emits host-flavoured assembly that the cross assembler then rejects.  Only
# mingw is wired up here; other cross targets need a mapping from ARCH_TRIPLET onto one of the
# target names in OpenSSL's Configurations/*.conf before they will produce anything but host
# binaries.
set(openssl_target)
set(openssl_env)
if(CMAKE_CROSSCOMPILING)
    if(ARCH_TRIPLET MATCHES "^x86_64-.*mingw")
        set(openssl_target mingw64)
        # The mingw64 target's tool names are unprefixed, so without these the host's ar would be
        # left to archive the cross-built objects.
        list(APPEND openssl_env "AR=${CMAKE_AR}" "RANLIB=${CMAKE_RANLIB}")
        if(CMAKE_RC_COMPILER)
            list(APPEND openssl_env RC=${CMAKE_RC_COMPILER})
        endif()
    else()
        message(FATAL_ERROR "The static OpenSSL build is only set up for native and 64-bit mingw "
            "targets; ${ARCH_TRIPLET} needs an OpenSSL target name mapped in libssl.cmake first")
    endif()
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    # A native build is not safe to leave to the guess either: a 32-bit userland on a 64-bit kernel
    # (an armhf container on an arm64 host, say) reports the kernel's machine, and OpenSSL then
    # emits assembly the toolchain cannot assemble.  The compiler knows what it is building for.
    execute_process(
        COMMAND ${CMAKE_C_COMPILER} -dumpmachine
        OUTPUT_VARIABLE openssl_machine
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE openssl_machine_rc)
    if(openssl_machine_rc)
        message(FATAL_ERROR "The static OpenSSL build could not determine the compiler's target "
            "(${CMAKE_C_COMPILER} -dumpmachine failed)")
    endif()
    if(openssl_machine MATCHES "^aarch64")
        set(openssl_target linux-aarch64)
    elseif(openssl_machine MATCHES "^arm")
        set(openssl_target linux-armv4)
    elseif(openssl_machine MATCHES "^(x86_64|amd64)")
        set(openssl_target linux-x86_64)
    elseif(openssl_machine MATCHES "^i[3-6]86")
        set(openssl_target linux-x86)
    elseif(openssl_machine MATCHES "^riscv64")
        set(openssl_target linux64-riscv64)
    elseif(openssl_machine MATCHES "^powerpc64le")
        set(openssl_target linux-ppc64le)
    elseif(openssl_machine MATCHES "^s390x")
        set(openssl_target linux64-s390x)
    else()
        message(WARNING "No OpenSSL target is mapped for ${openssl_machine}; OpenSSL will guess "
            "one from uname")
    endif()
endif()

# The archives are post-processed to hide everything but the public API (see
# extra/libssl-hide-internals.cmake), which merges each archive's members with a partial link; that
# has to be a plain object merge, so OpenSSL is built without LTO whatever the other dependencies
# use.
set(openssl_cflags "${sessiondeps_CFLAGS} -fno-lto")

foreach(tool CMAKE_AR CMAKE_LINKER CMAKE_NM)
    if(NOT ${tool})
        message(FATAL_ERROR "The static OpenSSL build needs ${tool} to be set")
    endif()
endforeach()
set(openssl_hide_tools -DAR=${CMAKE_AR} -DLD=${CMAKE_LINKER} -DNM=${CMAKE_NM})
if(NOT APPLE)
    if(NOT CMAKE_OBJCOPY)
        message(FATAL_ERROR "The static OpenSSL build needs objcopy (CMAKE_OBJCOPY is not set)")
    endif()
    list(APPEND openssl_hide_tools -DOBJCOPY=${CMAKE_OBJCOPY})
endif()

# --libdir=lib because OpenSSL otherwise installs to lib64 on 64-bit Linux, which is not where
# anything else here looks.
sessiondep_build_external(libssl
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env "CC=${sessiondeps_cc}" ${openssl_env}
        ./Configure ${openssl_target} --prefix=${SESSIONDEPS_DESTDIR} --libdir=lib
        "CFLAGS=${openssl_cflags}"
        no-shared no-apps no-docs no-tests
        no-capieng no-dso no-gost no-md2 no-rc5 no-rdrand no-rfc3779 no-sctp no-ssl-trace no-ssl3
        no-weak-ssl-ciphers no-zlib no-zlib-dynamic
    # build_libs/install_dev are the libraries, headers and .pc files and nothing else; the default
    # `make` and `make install_sw` would additionally build the engines and the openssl cli tool.
    BUILD_COMMAND ${sessiondeps_make} build_libs
    INSTALL_COMMAND ${sessiondeps_make} install_dev
    COMMAND ${CMAKE_COMMAND} -DLIBDIR=${SESSIONDEPS_DESTDIR}/lib -DSOURCE_DIR=<SOURCE_DIR>
        ${openssl_hide_tools} -P ${CMAKE_CURRENT_LIST_DIR}/extra/libssl-hide-internals.cmake
    BUILD_BYPRODUCTS
    ${SESSIONDEPS_DESTDIR}/lib/libssl.a
    ${SESSIONDEPS_DESTDIR}/lib/libcrypto.a
    ${SESSIONDEPS_DESTDIR}/include/openssl/ssl.h
)

set(libcrypto_extra_deps ${CMAKE_DL_LIBS})
if(WIN32)
    list(APPEND libcrypto_extra_deps ws2_32 crypt32)
elseif(NOT ANDROID)
    # Android has threads in libc; everywhere else libcrypto's locking needs pthreads.
    list(APPEND libcrypto_extra_deps -pthread)
endif()

sessiondep_static_target(sessiondep_ext_libcrypto libssl libcrypto.a ${libcrypto_extra_deps})
sessiondep_static_target(sessiondep_ext_libssl libssl libssl.a sessiondep_ext_libcrypto)
