include("${CMAKE_CURRENT_LIST_DIR}/StaticBuild.cmake")

set(GMP_VERSION 6.3.0 CACHE STRING "gmp version")
set(GMP_MIRROR ${LOCAL_MIRROR} https://gmplib.org/download/gmp
    CACHE STRING "gmp mirror(s)")
set(GMP_SOURCE gmp-${GMP_VERSION}.tar.xz)
set(GMP_HASH SHA512=e85a0dab5195889948a3462189f0e0598d331d3457612e2d3350799dba2e244316d256f8161df5219538eb003e4b5343f989aaa00f96321559063ed8c8f29fd2
    CACHE STRING "gmp source hash")


sessiondep_build_external(gmp
    # These two patches are applied to gmplib upstream (and come via the Debian package):
    PATCH_COMMAND
        patch -p1 -i ${CMAKE_CURRENT_LIST_DIR}/patches/gmplib-fix-acinclude-m4-for-gcc-15.patch &&
        patch -p1 -i ${CMAKE_CURRENT_LIST_DIR}/patches/gmplib-trust-vsprintf-return.patch
    CONFIGURE_COMMAND ./configure ${build_host} --disable-shared --prefix=${DEPS_DESTDIR} --with-pic
        "CC=${deps_cc}" "CXX=${deps_cxx}" "CFLAGS=${deps_CFLAGS}${apple_cflags_arch}" "CXXFLAGS=${deps_CXXFLAGS}${apple_cxxflags_arch}"
        "LDFLAGS=-L${DEPS_DESTDIR}/lib${apple_ldflags_arch}" ${cross_rc} CC_FOR_BUILD=cc CPP_FOR_BUILD=cpp
)
sessiondep_static_target(sessiondep_ext_libgmp gmp libgmp.a)
