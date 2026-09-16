set(LIBSSL_VERSION 3.5.8)
set(LIBSSL_MIRROR https://github.com/openssl/openssl/releases/download/openssl-${LIBSSL_VERSION})
set(LIBSSL_SOURCE openssl-${LIBSSL_VERSION}.tar.gz)
set(LIBSSL_HASH SHA256=a8f84a39918ec6415ce765d9b429d313ba97b8143169c172e734b9514464f5b2)


# OpenSSL has its own configuration system that sniffs the build machine rather than accepting an
# autotools-style --host, so a cross build needs a target name it recognises.  Only mingw is wired
# up here; other cross targets need a mapping from ARCH_TRIPLET onto one of the target names in
# OpenSSL's Configurations/*.conf before they will produce anything but host binaries.
set(openssl_env)
if(CMAKE_CROSSCOMPILING)
    if(ARCH_TRIPLET MATCHES mingw)
        set(openssl_env SYSTEM=MINGW64)
        if(CMAKE_RC_COMPILER)
            list(APPEND openssl_env RC=${CMAKE_RC_COMPILER})
        endif()
    else()
        message(WARNING "Static OpenSSL cross builds are only set up for mingw; ./config will "
            "guess a target from the build host for ${ARCH_TRIPLET}")
    endif()
endif()

# --libdir=lib because OpenSSL otherwise installs to lib64 on 64-bit Linux, which is not where
# anything else here looks.
sessiondep_build_external(libssl
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env "CC=${sessiondeps_cc}" ${openssl_env}
        ./config --prefix=${SESSIONDEPS_DESTDIR} --libdir=lib "CFLAGS=${sessiondeps_CFLAGS}"
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
