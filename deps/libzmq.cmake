set(LIBZMQ_VERSION 4.3.5)
set(LIBZMQ_MIRROR https://github.com/zeromq/libzmq/releases/download/v${LIBZMQ_VERSION})
set(LIBZMQ_SOURCE zeromq-${LIBZMQ_VERSION}.tar.gz)
set(LIBZMQ_HASH SHA512=a71d48aa977ad8941c1609947d8db2679fc7a951e4cd0c3a1127ae026d883c11bd4203cf315de87f95f5031aec459a731aec34e5ce5b667b8d0559b157952541)


session_dep(libsodium 1.0.17)

# libsodium is often a system library even when libzmq is built here (oxen-mq builds libzmq
# statically by default), so configure finds it through pkg-config with our destdir prepended
# (PKG_CONFIG_PATH) rather than substituted, picking up whichever libsodium sessiondep::libsodium
# resolved to.  Pointing it at the destdir instead fails wherever the system copy isn't on the
# compiler's default include path, such as MacPorts' /opt/local.
sessiondep_build_external(libzmq
    DEPENDS sessiondep::libsodium
    # With heartbeats enabled, a connection that dies while its receive pipe is full (the socket
    # owner not draining it) leaves an engine whose heartbeat timer still fires and aborts the
    # process on an assertion.  Present in every release through 4.3.5 (libzmq #4364, #4842).
    PATCHES libzmq-no-heartbeat-after-io-error.patch
    CONFIGURE_COMMAND ./configure ${sessiondeps_cross_host} --prefix=${SESSIONDEPS_DESTDIR} --enable-static --disable-shared
      --disable-curve-keygen --enable-curve --disable-drafts --disable-libunwind --with-libsodium
      --without-pgm --without-norm --without-vmci --without-docs --with-pic --disable-Werror --disable-libbsd
      "CC=${sessiondeps_cc}" "CXX=${sessiondeps_cxx}"
      "CFLAGS=${sessiondeps_CFLAGS} -fstack-protector" "CXXFLAGS=${sessiondeps_CXXFLAGS} -fstack-protector"
      "PKG_CONFIG_PATH=${SESSIONDEPS_DESTDIR}/lib/pkgconfig" "PKG_CONFIG=pkg-config"
)

set(extra_deps)
if(WIN32)
    set(extra_deps ws2_32 iphlpapi)
endif()
sessiondep_static_simple(libzmq sessiondep::libsodium ${extra_deps})
target_compile_definitions(sessiondep_ext_libzmq INTERFACE ZMQ_STATIC)
