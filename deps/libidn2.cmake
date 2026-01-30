include("${CMAKE_CURRENT_LIST_DIR}/StaticBuild.cmake")

set(LIBIDN2_VERSION 2.3.8 CACHE STRING "libidn2 version")
set(LIBIDN2_MIRROR ${LOCAL_MIRROR} https://ftp.gnu.org/gnu/libidn
    CACHE STRING "libidn2 mirror(s)")
set(LIBIDN2_SOURCE libidn2-${LIBIDN2_VERSION}.tar.gz)
set(LIBIDN2_HASH SHA512=4d8427c0f115268132f7544e80a808c883ab1406338f6c529b1a586b016d57aedb0857f66166eb8d9f37d70efc9dccf907b673b43b17bcf258c8797db1e829ce
    CACHE STRING "libidn2 source hash")

session_dep(libunistring 0.9)


sessiondep_build_external(libidn2
    # Patch out building the tools because they make a compilation with -flto take a very long time:
    PATCH_COMMAND patch -p1 -i ${CMAKE_CURRENT_LIST_DIR}/patches/libidn2-no-tools.patch
    CONFIGURE_COMMAND ./configure ${build_host} --disable-shared --disable-doc --prefix=${DEPS_DESTDIR} --with-pic
        "CC=${deps_cc}" "CXX=${deps_cxx}" "CFLAGS=${deps_CFLAGS}${apple_cflags_arch}" "CXXFLAGS=${deps_CXXFLAGS}${apple_cflags_arch}" ${cross_rc}
    DEPENDS sessiondep::libunistring
    BUILD_BYPRODUCTS ${DEPS_DESTDIR}/lib/libidn2.a ${DEPS_DESTDIR}/include/idn2.h)
sessiondep_static_target(sessiondep_ext_libidn2 libidn2_external libidn2.a sessiondep::libunistring)
