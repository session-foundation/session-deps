set(LIBEXIF_VERSION 0.6.26)
set(LIBEXIF_MIRROR https://github.com/libexif/libexif/releases/download/v${LIBEXIF_VERSION})
set(LIBEXIF_SOURCE libexif-${LIBEXIF_VERSION}.tar.bz2)
set(LIBEXIF_HASH SHA512=e99d2de0566284d98547915d6661effd18a51fe1687d923e57bd2250551d3ee73587f7c8386d926e7ff21df06887bedae3e10b4441bf544f04f559c381e258fe)

# --disable-nls keeps libexif off gettext, which matters on the non-glibc targets where an intl
# provider has to be supplied by hand; libvips only wants the tag values, never the translated tag
# descriptions.
sessiondep_build_external(libexif
    CONFIGURE_COMMAND ./configure ${sessiondeps_cross_host} --prefix=${SESSIONDEPS_DESTDIR}
    --enable-static --disable-shared --with-pic --disable-nls --disable-docs
    "CC=${sessiondeps_cc}" "CFLAGS=${sessiondeps_CFLAGS}" ${sessiondeps_cross_rc}
    BUILD_BYPRODUCTS
      ${SESSIONDEPS_DESTDIR}/lib/libexif.a
      ${SESSIONDEPS_DESTDIR}/include/libexif/exif-data.h
)

sessiondep_static_simple(libexif)
