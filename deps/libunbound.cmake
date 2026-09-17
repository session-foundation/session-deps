set(LIBUNBOUND_VERSION 1.26.1)
set(LIBUNBOUND_MIRROR https://nlnetlabs.nl/downloads/unbound)
set(LIBUNBOUND_SOURCE unbound-${LIBUNBOUND_VERSION}.tar.gz)
set(LIBUNBOUND_HASH SHA256=35a6dc0e425a9282c3426d9a3043144011bf0534aed4b73ab62c52aee0af1503)


session_dep(nettle 3.6 WITH hogweed)
session_dep(expat 2)

sessiondep_build_external(libunbound
    PATCH_COMMAND patch -p1 -i ${CMAKE_CURRENT_LIST_DIR}/patches/unbound-nettle4.patch
    COMMAND patch -p1 -i ${CMAKE_CURRENT_LIST_DIR}/patches/unbound-macos-getentropy.patch
    COMMAND patch -p1 -i ${CMAKE_CURRENT_LIST_DIR}/patches/unbound-windows-without-ssl.patch
    CONFIGURE_COMMAND ./configure ${sessiondeps_cross_host} ${sessiondeps_cross_rc} --prefix=${SESSIONDEPS_DESTDIR}
    --with-libunbound-only --disable-shared --enable-static
    --with-pic --$<IF:$<BOOL:${SESSIONDEPS_LTO}>,enable,disable>-flto
    --with-nettle=${SESSIONDEPS_DESTDIR} --with-libexpat=${SESSIONDEPS_DESTDIR}
    --without-ssl
    "CC=${sessiondeps_cc}" "CFLAGS=${sessiondeps_CFLAGS}"
    "LDFLAGS=${sessiondeps_ldflags}"
    DEPENDS sessiondep::nettle sessiondep::hogweed sessiondep::expat
)

set(extra_deps)
if(WIN32)
    set(extra_deps ws2_32 crypt32 iphlpapi)
endif()
sessiondep_static_simple(libunbound sessiondep::nettle sessiondep::hogweed ${extra_deps})
