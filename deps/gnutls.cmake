set(GNUTLS_VERSION 3.8.10 CACHE STRING "gnutls version")
string(REGEX REPLACE "^([0-9]+\\.[0-9]+)\\.[0-9]+$" "\\1" gnutls_version_nopatch "${GNUTLS_VERSION}")
set(GNUTLS_MIRROR https://www.gnupg.org/ftp/gcrypt/gnutls/v${gnutls_version_nopatch}
    CACHE STRING "gnutls mirror(s)")
set(GNUTLS_SOURCE gnutls-${GNUTLS_VERSION}.tar.xz)
set(GNUTLS_HASH SHA512=d453bd4527af95cb3905ce8753ceafd969e3f442ad1d148544a233ebf13285b999930553a805a0511293cc25390bb6a040260df5544a7c55019640f920ad3d92
    CACHE STRING "gnutls source hash")


session_dep(nettle 3.8 WITH hogweed)
session_dep(libidn2 2)
session_dep(libtasn1 4.16)

# The Android NDK defines `timezone_t` but not a number of related types and GnuTLS assumes if `timezone_t` is defined then all the others will be defined as well (resulting in build errors), so we need to patch GnuTLS to think `HAVE_TIMEZONE_T` is not defined and rename it's internal `timezone_t` so there isn't a name collision
set(gnutls_patch_commands "")
if(ANDROID)
    set(gnutls_patch_commands PATCH_COMMAND patch -p0 -i ${CMAKE_CURRENT_LIST_DIR}/patches/gnutls-android-timezone-t.patch)
endif()

sessiondep_build_external(gnutls
    ${gnutls_patch_commands}
    CONFIGURE_COMMAND ./configure ${sessiondeps_sane_cross_host} --disable-shared --prefix=${SESSIONDEPS_DESTDIR} --with-pic
        --without-p11-kit --disable-libdane --disable-cxx --without-tpm --without-tpm2 --disable-doc
        --without-zlib --without-brotli --without-zstd --without-libintl-prefix --disable-tests
        --disable-valgrind-tests --disable-full-test-suite --disable-tools
        "PKG_CONFIG_LIBDIR=${SESSIONDEPS_DESTDIR}/lib/pkgconfig" "PKG_CONFIG=pkg-config"
        "CPPFLAGS=-I${SESSIONDEPS_DESTDIR}/include" "LDFLAGS=-L${SESSIONDEPS_DESTDIR}/lib${sessiondeps_apple_ldflags_arch}"
        "CC=${sessiondeps_cc}" "CXX=${sessiondeps_cxx}"
        "CFLAGS=${sessiondeps_CFLAGS}${sessiondeps_apple_cflags_arch}"
        "CXXFLAGS=${sessiondeps_CXXFLAGS}${sessiondeps_apple_cxxflags_arch}"
        ${sessiondeps_cross_rc}
    DEPENDS sessiondep::nettle sessiondep::hogweed sessiondep::libidn2 sessiondep::libtasn1
    BUILD_BYPRODUCTS
    ${SESSIONDEPS_DESTDIR}/lib/libgnutls.a
    ${SESSIONDEPS_DESTDIR}/include/gnutls/gnutls.h
)
sessiondep_static_simple(gnutls
    sessiondep::nettle sessiondep::hogweed sessiondep::libidn2 sessiondep::libtasn1)

sessiondep_override_find_package(
    GnuTLS
    ${GNUTLS_VERSION}
    ${SESSIONDEPS_DESTDIR}/include
    ${SESSIONDEPS_DESTDIR}/lib/libgnutls.a
    ${SESSIONDEPS_DESTDIR}/lib/libgnutls.a)

if(WIN32)
    target_link_libraries(sessiondep_ext_gnutls INTERFACE ws2_32 ncrypt crypt32 iphlpapi)
    # See GNUTLS gitlab issue 1117:
    target_compile_definitions(sessiondep_ext_gnutls INTERFACE GNUTLS_INTERNAL_BUILD)
endif()
