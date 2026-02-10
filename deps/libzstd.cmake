set(LIBZSTD_VERSION 1.5.7 CACHE STRING "zstd version")
set(LIBZSTD_MIRROR ${LOCAL_MIRROR} https://github.com/facebook/zstd/releases/download/v${LIBZSTD_VERSION}
    CACHE STRING "zstd mirror(s)")
set(LIBZSTD_SOURCE zstd-${LIBZSTD_VERSION}.tar.gz)
set(LIBZSTD_HASH SHA256=eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3
    CACHE STRING "zstd source hash")

sessiondep_build_external(libzstd
    CONFIGURE_COMMAND DEFAULT_CMAKE
      -DZSTD_BUILD_PROGRAMS=OFF -DZSTD_BUILD_TESTS=OFF -DZSTD_BUILD_STATIC=ON -DZSTD_BUILD_SHARED=OFF -DZSTD_BUILD_DICTBUILDER=OFF
    SOURCE_SUBDIR build/cmake
    BUILD_BYPRODUCTS
      ${DEPS_DESTDIR}/lib/libzstd.a
      ${DEPS_DESTDIR}/include/zstd.h
)

sessiondep_static_simple(libzstd)
