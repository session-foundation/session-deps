set(SQLITE3MC_VERSION 2.3.2)
set(SQLITE3MC_SQLITE_VERSION 3.51.3)
set(SQLITE3MC_MIRROR
    https://github.com/utelle/SQLite3MultipleCiphers/releases/download/v${SQLITE3MC_VERSION})
set(SQLITE3MC_SOURCE sqlite3mc-${SQLITE3MC_VERSION}-sqlite-${SQLITE3MC_SQLITE_VERSION}-autoconf.tar.gz)
set(SQLITE3MC_HASH SHA512=cf58605cd00632cc47b7114868c735997715c91f0f306707e8405ab848056fbcf78c273d7ac2fa6995cad3cff8176a07ec5ba5b58b121b653e985cd2a57a908c)


option(SQLITE3MC_WITH_LIBICU "Build with libicu support" OFF)
option(SQLITE3MC_BUILD_SHELL "Also build and install the sqlite3mc command line shell" OFF)

set(sqlite3mc_deps)
set(sqlite3mc_config_icu)
if(SQLITE3MC_WITH_LIBICU)
    session_dep(icu-io 74)
    set(sqlite3mc_deps sessiondep::icu-io)
    set(sqlite3mc_config_icu --with-icu-config=pkg-config)
endif()

# Only the static library is needed to build against, so that is all that is built by default.  The
# shell is worth having when you want to open one of these databases by hand: being built from this
# same configure, it has the same cipher set (chacha20 by default, RC4 and the unauthenticated CBC
# modes disabled), which a distro-packaged sqlite3 does not, and so it reports these files as "not a
# database" rather than asking for a key.
set(sqlite3mc_shell_exe sqlite3mc${CMAKE_EXECUTABLE_SUFFIX})

set(sqlite3mc_build_targets libsqlite3mc.a)
set(sqlite3mc_install_targets install-headers install-lib)
set(sqlite3mc_install_shell)
set(sqlite3mc_byproducts
    ${SESSIONDEPS_DESTDIR}/lib/libsqlite3mc.a
    ${SESSIONDEPS_DESTDIR}/include/sqlite3.h)

# Readline is enabled by default upstream; the library never uses it, so it is only ever disabled
# here to avoid the link.  A shell without line editing or history is miserable, and the shell only
# gets built for development, so let it link libreadline when asked for.
set(sqlite3mc_config_readline --disable-readline)

if(SQLITE3MC_BUILD_SHELL)
    set(sqlite3mc_config_readline)
    list(APPEND sqlite3mc_build_targets ${sqlite3mc_shell_exe})

    # Copied out of the build rather than installed via upstream's install-shell rule: that rule
    # puts it under the static-deps prefix, several levels deep in the build tree, where nobody is
    # going to find it.  The build is BUILD_IN_SOURCE, so the source-relative name resolves here.
    set(sqlite3mc_install_shell
        COMMAND ${CMAKE_COMMAND} -E copy ${sqlite3mc_shell_exe} ${CMAKE_BINARY_DIR}/)
    list(APPEND sqlite3mc_byproducts ${CMAKE_BINARY_DIR}/${sqlite3mc_shell_exe})
endif()


sessiondep_build_external(sqlite3mc
    CONFIGURE_COMMAND
    ${CMAKE_COMMAND} -E env
        "PKG_CONFIG_LIBDIR=${SESSIONDEPS_DESTDIR}/lib/pkgconfig"
        ./configure ${sessiondeps_cross_host} --disable-shared --prefix=${SESSIONDEPS_DESTDIR}
        --fts5
        --with-tempstore=yes --disable-load-extension ${sqlite3mc_config_readline}
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
    BUILD_COMMAND ${sessiondeps_make} ${sqlite3mc_build_targets}
    INSTALL_COMMAND ${sessiondeps_make} ${sqlite3mc_install_targets}
        ${sqlite3mc_install_shell}
    BUILD_BYPRODUCTS ${sqlite3mc_byproducts}
    DEPENDS ${sqlite3mc_deps}
)

sessiondep_static_simple(sqlite3mc ${sqlite3mc_deps})
