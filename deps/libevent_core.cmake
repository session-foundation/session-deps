set(LIBEVENT_VERSION 2.1.12-stable)
set(LIBEVENT_MIRROR https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION})
set(LIBEVENT_SOURCE libevent-${LIBEVENT_VERSION}.tar.gz)
set(LIBEVENT_HASH SHA512=88d8944cd75cbe78bc4e56a6741ca67c017a3686d5349100f1c74f8a68ac0b6410ce64dff160be4a4ba0696ee29540dfed59aaf3c9a02f0c164b00307fcfe84f)


# libevent doesn't like --host=arm64-whatever, but is okay with aarch64-whatever
set(libevent_build_host "${sessiondeps_cross_host}")
if(libevent_build_host MATCHES "(.*--host=)arm64-(.*)")
    set(libevent_build_host "${CMAKE_MATCH_1}aarch64-${CMAKE_MATCH_2}")
endif()

set(lib_pthreads ${SESSIONDEPS_DESTDIR}/lib/libevent_pthreads.a)
if(WIN32)
    set(lib_pthreads)
endif()

sessiondep_build_external(libevent
    CONFIGURE_COMMAND ./configure ${libevent_build_host} --prefix=${SESSIONDEPS_DESTDIR}
    --enable-static --disable-shared --with-pic
    --disable-openssl --disable-libevent-regress --disable-samples
    "CPPFLAGS=-I${SESSIONDEPS_DESTDIR}/include" "LDFLAGS=-L${SESSIONDEPS_DESTDIR}/lib${sessiondeps_apple_ldflags_arch}"
    "CC=${sessiondeps_cc}"
    "CXX=${sessiondeps_cxx}"
    "CFLAGS=${sessiondeps_CFLAGS}"
    "CXXFLAGS=${sessiondeps_CXXFLAGS}"
    ${sessiondeps_cross_rc}
    BUILD_BYPRODUCTS
    ${SESSIONDEPS_DESTDIR}/lib/libevent_core.a
    ${lib_pthreads}
    ${SESSIONDEPS_DESTDIR}/include/event2/event.h
)

sessiondep_static_target(sessiondep_ext_libevent_core libevent libevent_core.a)

if(lib_pthreads)
    sessiondep_static_target(sessiondep_ext_libevent_pthreads libevent libevent_pthreads.a)
else()
    # On windows we don't actually use pthreads but just adding a fake pthreads library makes
    # linking this much easier in various deps.
    add_library(sessiondep_ext_libevent_pthreads INTERFACE)
endif()
