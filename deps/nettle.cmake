include("${CMAKE_CURRENT_LIST_DIR}/StaticBuild.cmake")

set(NETTLE_VERSION 3.10.2 CACHE STRING "nettle version")
set(NETTLE_MIRROR ${LOCAL_MIRROR} https://ftp.gnu.org/gnu/nettle
    CACHE STRING "nettle mirror(s)")
set(NETTLE_SOURCE nettle-${NETTLE_VERSION}.tar.gz)
set(NETTLE_HASH SHA512=bf37ddd7dca8e78488da2a5286dcf16761d527d620572b42f2ad27bb8ee8c12999d92b0272e06f53766e7155a3f4a1ab7ad9c4b1c3caec47c031878b6b1772fb
    CACHE STRING "nettle source hash")

session_dep(libgmp 6)

sessiondep_build_external(nettle
    CONFIGURE_COMMAND ./configure ${build_host} --disable-shared --prefix=${DEPS_DESTDIR} --libdir=${DEPS_DESTDIR}/lib
        --enable-pic --disable-openssl --disable-documentation
        "CC=${deps_cc}" "CXX=${deps_cxx}"
        "CFLAGS=${deps_CFLAGS}${apple_cflags_arch}" "CXXFLAGS=${deps_CXXFLAGS}${apple_cxxflags_arch}"
        "CPPFLAGS=-I${DEPS_DESTDIR}/include"
        "LDFLAGS=-L${DEPS_DESTDIR}/lib${apple_ldflags_arch}"

    DEPENDS sessiondep::libgmp
    BUILD_BYPRODUCTS
    ${DEPS_DESTDIR}/lib/libnettle.a
    ${DEPS_DESTDIR}/lib/libhogweed.a
    ${DEPS_DESTDIR}/include/nettle/version.h
)

sessiondep_static_target(sessiondep_ext_nettle nettle_external libnettle.a)
sessiondep_static_target(sessiondep_ext_hogweed nettle_external libhogweed.a sessiondep_ext_nettle sessiondep::libgmp)
