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
        message(WARNING "Static OpenSSL cross builds are only set up for 64-bit mingw; OpenSSL "
            "will guess a target from the build host for ${ARCH_TRIPLET}")
    endif()
endif()

# --libdir=lib because OpenSSL otherwise installs to lib64 on 64-bit Linux, which is not where
# anything else here looks.
sessiondep_build_external(libssl
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env "CC=${sessiondeps_cc}" ${openssl_env}
        ./Configure ${openssl_target} --prefix=${SESSIONDEPS_DESTDIR} --libdir=lib
        "CFLAGS=${sessiondeps_CFLAGS}"
        no-shared no-apps no-docs no-tests
        no-capieng no-dso no-gost no-md2 no-rc5 no-rdrand no-rfc3779 no-sctp no-ssl-trace no-ssl3
        no-weak-ssl-ciphers no-zlib no-zlib-dynamic
    # build_libs/install_dev are the libraries, headers and .pc files and nothing else; the default
    # `make` and `make install_sw` would additionally build the engines and the openssl cli tool.
    BUILD_COMMAND ${sessiondeps_make} build_libs
    INSTALL_COMMAND ${sessiondeps_make} install_dev
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
