set(LIBUTF8PROC_VERSION 2.11.3)
set(LIBUTF8PROC_MIRROR https://github.com/JuliaStrings/utf8proc/archive/refs/tags)
set(LIBUTF8PROC_SOURCE v${LIBUTF8PROC_VERSION}.tar.gz)
set(LIBUTF8PROC_HASH SHA512=148701fce506d076f03497b6d085f1993eff743debad4a2f6d3cbac91e19a5c22d9938245bdb460c1b22b51842c7416c42124db7416c684ee63d622490baac0e)

sessiondep_build_external(libutf8proc
    CONFIGURE_COMMAND DEFAULT_CMAKE
      -DBUILD_SHARED_LIBS=OFF -DUTF8PROC_ENABLE_TESTING=OFF
    BUILD_BYPRODUCTS
      ${SESSIONDEPS_DESTDIR}/lib/libutf8proc.a
      ${SESSIONDEPS_DESTDIR}/include/utf8proc.h
)

sessiondep_static_simple(libutf8proc)
