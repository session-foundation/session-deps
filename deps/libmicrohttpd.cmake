set(LIBMICROHTTPD_VERSION 1.0.10)
set(LIBMICROHTTPD_MIRROR https://ftp.gnu.org/gnu/libmicrohttpd)
set(LIBMICROHTTPD_SOURCE libmicrohttpd-${LIBMICROHTTPD_VERSION}.tar.gz)
set(LIBMICROHTTPD_HASH SHA512=b67458fad556fa0b73edf728efbc30a2304c544d98409b9efbdda5ebfb6668b31c1c96620eac33994ade1255f8170cd4628f0a61b57a9cef255d4980110b362f)


session_dep(gnutls 3.6)

# configure link-tests gnutls with a bare -lgnutls, which a static gnutls cannot satisfy on its own
# (its nettle/hogweed/gmp/tasn1/idn2 halves are separate archives), so hand it the link line cmake
# already resolved for sessiondep::gnutls -- correct whether gnutls was built here or found on the
# system.  Same approach as libcurl.cmake.
sessiondep_link_flags(mhd_tls_libs sessiondep::gnutls)
list(JOIN mhd_tls_libs " " mhd_tls_libs)

# Only the core HTTP(S) server is built: the authentication, form post-processing, cookie and
# HTTP-upgrade layers are optional features that nothing here uses, and each is request-parsing
# surface that has had its own security fixes.
#
# Unlike most recipes this one is routinely built statically on systems where gnutls is *not*: no
# current Debian/Ubuntu release ships a new enough libmicrohttpd, but all of them have gnutls.  So
# pkg-config gets the static destdir prepended (PKG_CONFIG_PATH) rather than substituted
# (PKG_CONFIG_LIBDIR), letting configure find whichever gnutls sessiondep::gnutls resolved to.
sessiondep_build_external(libmicrohttpd
    CONFIGURE_COMMAND ./configure ${sessiondeps_cross_host} --prefix=${SESSIONDEPS_DESTDIR} --with-pic
    --disable-shared --enable-static
    --enable-https --with-gnutls
    --disable-doc --disable-examples --disable-curl
    --disable-bauth --disable-dauth --disable-postprocessor --disable-httpupgrade --disable-cookie
    "PKG_CONFIG_PATH=${SESSIONDEPS_DESTDIR}/lib/pkgconfig" "PKG_CONFIG=pkg-config"
    "CPPFLAGS=-I${SESSIONDEPS_DESTDIR}/include" "LDFLAGS=${sessiondeps_ldflags}"
    "LIBS=${mhd_tls_libs}"
    "CC=${sessiondeps_cc}" "CXX=${sessiondeps_cxx}"
    "CFLAGS=${sessiondeps_CFLAGS}" "CXXFLAGS=${sessiondeps_CXXFLAGS}"
    ${sessiondeps_cross_rc}
    DEPENDS sessiondep::gnutls
)

sessiondep_static_simple(libmicrohttpd sessiondep::gnutls)
