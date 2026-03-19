set(LIBUNBOUND_VERSION 1.24.2)
set(LIBUNBOUND_MIRROR https://nlnetlabs.nl/downloads/unbound)
set(LIBUNBOUND_SOURCE unbound-${LIBUNBOUND_VERSION}.tar.gz)
set(LIBUNBOUND_HASH SHA256=44e7b53e008a6dcaec03032769a212b46ab5c23c105284aa05a4f3af78e59cdb)


if(WIN32)
    set(unbound_patch
        PATCH_COMMAND patch -p0 -i ${CMAKE_CURRENT_LIST_DIR}/patches/unbound-delete-crash-fix.patch)
endif()

session_dep(nettle 3.6 WITH hogweed)
session_dep(expat 2)

sessiondep_build_external(libunbound
    ${unbound_patch}
    CONFIGURE_COMMAND ./configure ${sessiondeps_cross_host} ${sessiondeps_cross_rc} --prefix=${SESSIONDEPS_DESTDIR}
    --with-libunbound-only --disable-shared --enable-static
    --with-pic --$<IF:$<BOOL:${SESSIONDEPS_LTO}>,enable,disable>-flto
    --with-nettle=${SESSIONDEPS_DESTDIR} --with-libexpat=${SESSIONDEPS_DESTDIR}
    --without-ssl
    "CC=${sessiondeps_cc}" "CFLAGS=${sessiondeps_CFLAGS}" "LDFLAGS=${sessiondeps_ldflags}"
    DEPENDS sessiondep::nettle sessiondep::hogweed sessiondep::expat
)

set(extra_deps)
if(WIN32)
    set(extra_deps ws2_32 crypt32 iphlpapi)
endif()
sessiondep_static_simple(libunbound sessiondep::nettle sessiondep::hogweed ${extra_deps})
