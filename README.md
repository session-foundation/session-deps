# Session Project CMake static dependency build tools

This package contains various common cmake code for loading dependencies, optionally from the system
or with fallback (or in some cases, only) static builds.

The scripts contained in this repository used to be scattered and duplicated around several separate
Session projects; this repo exists to consolidate the efforts of maintaining the various
dependencies of the many Session subprojects.

## Usage example:

    add_subdirectory(session-deps)

    # Search for a dependency, setting up a static build if not found or system deps are disabled.
    # This call requires that the package be one of the packages with static builds supported by
    # this repository.
    session_dep(libngtcp2 1.5.0)
    target_link_libraries(mylib PRIVATE sessiondep::libngtcp2)

    # Look for a system dependency and, if not found, add the given subdirectory for submodule
    # cmake projects *outside* this repository.  The first two arguments are as above; the third is
    # the subdirectory to add if the system lib is not found; and the fourth (and beyond, if given)
    # is the name of the target that session::${pkg} should point at if the subdirectory approach is
    # taken.
    session_dep_or_subdir(CLI11 2.2.0 path_to_cli11 CLI11::CLI11)
    target_link_libraries(mytarget PRIVATE sessiondep::CLI11)

The first example above will attempt to find ngtcp2 via system library (at least version 1.5.0), and
if not found will fall back to a static build.  The second example loads attempts to load CLI11 via
system library, and if not found, runs a `add_subdirectory(path_to_cli11)` and then makes a
`sessiondep::CLI11` an interface target that links to CLI11::CLI11.

## CMake options

### `SESSIONDEPS_STATIC=ON`

This is the "all static" master switch: if set to true (e.g. via `-DSESSIONDEPS_STATIC=ON` or
`set(SESSIONDEPS_STATIC ON CACHE BOOL "")`) then all `session_dep(...)` calls build static
dependencies and ignore anything on the system.

### `SESSIONDEPS_STATIC_${pkg}=ON`

This variable is a per-package override that forces the named package in question to ignore system
libraries and use a static build.  Note that system library dependencies of ${pkg} may still be
used.  This option has no effect when the global `SESSIONDEPS_STATIC` option is turned on.

### `SESSIONDEPS_LTO=ON/OFF`

Enabled or disable LTO for static dependency builds, where supported.

### `SESSIONDEPS_SUBMODULE=ON`

This flag forces all `session_dep_or_subdir` calls to take the submodule route, bypassing the
detection of system libraries.

### `SESSIONDEPS_SUBMODULE_${pkg}=ON`

This flag overrides `session_dep_or_subdir` for just a single package to force that package to
ignore system libs and use a submodule.

### `LOCAL_MIRROR`

This can be set to a mirror to check first for downloads, with fallback to the upstream download
URL, when download static sources.  For instance, CI jobs for Session projects typically set this to
https://oxen.rocks/deps/.  (Note that source files are hashed and verified, so use of a local mirror
does not allow modified source packages).

## Duplicate dependency handling

This code can safely be used by multiple callers with different requirements without worrying about
getting mixed versions.  For example, if project A requires xyz>=1.1 and also uses a submodule B
that uses this code and requires xyz>=1.2, then the system library will only be used if it can
satisfy both requirements.  If the system version found was 1.1.5 then this will build and link to
the static library for both dependencies.

## session_dep

This function is used to look for a system dependency, and if not found, build the dependency as a
static library using one of the available static dep build scripts in this repository.  Typical
usage specifies the pkg-config library name and the minimum required version such as:

    session_dep(libngtcp2 1.5.0)

This will make available a sessiondep::libngtcp2 target that is either a system library >= 1.5.0, or
alternatively the local static build of libngtcp2.

Optional arguments that can be added after the version are as follows:

    TARGET tgt

This will override the dependency target to be `tgt` instead of the given pkg-config name, and can
be used if the pkg-config name is unsuitable for some reason.

    WITH pkgspec [...]

If the dependency requires multiple pkg configs at once then you can use this to only load if all
pkg-config targets are found, and otherwise fall back to the builtin.  For example:

    session_dep(libngtcp2 1.5.0 WITH libngtcp2_crypto_gnutls>=1.5.0)

would either create a sessiondep::libngtcp2 target that links to both the specified libraries, or
else links to the bundled libngtcp2 build.

## Adding new builds

Static package builds go into deps/PKG.cmake and generally should make use of deps/StaticBuild.cmake
as much as possible for compiler flags and settings.  For typical automake packages that can simply
be a matter of calling sessiondep_build_external(...).

More advanced builds may need to do things differently: if so the build is expected to create a
`sessiondep_ext_PKG` cmake target carrying the library dependencies, include directories, and so on.
