set(QRCODEGENCPP_VERSION 1.8.0)
set(QRCODEGENCPP_MIRROR https://github.com/nayuki/QR-Code-generator/archive/refs/tags)
set(QRCODEGENCPP_SOURCE v${QRCODEGENCPP_VERSION}.tar.gz)
set(QRCODEGENCPP_HASH SHA512=0cdf0873e71aed124fc7357da86fb26f23fd26432f94c9752fa5a044085b26e5aece2115134d0e50213ff24be7c55818e7dec31205a68751065bc82ab0c2c6ac)

# Upstream carries implementations in six languages and no CMake build at all -- just a Makefile
# per language that builds a demo.  Drop a CMakeLists into cpp/ and build that subdirectory.
sessiondep_build_external(qrcodegencpp
    PATCH_COMMAND ${CMAKE_COMMAND} -E copy
      ${CMAKE_CURRENT_LIST_DIR}/extra/qrcodegencpp-CMakeLists.txt <SOURCE_DIR>/cpp/CMakeLists.txt
    CONFIGURE_COMMAND DEFAULT_CMAKE
    SOURCE_SUBDIR cpp
    BUILD_BYPRODUCTS
      ${SESSIONDEPS_DESTDIR}/lib/libqrcodegencpp.a
      ${SESSIONDEPS_DESTDIR}/include/qrcodegen.hpp
)

sessiondep_static_simple(qrcodegencpp)
