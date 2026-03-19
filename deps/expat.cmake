set(EXPAT_VERSION 2.7.1)
string(REPLACE "." "_" EXPAT_TAG "R_${EXPAT_VERSION}")
set(EXPAT_MIRROR https://github.com/libexpat/libexpat/releases/download/${EXPAT_TAG})
set(EXPAT_SOURCE expat-${EXPAT_VERSION}.tar.xz)
set(EXPAT_HASH SHA512=4c9a6c1c1769d2c4404da083dd3013dbc73883da50e2b7353db2349a420e9b6d27cac7dbcb645991d6c7cdbf79bd88486fc1ac353084ce48e61081fb56e13d46)


sessiondep_build_external(expat
    CONFIGURE_COMMAND ./configure ${sessiondeps_cross_host} --prefix=${SESSIONDEPS_DESTDIR} --enable-static
    --disable-shared --with-pic --without-examples --without-tests --without-docbook --without-xmlwf
    "CC=${sessiondeps_cc}" "CFLAGS=${sessiondeps_CFLAGS}"
)
sessiondep_static_simple(expat)
