set(CGIF_VERSION 0.5.4)
set(CGIF_MIRROR https://github.com/dloebl/cgif/archive/refs/tags)
set(CGIF_SOURCE v${CGIF_VERSION}.tar.gz)
set(CGIF_HASH SHA512=f0db0b08b12cebe6d4b0cd695fb24e37a170e57b36cd873a18ac6114c76a5dd082af5f5c5e8452bd9f2e3bb31d943d1692351300bfde5a00a7768a5dea1e146a)

# GIF *save* only -- libvips loads GIF with its own vendored nsgif and needs nothing external for
# that.  libvips will not use cgif unless a quantiser is also present, since writing a GIF means
# reducing to a 256-colour palette, so this is only useful alongside deps/imagequant.cmake.
sessiondep_build_external(cgif
    CONFIGURE_COMMAND DEFAULT_MESON
      -Dexamples=false
      -Dtests=false
      -Dfuzzer=false
    BUILD_BYPRODUCTS
      ${SESSIONDEPS_DESTDIR}/lib/libcgif.a
      ${SESSIONDEPS_DESTDIR}/include/cgif.h
)

sessiondep_static_simple(cgif)
