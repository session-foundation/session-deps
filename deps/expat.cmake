set(EXPAT_VERSION 2.8.4)
string(REPLACE "." "_" EXPAT_TAG "R_${EXPAT_VERSION}")
set(EXPAT_MIRROR https://github.com/libexpat/libexpat/releases/download/${EXPAT_TAG})
set(EXPAT_SOURCE expat-${EXPAT_VERSION}.tar.xz)
set(EXPAT_HASH SHA512=00a34340b4fdc3baee6dbd83df3e41710ebffb38dc23664406be187a73f1e948451568fea07b6f33532b6b6244650808ce157255bcf6216d98267535cc97f3cd)


sessiondep_build_external(expat
    CONFIGURE_COMMAND ./configure ${sessiondeps_cross_host} --prefix=${SESSIONDEPS_DESTDIR} --enable-static
    --disable-shared --with-pic --without-examples --without-tests --without-docbook --without-xmlwf
    "CC=${sessiondeps_cc}" "CFLAGS=${sessiondeps_CFLAGS}"
)
sessiondep_static_simple(expat)
