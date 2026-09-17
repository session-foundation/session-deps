set(LIBUNISTRING_VERSION 1.4.2)
set(LIBUNISTRING_MIRROR https://ftp.gnu.org/gnu/libunistring)
set(LIBUNISTRING_SOURCE libunistring-${LIBUNISTRING_VERSION}.tar.xz)
set(LIBUNISTRING_HASH SHA512=0215f7f40f426227eca5174140654a3fa43ac1520eeb212c2ba08043470f905687b2703afdda12e9635359a6187643900136b6bb11b422bd7567d17ca71b555f)


sessiondep_build_external(libunistring
    CONFIGURE_COMMAND ./configure ${sessiondeps_cross_host} --disable-shared --prefix=${SESSIONDEPS_DESTDIR} --with-pic
        "CC=${sessiondeps_cc}" "CXX=${sessiondeps_cxx}"
        "CFLAGS=${sessiondeps_CFLAGS}" "CXXFLAGS=${sessiondeps_CXXFLAGS}"
        "CPPFLAGS=-I${SESSIONDEPS_DESTDIR}/include" "LDFLAGS=${sessiondeps_ldflags}"
        ${sessiondeps_cross_rc}
    BUILD_BYPRODUCTS ${SESSIONDEPS_DESTDIR}/lib/libunistring.a ${SESSIONDEPS_DESTDIR}/include/unistr.h)

sessiondep_static_simple(libunistring)
