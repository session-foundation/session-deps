set(LIBUNBOUND_VERSION 1.26.1)
set(LIBUNBOUND_MIRROR https://nlnetlabs.nl/downloads/unbound)
set(LIBUNBOUND_SOURCE unbound-${LIBUNBOUND_VERSION}.tar.gz)
set(LIBUNBOUND_HASH SHA256=35a6dc0e425a9282c3426d9a3043144011bf0534aed4b73ab62c52aee0af1503)


session_dep(nettle 3.6 WITH hogweed)
session_dep(expat 2)

# unbound decides whether to use pthread spinlocks by looking for the pthread_spinlock_t type, but
# bionic defines the type unconditionally while gating pthread_spin_lock() and friends at API 24
# (__INTRODUCED_IN(24)), so below that the type check passes and the calls do not compile.  Answering
# the type check for it is what a cache variable is for: the type is genuinely unusable here, and
# unbound falls back to a mutex.
set(unbound_configure_vars)
if(ANDROID AND CMAKE_SYSTEM_VERSION VERSION_LESS 24)
    list(APPEND unbound_configure_vars ac_cv_type_pthread_spinlock_t=no)
endif()

sessiondep_build_external(libunbound
    PATCHES unbound-nettle4.patch unbound-arc4random-seed.patch unbound-windows-without-ssl.patch
    CONFIGURE_COMMAND ./configure ${sessiondeps_cross_host} ${sessiondeps_cross_rc} --prefix=${SESSIONDEPS_DESTDIR}
    --with-libunbound-only --disable-shared --enable-static
    --with-pic --$<IF:$<BOOL:${SESSIONDEPS_LTO}>,enable,disable>-flto
    --with-nettle=${SESSIONDEPS_DESTDIR} --with-libexpat=${SESSIONDEPS_DESTDIR}
    --without-ssl
    "CC=${sessiondeps_cc}" "CFLAGS=${sessiondeps_CFLAGS}"
    "LDFLAGS=${sessiondeps_ldflags}"
    ${unbound_configure_vars}
    DEPENDS sessiondep::nettle sessiondep::hogweed sessiondep::expat
)

set(extra_deps)
if(WIN32)
    set(extra_deps ws2_32 crypt32 iphlpapi)
endif()
sessiondep_static_simple(libunbound sessiondep::nettle sessiondep::hogweed ${extra_deps})
