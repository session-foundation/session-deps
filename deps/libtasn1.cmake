include("${CMAKE_CURRENT_LIST_DIR}/StaticBuild.cmake")

set(LIBTASN1_VERSION 4.20.0 CACHE STRING "libtasn1 version")
set(LIBTASN1_MIRROR ${LOCAL_MIRROR} https://ftp.gnu.org/gnu/libtasn1
    CACHE STRING "libtasn1 mirror(s)")
set(LIBTASN1_SOURCE libtasn1-${LIBTASN1_VERSION}.tar.gz)
set(LIBTASN1_HASH SHA512=0c0660085f5e80537aa3d65197967029be6cc5e27d7029789713902989c1694fdb49421ae0415b79b953e11893bb4bdaada85f7aff847dd0bb4075c91887e7b4
    CACHE STRING "libtasn1 source hash")



set(libtasn_extra_cflags)
if(CMAKE_C_COMPILER_ID STREQUAL GNU)
    # libtasn1 under current GCC produces some incredibly verbose warnings; disable them:
    set(libtasn_extra_cflags " -Wno-analyzer-null-dereference -Wno-analyzer-use-of-uninitialized-value -Wno-analyzer-out-of-bounds")
endif()

sessiondep_build_external(libtasn1
    CONFIGURE_COMMAND ./configure ${build_host} --disable-shared --disable-doc --prefix=${DEPS_DESTDIR} --with-pic
        "CC=${deps_cc}" "CXX=${deps_cxx}"
        "CFLAGS=${deps_CFLAGS}${apple_cflags_arch}${libtasn_extra_cflags}"
        "CXXFLAGS=${deps_CXXFLAGS}${apple_cflags_arch}${libtasn_extra_cflags}"
        "CPPFLAGS=-I${DEPS_DESTDIR}/include" "LDFLAGS=-L${DEPS_DESTDIR}/lib${apple_ldflags_arch}" ${cross_rc}
    BUILD_BYPRODUCTS ${DEPS_DESTDIR}/lib/libtasn1.a ${DEPS_DESTDIR}/include/libtasn1.h)

sessiondep_static_target(sessiondep_ext_libtasn1 libtasn1_external libtasn1.a)
