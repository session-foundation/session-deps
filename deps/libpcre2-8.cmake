set(LIBPCRE2-8_VERSION 10.48)
set(LIBPCRE2-8_MIRROR https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${LIBPCRE2-8_VERSION})
set(LIBPCRE2-8_SOURCE pcre2-${LIBPCRE2-8_VERSION}.tar.bz2)
set(LIBPCRE2-8_HASH SHA512=b350b8bfc909f3ebf9dfe39c535f04cc4618997f0fa025d12b4d92aaaac3c15ae93b6def62ed220eabbe08df9277cda0b80de4eedb7ec7376daf7e6a78a868b8)

# The 16- and 32-bit libraries and the JIT are all opt-in upstream, so there is nothing to turn off
# here.  Leave the JIT alone: it requires writable-executable pages, which iOS does not allow.
sessiondep_build_external(libpcre2-8
    CONFIGURE_COMMAND ./configure ${sessiondeps_cross_host} --prefix=${SESSIONDEPS_DESTDIR}
    --enable-static --disable-shared --with-pic
    "CC=${sessiondeps_cc}" "CFLAGS=${sessiondeps_CFLAGS}" ${sessiondeps_cross_rc}
    # Naming the library target and the matching install targets keeps pcre2grep and pcre2test from
    # being built at all; the default `all` builds both and installs them into bin.
    BUILD_COMMAND ${sessiondeps_make} libpcre2-8.la
    INSTALL_COMMAND ${sessiondeps_make}
        install-libLTLIBRARIES install-includeHEADERS install-pkgconfigDATA
    BUILD_BYPRODUCTS
    ${SESSIONDEPS_DESTDIR}/lib/libpcre2-8.a
    ${SESSIONDEPS_DESTDIR}/include/pcre2.h
)

sessiondep_static_simple(libpcre2-8)

# Without this pcre2.h declares everything __declspec(dllimport) on Windows, so callers look for
# __imp_pcre2_* and find the plain symbols the static library actually carries.
target_compile_definitions(sessiondep_ext_libpcre2-8 INTERFACE PCRE2_STATIC)
