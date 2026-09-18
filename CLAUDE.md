# session-deps

Builds the Session projects' C/C++ dependencies from source, statically, for Linux, Apple platforms
(macOS and, via `SDK_NAME`, iOS), Windows (mingw-w64 cross) and Android.  Consumed as a submodule: a
project includes `Deps.cmake` and asks for what it needs with `session_dep()`, which finds a suitable
system package or falls back to building one here.

CI covers only Linux, macOS and mingw — the Android and iOS paths are exercised by whoever builds
them, so code guarded by `ANDROID` or an Apple SDK check can rot unnoticed.

`README.md` documents the user-facing side — the cmake options, `session_dep()`, how to add a
package, and `check/PKG.cmake` system-package rejection.  Read it first; this file is what it does
not say.

## Layout

| path | what |
| --- | --- |
| `Deps.cmake` | entry point; `session_dep()`, the system-vs-static decision, version handshake |
| `deps/StaticBuild.cmake` | shared machinery: toolchain flags, the `sessiondep_*` functions |
| `deps/PKG.cmake` | one recipe per package, named for its pkg-config module |
| `deps/patches/` | patches applied to upstream sources |
| `check/PKG.cmake` | optional veto on an otherwise acceptable system package |
| `test/` | a project that builds every recipe and uses each one; what CI runs |
| `.drone.jsonnet` | CI pipelines |

## Recipes

A recipe is included only via `session_dep()`, never directly, and ends up providing
`sessiondep::PKG`.  Most of one looks like:

    set(LIBFOO_VERSION 1.2.3)
    set(LIBFOO_MIRROR https://example.com/download)
    set(LIBFOO_SOURCE libfoo-${LIBFOO_VERSION}.tar.xz)
    set(LIBFOO_HASH SHA512=...)

    session_dep(zlib 1.2)             # sub-dependencies, same mechanism

    sessiondep_build_external(libfoo
        PATCHES libfoo-something.patch
        CONFIGURE_COMMAND ...          # omit to get the standard ./configure
        DEPENDS sessiondep::zlib
    )
    sessiondep_static_simple(libfoo sessiondep::zlib)

Functions, all in `deps/StaticBuild.cmake` unless noted:

- `session_dep(PKG minver [WITH ...])` — *`Deps.cmake`*; the only way to pull in a dependency.
- `sessiondep_build_external(name ...)` — wraps `ExternalProject_Add` with the right compiler,
  flags, prefix and cross settings.  Takes `PATCHES`, `DEPENDS`, `CONFIGURE_COMMAND`,
  `BUILD_COMMAND`, `INSTALL_COMMAND`, `BUILD_BYPRODUCTS`, `PATCH_COMMAND`.
- `sessiondep_static_target(target ext libfoo.a [deps...])` — one imported archive.
- `sessiondep_static_simple(name [deps...])` — the common case: one archive named after the recipe.
- `sessiondep_bundle(name targets...)` — an interface target over several archives (see `icu-io`).
- `sessiondep_link_flags(out targets...)` — flattens cmake targets to a linker argument list, for
  handing to a foreign build system's `LIBS=`.
- `sessiondep_expand_urls(out file mirrors...)` — applies `LOCAL_MIRROR`.

Build settings come from promoted cache variables, not from computing your own: `sessiondeps_cc`,
`sessiondeps_cxx`, `sessiondeps_CFLAGS`, `sessiondeps_CXXFLAGS`, `sessiondeps_ldflags`,
`sessiondeps_make`, `sessiondeps_patch`, `sessiondeps_cross_host`, `sessiondeps_cross_rc`.  Anything
set as `deps_foo` near the end of `StaticBuild.cmake` is promoted to `sessiondeps_foo`; add to the
`foreach` promotion list when introducing one.

**Bump `session_deps_version` in `Deps.cmake` with any recipe change.**  When several projects in one
build tree carry this submodule, the highest version wins and the others are ignored, so a fix in a
copy with a stale version silently does nothing.

## Patches

Recipes name patches with `PATCHES`, bare filenames relative to `deps/patches/`.  Every patch is
applied with `-p1`; a patch from elsewhere that strips differently gets `a/` and `b/` prefixes added
to its headers rather than its own strip level.

`patch` runs as `patch -N -f` so it can never stop for input.  On a terminal an unapplyable patch
otherwise waits for an answer forever instead of failing.  Do not "fix" that with `--batch`: despite
the name it answers *yes, it looks reversed*, reverse-applies and exits **0**, which for a patch
upstream has since adopted means silently deleting the fix.

Generating one:

- **Produce it with `diff -u`, never by hand.**  Hand-written hunk headers get the line counts wrong
  and apply with fuzz or silently wrong.  Copy the file to a scratch directory, edit the copy, and
  `diff -u --label a/path --label b/path`.
- Verify with `patch -p1 -F0 --dry-run` against a *pristine* extracted tarball.  Fuzz means the
  context does not really match.
- Prefer a patch from MSYS2, MXE, Debian or the distro that already solved it over writing one;
  note the provenance at the top of the file.
- Explain *why* upstream needs it at the top of the patch file, above the diff.
- Re-check patches on a version bump.  A patch upstream has adopted now fails the build (good), but
  one whose context merely drifted can apply in the wrong place.

## Things that have bitten us

**A static archive nothing references contributes nothing.**  Linking against a `.a` proves the
target and its flags are coherent, not that its symbols exist or its headers are installed.  This is
why `test/main.cpp` calls into every library.

**libtool absorbs a `.a` named on a link line.**  Passing archive *paths* in an autotools `LIBS=`
gets their members copied into the library being built — a `libcurl.a` with `libgnutls.a` inside it.
Pass `-L`/`-l` instead; `sessiondep_link_flags()` does.

**Link order matters and cmake only knows what you tell it.**  A single-pass linker takes each
archive once, in order, so an archive that references a symbol must come *before* the one defining
it.  Declare the dependency between `sessiondep_static_target()`s rather than relying on the order
they happen to appear in; `icuuc` referencing `icudata` is the worked example.

**A Windows static library usually needs a define saying so.**  Headers that support both DLL and
static builds default to `__declspec(dllimport)`, so callers look for `__imp_foo` and the plain
symbol in the archive does not match.  The target must carry the library's own opt-out as an
`INTERFACE` definition — `UTF8PROC_STATIC`, `CURL_STATICLIB`, `ZMQ_STATIC`, `NGTCP2_STATICLIB`.
Windows also wants system libraries named explicitly (`ws2_32` for anything doing sockets,
`iphlpapi`, `crypt32`, `bcrypt`).

**Cross builds run host-compiled tools against target config.**  The worst bugs here come from a
tool built for the build machine making decisions with `#if` on *its* platform while reading the
target's settings — ICU's `pkgdata` names the data library that way and silently produces one nobody
installs.  When a cross build misbehaves, ask which machine the deciding code was compiled for.

**Autotools flags can be silently inert.**  `AC_ARG_WITH` names are collected at generation time, so
a flag whose handling sits inside a conditional is accepted and ignored with no warning
(`--without-ssl` does nothing for unbound once `--with-nettle` is given).  Check that a flag reaches
`config.h`/`configdata.pm` rather than assuming.

**`deps/sqlite3.cmake` is an alias** that bundles `sqlite3mc`; there is no separate stock sqlite3
build.

## Testing

`test/` builds every recipe — globbed, so a new recipe is covered without being listed — and links
`main.cpp`, which calls something from each and prints its version.  `HAVE_DEP_*` is defined per
recipe built, so the calls follow `SKIP_DEPS`.

The glob covers building, but the calls in `main.cpp` are written by hand, so **a new recipe gets
built and linked with nothing exercising it until someone adds one**.  Add the call with the recipe.

    cmake -S test -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DLOCAL_MIRROR=https://oxen.rocks/deps
    ninja -C build

`-DSKIP_DEPS='libfoo;libbar'` drops recipes; it lives in the CI job rather than in the cmake so a
skip is visible where it applies instead of switching off coverage everywhere.

A full run builds everything and is slow.  To iterate on one dep, build just its target
(`ninja sessiondep_libfoo_external`), or work in a scratch copy of the extracted source with the
recipe's own configure line — `make -k` there finds every compile error in one pass instead of one
per CI round trip.

## CI

`.drone.jsonnet` — seven pipelines: Debian sid/bookworm/trixie, Ubuntu jammy, mingw cross, macOS
arm and intel.  Run `jsonnetfmt --test .drone.jsonnet` after editing.

The arm builders run out of memory above 4 concurrent compiles, so those pipelines pass `jobs=4`.

CI builds `deps-test` but does not run it, so runtime breakage in a library that links fine is not
currently caught.
