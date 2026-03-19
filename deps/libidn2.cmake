set(LIBIDN2_VERSION 2.3.8)
set(LIBIDN2_MIRROR https://ftp.gnu.org/gnu/libidn)
set(LIBIDN2_SOURCE libidn2-${LIBIDN2_VERSION}.tar.gz)
set(LIBIDN2_HASH SHA512=4d8427c0f115268132f7544e80a808c883ab1406338f6c529b1a586b016d57aedb0857f66166eb8d9f37d70efc9dccf907b673b43b17bcf258c8797db1e829ce)

session_dep(libunistring 0.9)


sessiondep_build_external(libidn2
    # Patch out building the tools because they make a compilation with -flto take a very long time:
    PATCH_COMMAND patch -p1 -i ${CMAKE_CURRENT_LIST_DIR}/patches/libidn2-no-tools.patch
    CONFIGURE_COMMAND ./configure ${sessiondeps_cross_host} --disable-shared --disable-doc --prefix=${SESSIONDEPS_DESTDIR} --with-pic
        "CC=${sessiondeps_cc}" "CXX=${sessiondeps_cxx}"
        "CFLAGS=${sessiondeps_CFLAGS}${sessiondeps_apple_cflags_arch}"
        "CXXFLAGS=${sessiondeps_CXXFLAGS}${sessiondeps_apple_cflags_arch}"
        ${sessiondeps_cross_rc}
    DEPENDS sessiondep::libunistring
    BUILD_BYPRODUCTS ${SESSIONDEPS_DESTDIR}/lib/libidn2.a ${SESSIONDEPS_DESTDIR}/include/idn2.h)

sessiondep_static_simple(libidn2 sessiondep::libunistring)
