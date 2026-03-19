set(LIBZSTD_VERSION 1.5.7)
set(LIBZSTD_MIRROR https://github.com/facebook/zstd/releases/download/v${LIBZSTD_VERSION})
set(LIBZSTD_SOURCE zstd-${LIBZSTD_VERSION}.tar.gz)
set(LIBZSTD_HASH SHA256=eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3)

sessiondep_build_external(libzstd
    CONFIGURE_COMMAND DEFAULT_CMAKE
      -DZSTD_BUILD_PROGRAMS=OFF -DZSTD_BUILD_TESTS=OFF -DZSTD_BUILD_STATIC=ON -DZSTD_BUILD_SHARED=OFF -DZSTD_BUILD_DICTBUILDER=OFF
    SOURCE_SUBDIR build/cmake
    BUILD_BYPRODUCTS
      ${SESSIONDEPS_DESTDIR}/lib/libzstd.a
      ${SESSIONDEPS_DESTDIR}/include/zstd.h
)

sessiondep_static_simple(libzstd)
