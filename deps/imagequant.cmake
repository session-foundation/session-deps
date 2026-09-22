set(IMAGEQUANT_VERSION 2.4.1)
set(IMAGEQUANT_MIRROR https://github.com/lovell/libimagequant/archive/refs/tags)
set(IMAGEQUANT_SOURCE v${IMAGEQUANT_VERSION}.tar.gz)
set(IMAGEQUANT_HASH SHA512=3972eb26c603c46eff40f60992619a73f392ffcaeddf62b145a757084f33d0fd841c1711677405c17f126e888d2c6d901674f8ad746fb3d8b9f416ea23f32518)

# This is lovell/libimagequant (BSD-2-Clause), a fork of ImageOptim/libimagequant 2.4.1 that
# backports liq_image_quantize() -- ImageOptim's 2.4.1 has only the older liq_quantize_image(),
# which libvips does not call -- and replaces the hand-rolled Makefile, which has no install target
# and generates no pkg-config file, with a meson build.
sessiondep_build_external(imagequant
    CONFIGURE_COMMAND DEFAULT_MESON
    BUILD_BYPRODUCTS
        ${SESSIONDEPS_DESTDIR}/lib/libimagequant.a
        ${SESSIONDEPS_DESTDIR}/include/libimagequant.h
)

set(imagequant_libm)
if(NOT WIN32)
    set(imagequant_libm m)
endif()
sessiondep_static_target(sessiondep_ext_imagequant imagequant libimagequant.a ${imagequant_libm})
