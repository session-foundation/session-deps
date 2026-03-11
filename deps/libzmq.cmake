set(LIBZMQ_VERSION 4.3.5 CACHE STRING "libzmq version")
set(LIBZMQ_MIRROR https://github.com/zeromq/libzmq/releases/download/v${LIBZMQ_VERSION}
    CACHE STRING "libzmq mirror(s)")
set(LIBZMQ_SOURCE zeromq-${LIBZMQ_VERSION}.tar.gz)
set(LIBZMQ_HASH SHA512=a71d48aa977ad8941c1609947d8db2679fc7a951e4cd0c3a1127ae026d883c11bd4203cf315de87f95f5031aec459a731aec34e5ce5b667b8d0559b157952541
    CACHE STRING "libzmq source hash")


session_dep(libsodium 1.0.17)

if(CMAKE_CROSSCOMPILING AND ARCH_TRIPLET MATCHES mingw)
  set(zmq_patch PATCH_COMMAND
        patch -p1 -i ${CMAKE_CURRENT_LIST_DIR}/patches/libzmq-mingw-unistd.patch
        # This patch is apparently somewhat crashy when used, so not currently applied:
        #COMMAND patch -p1 -i ${CMAKE_CURRENT_LIST_DIR}/patches/libzmq-mingw-wepoll.patch
  )
endif()


sessiondep_build_external(libzmq
    DEPENDS sessiondep::libsodium
    ${zmq_patch}
    CONFIGURE_COMMAND ./configure ${sessiondeps_cross_host} --prefix=${SESSIONDEPS_DESTDIR} --enable-static --disable-shared
      --disable-curve-keygen --enable-curve --disable-drafts --disable-libunwind --with-libsodium
      --without-pgm --without-norm --without-vmci --without-docs --with-pic --disable-Werror --disable-libbsd
      "CC=${sessiondeps_cc}" "CXX=${sessiondeps_cxx}"
      "CFLAGS=${sessiondeps_CFLAGS} -fstack-protector" "CXXFLAGS=${sessiondeps_CXXFLAGS} -fstack-protector"
      "sodium_CFLAGS=-I${SESSIONDEPS_DESTDIR}/include" "sodium_LIBS=-L${SESSIONDEPS_DESTDIR}/lib -lsodium"
)

set(extra_deps)
if(WIN32)
    set(extra_deps iphlpapi)
endif()
sessiondep_static_simple(libunbound sessiondep::sodium ${extra_deps})
target_compile_definitions(sessiondep_ext_libzmq INTERFACE ZMQ_STATIC)
