set(SPNG_VERSION 0.7.4)
set(SPNG_MIRROR https://github.com/randy408/libspng/archive/refs/tags/v${SPNG_VERSION})
set(SPNG_SOURCE libspng-${SPNG_VERSION}.tar.gz)
set(SPNG_HASH SHA512=cd729653599ed97f80d19f3048c1b3bc2ac16f922b3465804b1913bc45d9fc8b28b56bc2121fda36e9d3dcdd12612cced5383313b722a5342b613f8781879f1a)

session_dep(zlib 1.2)

# Named for the pkg-config module rather than the archive: upstream's meson builds library('spng'),
# so the module is spng.pc while the file is libspng.a.
sessiondep_build_external(spng
    CONFIGURE_COMMAND DEFAULT_MESON
      -Dbuild_examples=false
      -Ddev_build=false
      -Dbenchmarks=false
    DEPENDS sessiondep::zlib
    BUILD_BYPRODUCTS
      ${SESSIONDEPS_DESTDIR}/lib/libspng.a
      ${SESSIONDEPS_DESTDIR}/include/spng.h
)

sessiondep_static_simple(spng sessiondep::zlib)

# spng.h declares its API __declspec(dllimport) on Windows unless told the library is static.
target_compile_definitions(sessiondep_ext_spng INTERFACE SPNG_STATIC)
