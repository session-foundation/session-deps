set(UTF8PROC_VERSION 2.11.0)
set(UTF8PROC_MIRROR https://github.com/JuliaStrings/utf8proc/archive/refs/tags)
set(UTF8PROC_SOURCE v${UTF8PROC_VERSION}.tar.gz)
set(UTF8PROC_HASH SHA512=bf9bfb20036e8b709449ee4a11592becf99e61f4c82d03519ab9de1a93ca47d6f8ed4b0bb471f7ca3ae06293275a391a9102ae810a9e07e914789d05ddbd25ab)

sessiondep_build_external(utf8proc
    CONFIGURE_COMMAND DEFAULT_CMAKE
      -DBUILD_SHARED_LIBS=OFF -DUTF8PROC_ENABLE_TESTING=OFF
    BUILD_BYPRODUCTS
      ${SESSIONDEPS_DESTDIR}/lib/libutf8proc.a
      ${SESSIONDEPS_DESTDIR}/include/utf8proc.h
)

sessiondep_static_simple(utf8proc)
