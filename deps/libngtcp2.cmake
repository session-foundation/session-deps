set(LIBNGTCP2_VERSION 1.25.0)
set(LIBNGTCP2_MIRROR https://github.com/ngtcp2/ngtcp2/releases/download/v${LIBNGTCP2_VERSION})
set(LIBNGTCP2_SOURCE ngtcp2-${LIBNGTCP2_VERSION}.tar.xz)
set(LIBNGTCP2_HASH SHA512=b5ebf0a4248a13b9231ac0b6353adbf6634a19bb57db3cf39947746c399ebc5085f780a540d246b7226bb994a920ad0cc9b755ebd9fe58c18a6838d50b6bc90e)


session_dep(gnutls 3.7.2)

# Upstream fixes merged after 1.25.0 (which 1.26.0 will include); the server-peer-ip-change-pmtu
# one is why consumers require a system ngtcp2 of at least 1.26.0 rather than 1.25.0.
sessiondep_build_external(libngtcp2
    PATCHES libngtcp2-fix-pktlen-check.patch libngtcp2-fix-fallback-dcid-retirement.patch
    libngtcp2-server-peer-ip-change-pmtu.patch
    CONFIGURE_COMMAND ./configure ${sessiondeps_cross_host} --prefix=${SESSIONDEPS_DESTDIR} --with-pic
    --with-sysroot=${SESSIONDEPS_DESTDIR}
    --enable-lib-only --disable-shared --enable-static
    --with-gnutls --without-openssl --without-boringssl --without-picotls --without-wolfssl
    --without-libbrotlienc --without-libbrotlidec --without-libev --without-libnghttp3
    # A static ngtcp2 is needed wherever the system's is too old, which can perfectly well be on a
    # system gnutls, so configure has to see the system .pc files as well as ours.
    ${sessiondeps_pkg_config_env}
    "CPPFLAGS=-I${SESSIONDEPS_DESTDIR}/include" "LDFLAGS=${sessiondeps_ldflags}"
    "CC=${sessiondeps_cc}" "CXX=${sessiondeps_cxx}"
    "CFLAGS=${sessiondeps_CFLAGS}" "CXXFLAGS=${sessiondeps_CXXFLAGS}"
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
