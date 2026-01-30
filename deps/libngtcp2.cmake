include("${CMAKE_CURRENT_LIST_DIR}/StaticBuild.cmake")

set(NGTCP2_VERSION 1.15.0 CACHE STRING "ngtcp2 version")
set(NGTCP2_MIRROR ${LOCAL_MIRROR} https://github.com/ngtcp2/ngtcp2/releases/download/v${NGTCP2_VERSION}
    CACHE STRING "ngtcp2 mirror(s)")
set(NGTCP2_SOURCE ngtcp2-${NGTCP2_VERSION}.tar.xz)
set(NGTCP2_HASH SHA512=8d621f49561f80242ec1737ac9706adf7525c17e268f84dbb05c21fd9346921d458d8e64eebad50e4c04d4059aecb5c00245f7fde41781a31fe7da9634b1b222
    CACHE STRING "ngtcp2 source hash")


session_dep(gnutls 3.7.2)

sessiondep_build_external(ngtcp2
    CONFIGURE_COMMAND ./configure ${build_host} --prefix=${DEPS_DESTDIR} --with-pic
    --with-sysroot=${DEPS_DESTDIR}
    --enable-lib-only --disable-shared --enable-static
    --with-gnutls --without-openssl --without-boringssl --without-picotls --without-wolfssl
    --without-libbrotlienc --without-libbrotlidec --without-libev --without-libnghttp3
    "PKG_CONFIG_LIBDIR=${DEPS_DESTDIR}/lib/pkgconfig" "PKG_CONFIG=pkg-config"
    "CPPFLAGS=-I${DEPS_DESTDIR}/include" "LDFLAGS=-L${DEPS_DESTDIR}/lib${apple_ldflags_arch}"
    "CC=${deps_cc}" "CXX=${deps_cxx}" "CFLAGS=${deps_CFLAGS}${apple_cflags_arch}" "CXXFLAGS=${deps_CXXFLAGS}${apple_cxxflags_arch}" ${cross_rc}
    DEPENDS sessiondep::gnutls
    BUILD_BYPRODUCTS
    ${DEPS_DESTDIR}/lib/libngtcp2.a
    ${DEPS_DESTDIR}/lib/libngtcp2_crypto_gnutls.a
    ${DEPS_DESTDIR}/include/ngtcp2/ngtcp2.h
)

sessiondep_static_target(sessiondep_ext_libngtcp2 ngtcp2_external libngtcp2.a)
target_compile_definitions(sessiondep_ext_libngtcp2 INTERFACE -DNGTCP2_STATICLIB)

sessiondep_static_target(sessiondep_ext_libngtcp2_crypto_gnutls ngtcp2_external libngtcp2_crypto_gnutls.a
    sessiondep::gnutls sessiondep_ext_libngtcp2)
