set(NETTLE_VERSION 4.0)
set(NETTLE_MIRROR https://ftp.gnu.org/gnu/nettle)
set(NETTLE_SOURCE nettle-${NETTLE_VERSION}.tar.gz)
set(NETTLE_HASH SHA512=833303d94f5a67094011ad4dd931fffdb9adf679b4df241a544a08194a66e6e449398b704ba5b29d52c1c3b5ada6f6dc18b24d1adb3382a68470a11645bf13cd)

session_dep(libgmp 6)

sessiondep_build_external(nettle
    CONFIGURE_COMMAND ./configure ${sessiondeps_cross_host} --disable-shared --prefix=${SESSIONDEPS_DESTDIR} --libdir=${SESSIONDEPS_DESTDIR}/lib
        --enable-pic --disable-openssl --disable-documentation
        "CC=${sessiondeps_cc}" "CXX=${sessiondeps_cxx}"
        "CFLAGS=${sessiondeps_CFLAGS}" "CXXFLAGS=${sessiondeps_CXXFLAGS}"
        "CPPFLAGS=-I${SESSIONDEPS_DESTDIR}/include"
        "LDFLAGS=${sessiondeps_ldflags}"

    DEPENDS sessiondep::libgmp
    BUILD_BYPRODUCTS
    ${SESSIONDEPS_DESTDIR}/lib/libnettle.a
    ${SESSIONDEPS_DESTDIR}/lib/libhogweed.a
    ${SESSIONDEPS_DESTDIR}/include/nettle/version.h
)

sessiondep_static_target(sessiondep_ext_nettle nettle libnettle.a)
sessiondep_static_target(sessiondep_ext_hogweed nettle libhogweed.a sessiondep_ext_nettle sessiondep::libgmp)
