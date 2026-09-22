set(LIBICONV_VERSION 1.19)
set(LIBICONV_MIRROR https://ftp.gnu.org/gnu/libiconv)
set(LIBICONV_SOURCE libiconv-${LIBICONV_VERSION}.tar.gz)
set(LIBICONV_HASH SHA512=1e8150f9bca907579330cd9c44ebbee46a260271fbe8f50d5ee24a39ef29c8d254505e85c3409324f7440596da711a8bd49e89f848a6be0cb3238a58c24aaecd)

# Only for targets whose C library lacks iconv.  Elsewhere there is nothing to build, and a GNU
# iconv.h anywhere a recipe looks would pair its `#define iconv_open libiconv_open` with libc's
# implementation.  Where it is built it goes in SESSIONDEPS_PROVIDERS_DIR rather than the destdir, so
# that only a recipe that asks for it gets it (see StaticBuild.cmake).
#
# The library, libcharset and localcharset.h are built by name, and installed the way the top-level
# install-lib target does, because install-lib depends on `all`, which also builds the iconv
# program.  The archive is effectively a single object: iconv.c includes every converter so that
# iconv_open() can dispatch on a name at runtime, so linking it at all brings in every encoding
# table, about 900KB.
if(NOT sessiondeps_need_libiconv)
    add_library(sessiondep_ext_libiconv INTERFACE)
else()
    set(_libiconv_prefix ${SESSIONDEPS_PROVIDERS_DIR})
    sessiondep_build_external(libiconv
        CONFIGURE_COMMAND ./configure ${sessiondeps_cross_host} --prefix=${_libiconv_prefix}
            --enable-static --disable-shared --with-pic --disable-nls
            "CC=${sessiondeps_cc}" "CFLAGS=${sessiondeps_CFLAGS}" ${sessiondeps_cross_rc}
        BUILD_COMMAND ${sessiondeps_make} -C libcharset
            COMMAND ${sessiondeps_make} lib/localcharset.h
            COMMAND ${sessiondeps_make} -C lib
        INSTALL_COMMAND ${sessiondeps_make} -C lib install-lib
                libdir=${_libiconv_prefix}/lib includedir=${_libiconv_prefix}/include
            COMMAND ${CMAKE_COMMAND} -E copy include/iconv.h.inst ${_libiconv_prefix}/include/iconv.h
        BUILD_BYPRODUCTS
            ${_libiconv_prefix}/lib/libiconv.a
            ${_libiconv_prefix}/include/iconv.h
    )

    sessiondep_static_target(sessiondep_ext_libiconv libiconv libiconv.a PREFIX ${_libiconv_prefix})
endif()
