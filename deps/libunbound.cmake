set(LIBUNBOUND_VERSION 1.23.0 CACHE STRING "unbound version")
set(LIBUNBOUND_MIRROR https://nlnetlabs.nl/downloads/unbound CACHE STRING "unbound download mirror(s)")
set(LIBUNBOUND_SOURCE unbound-${LIBUNBOUND_VERSION}.tar.gz)
set(LIBUNBOUND_HASH SHA512=9b5ca48f4f5189f168f76396f5895f39262a4333e589f8c64bb9298a55c6266f626a4a4399370c68edd9f6318215a401146bf9e16a101c54decf623668a398af
    CACHE STRING "unbound source hash")


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
