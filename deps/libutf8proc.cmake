set(LIBUTF8PROC_VERSION 2.11.3)
set(LIBUTF8PROC_MIRROR https://github.com/JuliaStrings/utf8proc/archive/refs/tags/v${LIBUTF8PROC_VERSION})
set(LIBUTF8PROC_SOURCE utf8proc-${LIBUTF8PROC_VERSION}.tar.gz)
set(LIBUTF8PROC_HASH SHA512=148701fce506d076f03497b6d085f1993eff743debad4a2f6d3cbac91e19a5c22d9938245bdb460c1b22b51842c7416c42124db7416c684ee63d622490baac0e)

sessiondep_build_external(libutf8proc
    CONFIGURE_COMMAND DEFAULT_CMAKE
      -DBUILD_SHARED_LIBS=OFF -DUTF8PROC_ENABLE_TESTING=OFF
    BUILD_BYPRODUCTS
      ${SESSIONDEPS_DESTDIR}/lib/libutf8proc.a
      ${SESSIONDEPS_DESTDIR}/include/utf8proc.h
)

sessiondep_static_simple(libutf8proc)
# Without this its header declares everything __declspec(dllimport) on Windows, so callers look for
# __imp_utf8proc_* and find the plain symbols the static library actually carries.
target_compile_definitions(sessiondep_ext_libutf8proc INTERFACE UTF8PROC_STATIC)
