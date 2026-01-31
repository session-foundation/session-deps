include("${CMAKE_CURRENT_LIST_DIR}/StaticBuild.cmake")

set(LIBUNISTRING_VERSION 1.3 CACHE STRING "libunistring version")
set(LIBUNISTRING_MIRROR ${LOCAL_MIRROR} https://ftp.gnu.org/gnu/libunistring
    CACHE STRING "libunistring mirror(s)")
set(LIBUNISTRING_SOURCE libunistring-${LIBUNISTRING_VERSION}.tar.xz)
set(LIBUNISTRING_HASH SHA512=864d42b1d4ae4941fe5c8327d6726ab8e3a35d2d5f9d25ce4859a72ab2f549a7b68f58638cf8767d863f58161d1a4053495d185860964a942d6750e42facf931
    CACHE STRING "libunistring source hash")


sessiondep_build_external(libunistring
    CONFIGURE_COMMAND ./configure ${build_host} --disable-shared --prefix=${SESSIONDEPS_DESTDIR} --with-pic
        "CC=${sessiondeps_cc}" "CXX=${sessiondeps_cxx}"
        "CFLAGS=${sessiondeps_CFLAGS}${sessiondeps_apple_cflags_arch}" "CXXFLAGS=${sessiondeps_CXXFLAGS}${sessiondeps_apple_cflags_arch}"
        "CPPFLAGS=-I${SESSIONDEPS_DESTDIR}/include" "LDFLAGS=-L${SESSIONDEPS_DESTDIR}/lib${sessiondeps_apple_ldflags_arch}"
        ${sessiondeps_cross_rc}
    BUILD_BYPRODUCTS ${SESSIONDEPS_DESTDIR}/lib/libunistring.a ${SESSIONDEPS_DESTDIR}/include/unistr.h)
sessiondep_static_target(sessiondep_ext_libunistring libunistring_external libunistring.a)
