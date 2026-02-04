set(SQLITE3MC_VERSION 2.2.7 CACHE STRING "SQLite3 Multiple Ciphers version")
set(SQLITE3MC_SQLITE_VERSION 3.51.2 CACHE STRING "SQLite3 Multiple Ciphers underlying sqlite3 version")
set(SQLITE3MC_MIRROR
    https://github.com/utelle/SQLite3MultipleCiphers/releases/download/v2.2.7
    CACHE STRING "sqlite3mc download mirror(s)")
set(SQLITE3MC_SOURCE sqlite3mc-${SQLITE3MC_VERSION}-sqlite-${SQLITE3MC_SQLITE_VERSION}-autoconf.tar.gz)
set(SQLITE3MC_HASH SHA512=b901a294f5417a585c5aafb65f350b6ccfb699d0673462a1c54ae5e1cfa6032f2e0e636c9b5df98079a3480eb71b4a4e385b5126c7d7785461b11b88d6969b68
    CACHE STRING "sqlite3mc source hash")


option(SQLITE3MC_WITH_LIBICU "Build with libicu support" OFF)

set(sqlite3mc_deps)
set(sqlite3mc_config_icu)
if(SQLITE3MC_WITH_LIBICU)
    session_dep(icu-io 74)
    set(sqlite3mc_deps sessiondep::icu-io)
    set(sqlite3mc_config_icu --with-icu-config=pkg-config)
endif()


sessiondep_build_external(sqlite3mc
    CONFIGURE_COMMAND
    ${CMAKE_COMMAND} -E env
        "PKG_CONFIG_LIBDIR=${SESSIONDEPS_DESTDIR}/lib/pkgconfig"
        ./configure ${sessiondeps_cross_host} --disable-shared --prefix=${SESSIONDEPS_DESTDIR}
        --fts5
        --with-tempstore=yes --disable-load-extension --disable-readline
        ${sqlite3mc_config_icu}
        # Already the default, but just being explicit in case a future version changes it:
        --default-cipher=chacha20
        # Disable weak ciphers:
        # - RC4 is just silly (and is used for compatibility with some ancient badly implemented
        #   .NET component)
        # - aes128cbc and aes256cbc aren't exactly weak, but they aren't authenticated and thus
        #   don't (necessarily) detect tampering or corruption, and so aren't great choices compared
        #   to anything else here that is authenticated (nor are they widely used enough for us to
        #   worry about offering compatibility).
        --disable-cipher-rc4 --disable-cipher-aes128cbc --disable-cipher-aes256cbc
        "CC=${sessiondeps_cc}" "CFLAGS=${sessiondeps_CFLAGS}" ${sessiondeps_cross_extra}
    BUILD_COMMAND ${sessiondeps_make} libsqlite3mc.a
    INSTALL_COMMAND ${sessiondeps_make} install-headers install-lib
    BUILD_BYPRODUCTS
        ${SESSIONDEPS_DESTDIR}/lib/libsqlite3mc.a
        ${SESSIONDEPS_DESTDIR}/include/sqlite3.h
    DEPENDS ${sqlite3mc_deps}
)

sessiondep_static_simple(sqlite3mc ${sqlite3mc_deps})
