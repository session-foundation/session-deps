include("${CMAKE_CURRENT_LIST_DIR}/StaticBuild.cmake")

set(LIBNGTCP2_VERSION 1.15.0 CACHE STRING "ngtcp2 version")
set(LIBNGTCP2_MIRROR ${LOCAL_MIRROR} https://github.com/ngtcp2/ngtcp2/releases/download/v${LIBNGTCP2_VERSION}
    CACHE STRING "ngtcp2 mirror(s)")
set(LIBNGTCP2_SOURCE ngtcp2-${LIBNGTCP2_VERSION}.tar.xz)
set(LIBNGTCP2_HASH SHA512=8d621f49561f80242ec1737ac9706adf7525c17e268f84dbb05c21fd9346921d458d8e64eebad50e4c04d4059aecb5c00245f7fde41781a31fe7da9634b1b222
    CACHE STRING "ngtcp2 source hash")


session_dep(gnutls 3.7.2)

sessiondep_build_external(libngtcp2
    CONFIGURE_COMMAND ./configure ${build_host} --prefix=${SESSIONDEPS_DESTDIR} --with-pic
    --with-sysroot=${SESSIONDEPS_DESTDIR}
    --enable-lib-only --disable-shared --enable-static
    --with-gnutls --without-openssl --without-boringssl --without-picotls --without-wolfssl
    --without-libbrotlienc --without-libbrotlidec --without-libev --without-libnghttp3
    "PKG_CONFIG_LIBDIR=${SESSIONDEPS_DESTDIR}/lib/pkgconfig" "PKG_CONFIG=pkg-config"
    "CPPFLAGS=-I${SESSIONDEPS_DESTDIR}/include" "LDFLAGS=-L${SESSIONDEPS_DESTDIR}/lib${sessiondeps_apple_ldflags_arch}"
    "CC=${sessiondeps_cc}" "CXX=${sessiondeps_cxx}"
    "CFLAGS=${sessiondeps_CFLAGS}${sessiondeps_apple_cflags_arch}" "CXXFLAGS=${sessiondeps_CXXFLAGS}${sessiondeps_apple_cxxflags_arch}"
    ${sessiondeps_cross_rc}
    DEPENDS sessiondep::gnutls
    BUILD_BYPRODUCTS
    ${SESSIONDEPS_DESTDIR}/lib/libngtcp2.a
    ${SESSIONDEPS_DESTDIR}/lib/libngtcp2_crypto_gnutls.a
    ${SESSIONDEPS_DESTDIR}/include/ngtcp2/ngtcp2.h
)

sessiondep_static_target(sessiondep_ext_libngtcp2 libngtcp2 libngtcp2.a)
target_compile_definitions(sessiondep_ext_libngtcp2 INTERFACE -DNGTCP2_STATICLIB)

sessiondep_static_target(sessiondep_ext_libngtcp2_crypto_gnutls libngtcp2 libngtcp2_crypto_gnutls.a
    sessiondep::gnutls sessiondep_ext_libngtcp2)
