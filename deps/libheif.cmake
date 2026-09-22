set(LIBHEIF_VERSION 1.23.5)
set(LIBHEIF_MIRROR https://github.com/strukturag/libheif/releases/download/v${LIBHEIF_VERSION})
set(LIBHEIF_SOURCE libheif-${LIBHEIF_VERSION}.tar.gz)
set(LIBHEIF_HASH SHA512=481f94d7b1a88edfcaa8218c3f07df8ed17609a7fcb79a48f42bddcc7dfb7412f4d68299808300e0c81d4d171aec9b3281922adc39bb49d94fd5b73ffcb2eb1f)

session_dep(libde265 1.0)
session_dep(dav1d 1.0)

# libheif is the container layer for both HEIC and AVIF, so turning it off removes both regardless
# of which codecs are available.
#
# Every codec backend is listed, including the ones being turned off, because each defaults to
# whatever cmake finds and would otherwise vary with what else has been installed into the destdir.
#
# ENABLE_PLUGIN_LOADING must be off for a static build: with it on, libheif resolves its codec
# backends as dlopen()ed shared objects at runtime, which a statically linked consumer never finds.
sessiondep_build_external(libheif
    CONFIGURE_COMMAND DEFAULT_CMAKE
      -DBUILD_SHARED_LIBS=OFF
      -DBUILD_TESTING=OFF
      -DENABLE_PLUGIN_LOADING=OFF
      -DWITH_EXAMPLES=OFF
      -DWITH_GDK_PIXBUF=OFF
      -DWITH_LIBDE265=ON
      -DWITH_DAV1D=ON
      -DWITH_AOM_DECODER=OFF
      -DWITH_AOM_ENCODER=OFF
      -DWITH_X265=OFF
      -DWITH_X264=OFF
      -DWITH_SvtEnc=OFF
      -DWITH_RAV1E=OFF
      -DWITH_KVAZAAR=OFF
      -DWITH_UVG266=OFF
      -DWITH_VVDEC=OFF
      -DWITH_VVENC=OFF
      -DWITH_OpenH264_DECODER=OFF
      -DWITH_JPEG_DECODER=OFF
      -DWITH_JPEG_ENCODER=OFF
      -DWITH_OpenJPEG_DECODER=OFF
      -DWITH_OpenJPEG_ENCODER=OFF
      -DWITH_OPENJPH_ENCODER=OFF
      -DWITH_FFMPEG_DECODER=OFF
      -DWITH_UNCOMPRESSED_CODEC=OFF
      -DWITH_LIBSHARPYUV=OFF
    DEPENDS sessiondep::libde265 sessiondep::dav1d
    BUILD_BYPRODUCTS
      ${SESSIONDEPS_DESTDIR}/lib/libheif.a
      ${SESSIONDEPS_DESTDIR}/include/libheif/heif.h
)

sessiondep_static_simple(libheif sessiondep::libde265 sessiondep::dav1d)
set_target_properties(sessiondep_ext_libheif PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES CXX)

# A caller decoding untrusted input should set heif_context_set_security_limits() rather than
# inheriting the global defaults: max_number_of_tiles, max_items and max_total_memory all bound
# allocations that the file itself declares.
