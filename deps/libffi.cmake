set(LIBFFI_VERSION 3.8.0)
set(LIBFFI_MIRROR https://github.com/libffi/libffi/releases/download/v${LIBFFI_VERSION})
set(LIBFFI_SOURCE libffi-${LIBFFI_VERSION}.tar.gz)
set(LIBFFI_HASH SHA512=a259d50f40b5dcde9cb6227bd105761e667290f107553b204a5a6cfdfbf2e6b022ed04be2ea4596da42961d11396125425def3cb67e2844a9eba90b6750c8c39)

# --disable-multi-os-directory: otherwise libffi asks gcc for --print-multi-os-directory and
# installs into lib64 on a multilib toolchain, which is not where sessiondep_static_target() looks.
sessiondep_build_external(libffi
    CONFIGURE_COMMAND ./configure ${sessiondeps_cross_host} --prefix=${SESSIONDEPS_DESTDIR}
    --enable-static --disable-shared --with-pic --disable-docs --disable-multi-os-directory
    "CC=${sessiondeps_cc}" "CFLAGS=${sessiondeps_CFLAGS}" ${sessiondeps_cross_rc}
)

sessiondep_static_simple(libffi)
