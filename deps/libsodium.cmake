set(LIBSODIUM_VERSION 1.0.22)
set(LIBSODIUM_MIRROR
  https://download.libsodium.org/libsodium/releases
  https://github.com/jedisct1/libsodium/releases/download/${LIBSODIUM_VERSION}-RELEASE)
set(LIBSODIUM_SOURCE libsodium-${LIBSODIUM_VERSION}.tar.gz)
set(LIBSODIUM_HASH SHA512=8f392de781f09578d9a32000a4198e8d199ab910743017af3b3c5cae8053f745bcc885a9417fcaffb03b832400d829aef3a93c065bbb77b92598d882b6dcf187)

sessiondep_build_external(libsodium
    CONFIGURE_COMMAND ./configure ${sessiondeps_cross_host} ${sessiondeps_cross_rc}
      --prefix=${SESSIONDEPS_DESTDIR} --disable-shared --enable-static
      --with-pic "CC=${sessiondeps_cc}" "CFLAGS=${sessiondeps_CFLAGS}"
)

sessiondep_static_simple(libsodium)
