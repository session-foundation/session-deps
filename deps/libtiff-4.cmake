set(LIBTIFF-4_VERSION 4.7.2)
set(LIBTIFF-4_MIRROR https://download.osgeo.org/libtiff)
set(LIBTIFF-4_SOURCE tiff-${LIBTIFF-4_VERSION}.tar.gz)
set(LIBTIFF-4_HASH SHA512=bad66954a7e7e158c6dcbfc0e2d0032b8f3e2a354b6d0fdbb8038a7963e36c5b8a433dd4ee81c6c4dabfb50094152d440aa1f32b5299098c9ae29e55de2e41fc)

session_dep(zlib 1.2)
session_dep(libjpeg 2)

# Every codec option defaults to whatever cmake happens to find, so each one is set explicitly:
# otherwise the set of TIFF compressions this supports would depend on which other recipes a given
# build tree had already populated the destdir with.  Deflate and JPEG cover what anyone actually
# sends; the rest are decoders we would be carrying for no reason.
sessiondep_build_external(libtiff-4
    CONFIGURE_COMMAND DEFAULT_CMAKE
      -DBUILD_SHARED_LIBS=OFF
      -Dtiff-static=ON
      -Dtiff-tools=OFF
      -Dtiff-tests=OFF
      -Dtiff-contrib=OFF
      -Dtiff-docs=OFF
      -Dtiff-deprecated=OFF
      -Dzlib=ON
      -Djpeg=ON
      -Dwebp=OFF
      -Dzstd=OFF
      -Dlzma=OFF
      -Djbig=OFF
      -Dlerc=OFF
      -Djpeg12=OFF
      # Not a codec but detected the same way: libdeflate is an optional faster Deflate backend,
      # and its default is whether cmake found one.  On a native build our pkg-config path also
      # sees the system's, so leaving this alone links libtiff.a against a system libdeflate that
      # is not in the destdir -- the final link then fails on libdeflate_* with no clue why.
      -Dlibdeflate=OFF
      -Dtiff-cxx=OFF
      -Dtiff-opengl=OFF
    DEPENDS sessiondep::zlib sessiondep::libjpeg
    BUILD_BYPRODUCTS
      ${SESSIONDEPS_DESTDIR}/lib/libtiff.a
      ${SESSIONDEPS_DESTDIR}/include/tiffio.h
)

sessiondep_static_target(sessiondep_ext_libtiff-4 libtiff-4 libtiff.a
    sessiondep::libjpeg sessiondep::zlib)
