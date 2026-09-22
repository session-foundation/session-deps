set(LIBWEBP_VERSION 1.6.0)
set(LIBWEBP_MIRROR https://github.com/webmproject/libwebp/archive/refs/tags)
set(LIBWEBP_SOURCE v${LIBWEBP_VERSION}.tar.gz)
set(LIBWEBP_HASH SHA512=298e0ad4c09392213baf5abb69d330c6203b618800073fe2df91d01d35034197c5d3e29a74573b06971473c52c74514f0e6e0f6c8162f923e2dd15cb1a692aef)

# libvips insists on all three of libwebp, libwebpmux and libwebpdemux -- it splits animation and
# metadata handling across mux/demux -- so the extras are built rather than left off.  Only the
# command line tools are dropped.
sessiondep_build_external(libwebp
    CONFIGURE_COMMAND DEFAULT_CMAKE
      -DBUILD_SHARED_LIBS=OFF
      -DWEBP_BUILD_LIBWEBPMUX=ON
      -DWEBP_BUILD_ANIM_UTILS=OFF
      -DWEBP_BUILD_CWEBP=OFF
      -DWEBP_BUILD_DWEBP=OFF
      -DWEBP_BUILD_GIF2WEBP=OFF
      -DWEBP_BUILD_IMG2WEBP=OFF
      -DWEBP_BUILD_VWEBP=OFF
      -DWEBP_BUILD_WEBPINFO=OFF
      -DWEBP_BUILD_WEBPMUX=OFF
      -DWEBP_BUILD_EXTRAS=OFF
    BUILD_BYPRODUCTS
      ${SESSIONDEPS_DESTDIR}/lib/libwebp.a
      ${SESSIONDEPS_DESTDIR}/lib/libwebpdemux.a
      ${SESSIONDEPS_DESTDIR}/lib/libwebpmux.a
      ${SESSIONDEPS_DESTDIR}/lib/libsharpyuv.a
      ${SESSIONDEPS_DESTDIR}/include/webp/encode.h
)

# sharpyuv holds the RGB->YUV conversion the encoder calls into, so it has to follow libwebp on the
# link line; mux and demux likewise reference the core.  Its gamma tables pull in pow()/log10(), so
# libm comes last of all.
set(libwebp_libm)
if(NOT WIN32)
    set(libwebp_libm m)
endif()
sessiondep_static_target(sessiondep_sharpyuv libwebp libsharpyuv.a ${libwebp_libm})
sessiondep_static_target(sessiondep_ext_libwebp libwebp libwebp.a sessiondep_sharpyuv)
sessiondep_static_target(sessiondep_ext_libwebpdemux libwebp libwebpdemux.a sessiondep_ext_libwebp)
sessiondep_static_target(sessiondep_ext_libwebpmux libwebp libwebpmux.a sessiondep_ext_libwebp)
