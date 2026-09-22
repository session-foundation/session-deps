set(LCMS2_VERSION 2.19.1)
# The tag is the version with a bare "lcms" prefix -- lcms2.19.1 for 2.19.1 -- while the tarball
# inside spells the project name out in full.
set(LCMS2_MIRROR https://github.com/mm2/Little-CMS/releases/download/lcms${LCMS2_VERSION})
set(LCMS2_SOURCE lcms2-${LCMS2_VERSION}.tar.gz)
set(LCMS2_HASH SHA512=0c476a0c2ed7a4eabd149767c6e6fb372090dfd582b93ae738c9bd3dda94a2fc1c0b7da4b400422a3bc3650c9b98c9956ba9181b29f9b7c57f08763e20b7c8ac)

# fastfloat and threaded are optional plugins with their own licence terms; they are set here rather
# than left to a default that a version bump could change.
#
# jpeg and tiff serve the command line utilities, not the library, and would otherwise be picked up
# from whatever the destdir happens to contain by the time this builds.
sessiondep_build_external(lcms2
    CONFIGURE_COMMAND DEFAULT_MESON
      -Dtests=disabled
      -Dutils=false
      -Djpeg=disabled
      -Dtiff=disabled
      -Dfastfloat=false
      -Dthreaded=false
    BUILD_BYPRODUCTS
      ${SESSIONDEPS_DESTDIR}/lib/liblcms2.a
      ${SESSIONDEPS_DESTDIR}/include/lcms2.h
)

set(lcms2_libm)
if(NOT WIN32)
    set(lcms2_libm m)
endif()
sessiondep_static_target(sessiondep_ext_lcms2 lcms2 liblcms2.a ${lcms2_libm})
