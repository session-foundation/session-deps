set(NETTLE_VERSION 3.10.2 CACHE STRING "nettle version")
set(NETTLE_MIRROR https://ftp.gnu.org/gnu/nettle CACHE STRING "nettle mirror(s)")
set(NETTLE_SOURCE nettle-${NETTLE_VERSION}.tar.gz)
set(NETTLE_HASH SHA512=bf37ddd7dca8e78488da2a5286dcf16761d527d620572b42f2ad27bb8ee8c12999d92b0272e06f53766e7155a3f4a1ab7ad9c4b1c3caec47c031878b6b1772fb
    CACHE STRING "nettle source hash")

session_dep(libgmp 6)

sessiondep_build_external(nettle
    CONFIGURE_COMMAND ./configure ${sessiondeps_sane_cross_host} --disable-shared --prefix=${SESSIONDEPS_DESTDIR} --libdir=${SESSIONDEPS_DESTDIR}/lib
        --enable-pic --disable-openssl --disable-documentation
        "CC=${sessiondeps_cc}" "CXX=${sessiondeps_cxx}"
        "CFLAGS=${sessiondeps_CFLAGS}${sessiondeps_apple_cflags_arch}" "CXXFLAGS=${sessiondeps_CXXFLAGS}${sessiondeps_apple_cxxflags_arch}"
        "CPPFLAGS=-I${SESSIONDEPS_DESTDIR}/include"
        "LDFLAGS=-L${SESSIONDEPS_DESTDIR}/lib${sessiondeps_apple_ldflags_arch}"

    DEPENDS sessiondep::libgmp
    BUILD_BYPRODUCTS
    ${SESSIONDEPS_DESTDIR}/lib/libnettle.a
    ${SESSIONDEPS_DESTDIR}/lib/libhogweed.a
    ${SESSIONDEPS_DESTDIR}/include/nettle/version.h
)

sessiondep_static_target(sessiondep_ext_nettle nettle libnettle.a)
sessiondep_static_target(sessiondep_ext_hogweed nettle libhogweed.a sessiondep_ext_nettle sessiondep::libgmp)
