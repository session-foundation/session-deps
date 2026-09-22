set(GNUTLS_VERSION 3.8.13)
string(REGEX REPLACE "^([0-9]+\\.[0-9]+)\\.[0-9]+$" "\\1" gnutls_version_nopatch "${GNUTLS_VERSION}")
set(GNUTLS_MIRROR https://www.gnupg.org/ftp/gcrypt/gnutls/v${gnutls_version_nopatch})
set(GNUTLS_SOURCE gnutls-${GNUTLS_VERSION}.tar.xz)
set(GNUTLS_HASH SHA512=71bf189a836fd18d58b9e995d4bfcecdb0aae6129dfd44247b98422b2f127dd868f9905d28fad2ca05afd919a0e6b3c8eebb6b95804067d3a8dab31ebdc72453)


session_dep(nettle 3.8 WITH hogweed)
session_dep(libidn2 2)
session_dep(libtasn1 4.16)

# The Android NDK defines `timezone_t` but not a number of related types and GnuTLS assumes if `timezone_t` is defined then all the others will be defined as well (resulting in build errors), so we need to patch GnuTLS to think `HAVE_TIMEZONE_T` is not defined and rename it's internal `timezone_t` so there isn't a name collision
set(gnutls_patch_commands "")
if(ANDROID)
    set(gnutls_patch_commands PATCHES gnutls-android-timezone-t.patch)
endif()

sessiondep_build_external(gnutls
    ${gnutls_patch_commands}
    CONFIGURE_COMMAND ./configure ${sessiondeps_cross_host} --disable-shared --prefix=${SESSIONDEPS_DESTDIR} --with-pic
        --without-p11-kit --disable-libdane --disable-cxx --without-tpm --without-tpm2 --disable-doc
        --without-zlib --without-brotli --without-zstd --without-libintl-prefix --disable-tests
        --disable-valgrind-tests --disable-full-test-suite --disable-tools --disable-nls
        "PKG_CONFIG_LIBDIR=${SESSIONDEPS_DESTDIR}/lib/pkgconfig" "PKG_CONFIG=pkg-config"
        "CPPFLAGS=-I${SESSIONDEPS_DESTDIR}/include" "LDFLAGS=${sessiondeps_ldflags}"
        "CC=${sessiondeps_cc}" "CXX=${sessiondeps_cxx}"
        "CFLAGS=${sessiondeps_CFLAGS}"
        "CXXFLAGS=${sessiondeps_CXXFLAGS}"
        ${sessiondeps_cross_rc}
    DEPENDS sessiondep::nettle sessiondep::hogweed sessiondep::libidn2 sessiondep::libtasn1
    BUILD_BYPRODUCTS
    ${SESSIONDEPS_DESTDIR}/lib/libgnutls.a
    ${SESSIONDEPS_DESTDIR}/include/gnutls/gnutls.h
)
# hogweed before nettle: cmake orders the final link from the target graph regardless, but
# sessiondep_link_flags() emits these in the order given, and a static link line needs hogweed's
# archive ahead of the nettle archive that satisfies it (hogweed's RSA code calls
# nettle_cnd_memcpy, for one).  Recipes that hand configure a link line for gnutls depend on this.
sessiondep_static_simple(gnutls
    sessiondep::hogweed sessiondep::nettle sessiondep::libidn2 sessiondep::libtasn1)

if(ANDROID AND SESSIONDEPS_LTO AND CMAKE_SYSTEM_VERSION VERSION_LESS 29)
    # Built with LTO this archive holds bitcode, so whoever links it is what compiles it -- and a
    # link without -flto tells the driver nothing is being compiled, so it forwards none of the
    # -plugin-opt settings describing the target.  lld runs LTO anyway, having found the bitcode,
    # and uses its own defaults: for gnutls's thread-locals that means real ELF TLS, which bionic
    # has no __tls_get_addr for below API 29.  Nothing else here has thread-locals, so gnutls is
    # where the requirement is real enough to hand to whoever links it.
    set_property(TARGET sessiondep_ext_gnutls APPEND PROPERTY INTERFACE_LINK_OPTIONS -flto)
endif()


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
