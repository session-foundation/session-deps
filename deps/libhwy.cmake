set(LIBHWY_VERSION 1.4.0)
set(LIBHWY_MIRROR https://github.com/google/highway/archive/refs/tags)
set(LIBHWY_SOURCE ${LIBHWY_VERSION}.tar.gz)
set(LIBHWY_HASH SHA512=819422857d6a74e3a936c402698e078db5b7b88fb43767e62429ec7bd954fe93b017e75029a4df4a1a97ef3a2486107eef5247da751eb487640dea409f3f2fa2)

# Not a format: this is the SIMD backend libvips uses for resize and reduce, which is the hot path
# for thumbnailing.  Named libhwy because that is the pkg-config module libvips looks for.
sessiondep_build_external(libhwy
    CONFIGURE_COMMAND DEFAULT_CMAKE
      -DBUILD_SHARED_LIBS=OFF
      -DHWY_ENABLE_TESTS=OFF
      -DHWY_ENABLE_EXAMPLES=OFF
      -DHWY_ENABLE_CONTRIB=OFF
      -DBUILD_TESTING=OFF
    BUILD_BYPRODUCTS
      ${SESSIONDEPS_DESTDIR}/lib/libhwy.a
      ${SESSIONDEPS_DESTDIR}/include/hwy/highway.h
)

sessiondep_static_simple(libhwy)
