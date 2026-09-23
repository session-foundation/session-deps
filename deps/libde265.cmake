set(LIBDE265_VERSION 1.1.3)
set(LIBDE265_MIRROR https://github.com/strukturag/libde265/releases/download/v${LIBDE265_VERSION})
set(LIBDE265_SOURCE libde265-${LIBDE265_VERSION}.tar.gz)
set(LIBDE265_HASH SHA512=2068396658d43f0b1a52f96d6ffc6836271cc39e0fad89ce21980445be04da2792e2191bfc49130b2c6f640c7592010594dce1d5928c9eaa7e3290cc3e4f81d8)

# ENABLE_SDL is off so that the example player does not pull in a system SDL.
#
# ENABLE_DECODER gates only add_subdirectory(dec265), the command line tool; the library itself is
# added unconditionally above it, so turning this off does not remove decoding.
sessiondep_build_external(libde265
    CONFIGURE_COMMAND DEFAULT_CMAKE
      -DBUILD_SHARED_LIBS=OFF
      -DENABLE_DECODER=OFF
      -DENABLE_ENCODER=OFF
      -DENABLE_SDL=OFF
      -DENABLE_SHERLOCK265=OFF
      -DENABLE_INTERNAL_DEVELOPMENT_TOOLS=OFF
      -DBUILD_TESTING=OFF
    BUILD_BYPRODUCTS
      ${SESSIONDEPS_DESTDIR}/lib/libde265.a
      ${SESSIONDEPS_DESTDIR}/include/libde265/de265.h
)

# The decoder is C++ and threaded, so consumers need the C++ runtime and pthreads behind it.
set(libde265_extra)
if(NOT WIN32)
    find_package(Threads REQUIRED)
    set(libde265_extra Threads::Threads)
endif()
sessiondep_static_simple(libde265 ${libde265_extra})
set_target_properties(sessiondep_ext_libde265 PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES CXX)

# de265.h declares the API __declspec(dllimport) on Windows unless told the library is static.
target_compile_definitions(sessiondep_ext_libde265 INTERFACE LIBDE265_STATIC_BUILD)
