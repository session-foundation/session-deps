set(LIBCURL_VERSION 8.22.0)
set(LIBCURL_MIRROR https://curl.se/download https://curl.askapache.com)
set(LIBCURL_SOURCE curl-${LIBCURL_VERSION}.tar.xz)
set(LIBCURL_HASH SHA512=d6badf794e7a72760a353db73adb8b671804ce41619b401265b22dc8f6770ebeaa5adb3c4d1312722082c56013612a382884e025cca49397a8ab47577dd659f7)


session_dep(libssl 3 WITH libcrypto)
session_dep(zlib 1.2)

set(curl_extra_libs)
if(NOT WIN32 AND NOT APPLE)
    # configure's link tests pull in libcrypto, which needs pthreads.
    set(curl_extra_libs "LIBS=-pthread")
endif()

# Everything but HTTP(S) is turned off: this exists to make requests at an API, so the other
# protocol backends are just attack surface.  Note that the disabled features that libcurl still
# exposes entry points for (mime in particular, which cpr references unconditionally) keep working
# as stubs that return CURLE_NOT_BUILT_IN rather than failing to link.
sessiondep_build_external(libcurl
    DEPENDS sessiondep::libssl sessiondep::zlib
    CONFIGURE_COMMAND ./configure ${sessiondeps_cross_host} --prefix=${SESSIONDEPS_DESTDIR}
        --disable-shared --enable-static --with-pic
        --with-openssl=${SESSIONDEPS_DESTDIR} --with-zlib=${SESSIONDEPS_DESTDIR}
        --enable-http --enable-http-auth --enable-ipv6 --enable-doh --enable-dateparse
        --disable-ares --disable-dict --disable-ftp --disable-gopher --disable-imap
        --disable-ldap --disable-ldaps --disable-mqtt --disable-pop3 --disable-rtsp
        --disable-smb --disable-smtp --disable-telnet --disable-tftp --disable-websockets
        --disable-cookies --disable-libcurl-option --disable-manual --disable-mime
        --disable-netrc --disable-progress-meter --disable-sspi --disable-threaded-resolver
        --disable-unix-sockets --disable-verbose --disable-versioned-symbols
        --without-brotli --without-libidn2 --without-libpsl --without-zstd
        --without-nghttp2 --without-nghttp3 --without-ngtcp2 --without-quiche
        --without-fish-functions-dir --without-zsh-functions-dir
        "PKG_CONFIG_LIBDIR=${SESSIONDEPS_DESTDIR}/lib/pkgconfig" "PKG_CONFIG=pkg-config"
        "CC=${sessiondeps_cc}" "CFLAGS=${sessiondeps_CFLAGS}"
        "LDFLAGS=-L${SESSIONDEPS_DESTDIR}/lib${sessiondeps_apple_ldflags_arch}"
        ${curl_extra_libs} ${sessiondeps_cross_rc}
    # Only lib/ and include/: the top-level targets additionally build the curl command line tool.
    BUILD_COMMAND ${sessiondeps_make} -C lib
    INSTALL_COMMAND ${sessiondeps_make} -C lib install
        COMMAND ${sessiondeps_make} -C include install
    BUILD_BYPRODUCTS
    ${SESSIONDEPS_DESTDIR}/lib/libcurl.a
    ${SESSIONDEPS_DESTDIR}/include/curl/curl.h
)

set(libcurl_extra_deps)
if(WIN32)
    set(libcurl_extra_deps ws2_32 crypt32)
elseif(APPLE)
    set(libcurl_extra_deps "-framework Security" "-framework CoreFoundation"
        "-framework SystemConfiguration")
endif()

sessiondep_static_simple(libcurl sessiondep::libssl sessiondep::zlib ${libcurl_extra_deps})
target_compile_definitions(sessiondep_ext_libcurl INTERFACE CURL_STATICLIB)
