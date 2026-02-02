set(LIBTASN1_VERSION 4.20.0 CACHE STRING "libtasn1 version")
set(LIBTASN1_MIRROR https://ftp.gnu.org/gnu/libtasn1 CACHE STRING "libtasn1 mirror(s)")
set(LIBTASN1_SOURCE libtasn1-${LIBTASN1_VERSION}.tar.gz)
set(LIBTASN1_HASH SHA512=0c0660085f5e80537aa3d65197967029be6cc5e27d7029789713902989c1694fdb49421ae0415b79b953e11893bb4bdaada85f7aff847dd0bb4075c91887e7b4
    CACHE STRING "libtasn1 source hash")



set(libtasn_extra_cflags)
if(CMAKE_C_COMPILER_ID STREQUAL GNU)
    # libtasn1 under current GCC produces some incredibly verbose warnings; disable them:
    set(libtasn_extra_cflags " -Wno-analyzer-null-dereference -Wno-analyzer-use-of-uninitialized-value -Wno-analyzer-out-of-bounds")
endif()

sessiondep_build_external(libtasn1
    CONFIGURE_COMMAND ./configure ${build_host} --disable-shared --disable-doc --prefix=${SESSIONDEPS_DESTDIR} --with-pic
        "CC=${sessiondeps_cc}" "CXX=${sessiondeps_cxx}"
        "CFLAGS=${sessiondeps_CFLAGS}${sessiondeps_apple_cflags_arch}${libtasn_extra_cflags}"
        "CXXFLAGS=${sessiondeps_CXXFLAGS}${sessiondeps_apple_cflags_arch}${libtasn_extra_cflags}"
        "CPPFLAGS=-I${SESSIONDEPS_DESTDIR}/include" "LDFLAGS=-L${SESSIONDEPS_DESTDIR}/lib${sessiondeps_apple_ldflags_arch}"
        ${sessiondeps_cross_rc}
    BUILD_BYPRODUCTS ${SESSIONDEPS_DESTDIR}/lib/libtasn1.a ${SESSIONDEPS_DESTDIR}/include/libtasn1.h)

sessiondep_static_simple(libtasn1)
