set(ZLIB_VERSION 1.3.1)
set(ZLIB_MIRROR https://zlib.net)
set(ZLIB_SOURCE zlib-${ZLIB_VERSION}.tar.xz)
set(ZLIB_HASH SHA256=38ef96b8dfe510d42707d9c781877914792541133e1870841463bfa73f883e32)


sessiondep_build_external(zlib
    CONFIGURE_COMMAND
    ${CMAKE_COMMAND} -E env "CC=${sessiondeps_cc}" "CFLAGS=${sessiondeps_CFLAGS} -fPIC" ${sessiondeps_cross_extra}
    ./configure --prefix=${SESSIONDEPS_DESTDIR} --static
    BUILD_BYPRODUCTS
    ${SESSIONDEPS_DESTDIR}/lib/libz.a
    ${SESSIONDEPS_DESTDIR}/include/zlib.h
)
add_static_target(sessiondep_ext_zlib zlib libz.a)
