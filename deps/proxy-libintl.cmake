set(PROXY-LIBINTL_VERSION 0.5)
set(PROXY-LIBINTL_MIRROR https://github.com/frida/proxy-libintl/archive/refs/tags/${PROXY-LIBINTL_VERSION})
set(PROXY-LIBINTL_SOURCE proxy-libintl-${PROXY-LIBINTL_VERSION}.tar.gz)
set(PROXY-LIBINTL_HASH SHA512=8d51a6272a1495a604dd5595c8f2a3bdf4c819556ec48ce0b1691122c7dd0e4087da50825582eb24d3f77484edb6337e86f553229663d3f7c49ae8813a663a82)

# A stub implementation of the gettext API that returns its input untranslated, for C libraries
# that have no gettext of their own.  Where libc does provide it there is nothing to build.  Where it
# does not, it is installed in SESSIONDEPS_PROVIDERS_DIR rather than the destdir, so that only a
# recipe that asks for it gets it (see StaticBuild.cmake).
if(NOT sessiondeps_need_libintl)
    add_library(sessiondep_ext_proxy-libintl INTERFACE)
else()
    sessiondep_build_external(proxy-libintl
        CONFIGURE_COMMAND DEFAULT_MESON
        PREFIX ${SESSIONDEPS_PROVIDERS_DIR}
        BUILD_BYPRODUCTS
            ${SESSIONDEPS_PROVIDERS_DIR}/lib/libintl.a
            ${SESSIONDEPS_PROVIDERS_DIR}/include/libintl.h
    )

    sessiondep_static_target(sessiondep_ext_proxy-libintl proxy-libintl libintl.a
        PREFIX ${SESSIONDEPS_PROVIDERS_DIR})

    # libintl.h declares its API __declspec(dllimport) on Windows unless told the library is static.
    target_compile_definitions(sessiondep_ext_proxy-libintl INTERFACE G_INTL_STATIC_COMPILATION)
endif()
