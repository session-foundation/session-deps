set(LIBSODIUM_VERSION 1.0.21 CACHE STRING "libsodium version")
set(LIBSODIUM_MIRROR
  https://download.libsodium.org/libsodium/releases
  https://github.com/jedisct1/libsodium/releases/download/${LIBSODIUM_VERSION}-RELEASE
  CACHE STRING "libsodium mirror(s)")
set(LIBSODIUM_SOURCE libsodium-${LIBSODIUM_VERSION}.tar.gz)
set(LIBSODIUM_HASH SHA512=ee8cc2f3f5707b172bf75d8c04afbd5f0c83c6f94dbab3f988f07aab716d96f1662556a59e09b3d83c3bd5c22f59327ad95937bf499d523c86146f4df830f777
  CACHE STRING "libsodium source hash")

sessiondep_build_external(libsodium
    PATCH_COMMAND patch -p1 -i ${CMAKE_CURRENT_LIST_DIR}/patches/libsodium-1.0.21-fix-arm64-compilation.patch
    CONFIGURE_COMMAND ./configure ${sessiondeps_cross_host} ${sessiondeps_cross_rc}
      --prefix=${SESSIONDEPS_DESTDIR} --disable-shared --enable-static
      --with-pic "CC=${sessiondeps_cc}" "CFLAGS=${sessiondeps_CFLAGS}"
)

sessiondep_static_simple(libsodium)
