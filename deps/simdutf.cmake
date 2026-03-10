set(SIMDUTF_VERSION 8.0.0 CACHE STRING "simdutf version")
set(SIMDUTF_MIRROR ${LOCAL_MIRROR} https://github.com/simdutf/simdutf/archive/refs/tags
    CACHE STRING "simdutf mirror(s)")
set(SIMDUTF_SOURCE v${SIMDUTF_VERSION}.tar.gz)
set(SIMDUTF_HASH SHA512=ee30ac7b7b96dfef2ced3938b1cc8e10cd5ec5b3d35ac9679f30fbb7811bf3f930a31f5b4cf0b4002f27eba84d2e27e7c7bd910d96aa04485588188ad910361d
    CACHE STRING "simdutf source hash")

sessiondep_build_external(simdutf
    CONFIGURE_COMMAND DEFAULT_CMAKE
      -DSIMDUTF_TESTS=OFF -DSIMDUTF_TOOLS=OFF -DBUILD_SHARED_LIBS=OFF
    BUILD_BYPRODUCTS
      ${DEPS_DESTDIR}/lib/libsimdutf.a
      ${DEPS_DESTDIR}/include/simdutf.h
)

sessiondep_static_simple(simdutf)
