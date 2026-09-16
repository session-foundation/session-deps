set(ZLIB_VERSION 1.3.2)
set(ZLIB_MIRROR https://zlib.net)
set(ZLIB_SOURCE zlib-${ZLIB_VERSION}.tar.xz)
set(ZLIB_HASH SHA256=d7a0654783a4da529d1bb793b7ad9c3318020af77667bcae35f95d0e42a792f3)


sessiondep_build_external(zlib
    CONFIGURE_COMMAND
    ${CMAKE_COMMAND} -E env "CC=${sessiondeps_cc}" "CFLAGS=${sessiondeps_CFLAGS} -fPIC" ${sessiondeps_cross_rc}
    ./configure --prefix=${SESSIONDEPS_DESTDIR} --static
    BUILD_BYPRODUCTS
    ${SESSIONDEPS_DESTDIR}/lib/libz.a
    ${SESSIONDEPS_DESTDIR}/include/zlib.h
)
sessiondep_static_target(sessiondep_ext_zlib zlib libz.a)
