set(SIMDUTF_VERSION 9.2.0)
set(SIMDUTF_MIRROR https://github.com/simdutf/simdutf/archive/refs/tags)
set(SIMDUTF_SOURCE v${SIMDUTF_VERSION}.tar.gz)
set(SIMDUTF_HASH SHA512=3585ad36511ec7fc059fb9ddfea121dd41d7f464fcb376f9d4109e28abbd6e5ed82aa142bb57452a9917827e7e9cba64f132fc136adb14db396276b848fed2ab)

sessiondep_build_external(simdutf
    CONFIGURE_COMMAND DEFAULT_CMAKE
      -DSIMDUTF_TESTS=OFF -DSIMDUTF_TOOLS=OFF -DBUILD_SHARED_LIBS=OFF
    BUILD_BYPRODUCTS
      ${SESSIONDEPS_DESTDIR}/lib/libsimdutf.a
      ${SESSIONDEPS_DESTDIR}/include/simdutf.h
)

sessiondep_static_simple(simdutf)
