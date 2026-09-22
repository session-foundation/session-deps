set(GLIB-2.0_VERSION 2.90.0)
string(REGEX REPLACE "^([0-9]+\\.[0-9]+).*" "\\1" GLIB-2.0_SERIES ${GLIB-2.0_VERSION})
set(GLIB-2.0_MIRROR https://download.gnome.org/sources/glib/${GLIB-2.0_SERIES})
set(GLIB-2.0_SOURCE glib-${GLIB-2.0_VERSION}.tar.xz)
set(GLIB-2.0_HASH SHA512=5ca18b4e89d0efef40d6921c33903cad242ac664e4125e8161fa7d0f0c9c65c9a7ff61d9e3ac3eb7b780b7e113392a87d12b402000f8af76b8050ddae26d0a01)

session_dep(libffi 3.0)
session_dep(libpcre2-8 10.32)
session_dep(zlib 1.2)

find_package(Threads REQUIRED)

# glib always wants a gettext provider: -Dnls=disabled only gates xgettext, it does not remove the
# dependency('intl') call.  glibc provides ngettext in libc, so this resolves there; everywhere else
# glib falls back to its proxy-libintl *wrap*, which --wrap-mode=nodownload refuses.  Non-glibc
# targets therefore need subprojects/proxy-libintl pre-populated before meson runs.
# Consumers reach glib's build tools through glib-2.0.pc's own `glib_mkenums` and `glib_genmarshal`
# variables, and meson treats a path there that does not exist as a fatal packaging error rather
# than falling back to one on PATH -- so those tools have to be installed even though nothing runs
# them by hand.  They are Python, so a cross build can execute them; glib-compile-resources is an
# ELF binary built for the target, so anything calling gnome.compile_resources() will not cross.
sessiondep_build_external(glib-2.0
    CONFIGURE_COMMAND DEFAULT_MESON
      -Dtests=false
      -Dinstalled_tests=false
      -Dnls=disabled
      -Dselinux=disabled
      -Dlibmount=disabled
      -Dxattr=false
      -Dlibelf=disabled
      -Dsysprof=disabled
      -Ddtrace=disabled
      -Dsystemtap=disabled
      -Dintrospection=disabled
      -Ddocumentation=false
      -Dman-pages=disabled
      -Dmultiarch=false
    DEPENDS sessiondep::libffi sessiondep::libpcre2-8 sessiondep::zlib
    BUILD_BYPRODUCTS
      ${SESSIONDEPS_DESTDIR}/lib/libglib-2.0.a
      ${SESSIONDEPS_DESTDIR}/lib/libgobject-2.0.a
      ${SESSIONDEPS_DESTDIR}/lib/libgmodule-2.0.a
      ${SESSIONDEPS_DESTDIR}/lib/libgio-2.0.a
      ${SESSIONDEPS_DESTDIR}/include/glib-2.0/glib.h
)

# glib_checks and glib_assert are left at their defaults on purpose: they are what turns a
# g_return_if_fail() precondition into an early return rather than undefined behaviour, and this
# library ends up parsing images from strangers.

# Declared in link order -- gio references gobject references glib -- because a single-pass linker
# takes each archive once, in the order given.
sessiondep_static_target(sessiondep_glib glib-2.0 libglib-2.0.a sessiondep::libpcre2-8)
sessiondep_static_target(sessiondep_gmodule glib-2.0 libgmodule-2.0.a sessiondep_glib)
sessiondep_static_target(sessiondep_gobject glib-2.0 libgobject-2.0.a sessiondep_glib sessiondep::libffi)
sessiondep_static_target(sessiondep_gio glib-2.0 libgio-2.0.a sessiondep_gobject sessiondep_gmodule sessiondep::zlib)

# glib splits its headers: the public ones go in include/glib-2.0, but glibconfig.h is generated per
# target and installed under lib/, so a consumer needs both directories.  Everything downstream
# includes <glib.h>, which is only findable this way.
foreach(tgt sessiondep_glib sessiondep_gmodule sessiondep_gobject sessiondep_gio)
    target_include_directories(${tgt} INTERFACE
        ${SESSIONDEPS_DESTDIR}/include/glib-2.0
        ${SESSIONDEPS_DESTDIR}/lib/glib-2.0/include)
endforeach()

if(NOT WIN32)
    target_link_libraries(sessiondep_glib INTERFACE m ${CMAKE_DL_LIBS} Threads::Threads)
else()
    # gio's networking needs the socket stack, and glib's own timing/path code wants the rest.
    target_link_libraries(sessiondep_glib INTERFACE ws2_32 winmm ole32 shlwapi)
endif()

sessiondep_bundle(glib-2.0 sessiondep_glib)
sessiondep_bundle(gmodule-2.0 sessiondep_gmodule)
sessiondep_bundle(gobject-2.0 sessiondep_gobject)
sessiondep_bundle(gio-2.0 sessiondep_gio)
