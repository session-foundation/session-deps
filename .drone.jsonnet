// CI for session-deps itself.  There is nothing here to build but the dependency recipes, so every
// pipeline builds test/, which pulls in every recipe in deps/ and links against all of them.  The
// point is that a recipe which has rotted -- an upstream that moved its tarball, a configure option
// that went away, a platform it never actually built on -- is found here rather than by whichever
// project next needs it.
//
// The dependency list is not written down anywhere: test/CMakeLists.txt globs deps/, so a recipe
// added without touching this file is still covered.

local docker_base = 'registry.oxen.rocks/';

local apt_get_quiet = 'apt-get -o=Dpkg::Use-Pty=0 -q';

// Dep sources come from our own mirror first so that CI does not hammer (or depend on the
// availability of) a dozen upstream download sites.
local local_mirror = ' -DLOCAL_MIRROR=https://oxen.rocks/deps ';

// Everything needed to build the recipes themselves; the deps' own dependencies get built, not
// installed, which is the whole point.
local build_tools = 'build-essential cmake git pkg-config ccache ca-certificates automake autoconf '
                    + 'libtool patch file xz-utils unzip python3';

// Running deps-test is the point of it: building only proves the recipes compiled, while the run
// calls into every library and is what catches one that links but does not work.  A cross build
// that the CI machine cannot execute passes run_test='' and gets the build only.
local build_commands(jobs, cmake_extra='', run_test='./deps-test') = [
  'mkdir build',
  'cd build',
  'cmake ../test -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_COLOR_DIAGNOSTICS=ON '
  + cmake_extra + local_mirror,
  'ninja -j' + jobs + ' -v',
] + (if run_test == '' then [] else [run_test]);

// glib needs meson >= 1.4.  `meson` is the package name to install it from, for a release whose own
// is too old; `meson_setup` runs after the package install, for one where no package will do.
local linux_pipeline(name,
                     image,
                     arch='amd64',
                     extra_pkgs='',
                     cmake_extra='',
                     jobs=6,
                     run_test='./deps-test',
                     apt_sources=[],
                     meson='meson',
                     meson_setup=[],
                     allow_fail=false) = {
  kind: 'pipeline',
  type: 'docker',
  name: name,
  platform: { arch: arch },
  steps: [{
    name: 'build',
    image: image,
    pull: 'always',
    [if allow_fail then 'failure']: 'ignore',
    commands: [
      'echo "Building on ${DRONE_STAGE_MACHINE}"',
      'echo "man-db man-db/auto-update boolean false" | debconf-set-selections',
    ] + [
      'echo "' + src + '" >> /etc/apt/sources.list.d/extra.list'
      for src in apt_sources
    ] + [
      apt_get_quiet + ' update',
      apt_get_quiet + ' install -y eatmydata',
      'eatmydata ' + apt_get_quiet + ' install --no-install-recommends -y ninja-build ' + meson + ' '
      + build_tools + ' ' + extra_pkgs,
    ] + meson_setup + build_commands(jobs, cmake_extra, run_test),
  }],
};

local mac_pipeline(name,
                   arch='amd64',
                   jobs=6,
                   setup=[],
                   cmake_extra='',
                   run_test='./deps-test',
                   allow_fail=false) = {
  kind: 'pipeline',
  type: 'exec',
  name: name,
  platform: { os: 'darwin', arch: arch },
  steps: [{
    name: 'build',
    [if allow_fail then 'failure']: 'ignore',
    commands: [
      'echo "Building on ${DRONE_STAGE_MACHINE}"',
      // Without this the C compiler has no include path containing basic system headers.
      'export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"',
    ] + setup + build_commands(jobs, cmake_extra, run_test),
  }],
};

// The Android NDK ships the toolchain file; the image has the NDK at this path.
local android_ndk = '/usr/lib/android-ndk';
local android_pipeline(abi, jobs=6) = linux_pipeline(
  'Android (' + abi + ')',
  docker_base + 'android',
  jobs=jobs,
  cmake_extra='-DCMAKE_TOOLCHAIN_FILE=' + android_ndk + '/build/cmake/android.toolchain.cmake '
              + '-DANDROID_ABI=' + abi + ' -DANDROID_ARM_MODE=arm -DANDROID_PLATFORM=android-23 '
              + '-DANDROID_STL=c++_static '
              // OpenSSL has to be told its target when cross-compiling, and only mingw is mapped.
              + '-DSKIP_DEPS=libssl ',
  run_test='',
);

local ios_pipeline(name, platform, jobs=6, allow_fail=false) = mac_pipeline(
  name,
  arch='arm64',
  jobs=jobs,
  // Not --depth=1: the submodule is pinned to a commit that is not its branch tip, which a shallow
  // fetch can only retrieve if the server happens to allow fetching arbitrary revisions.
  setup=['git submodule update --init --recursive'],
  cmake_extra='-DCMAKE_TOOLCHAIN_FILE=../external/ios-cmake/ios.toolchain.cmake -DPLATFORM='
              + platform + ' -DDEPLOYMENT_TARGET=13 -DENABLE_BITCODE=OFF '
              // OpenSSL has to be told its target when cross-compiling, and only mingw is mapped.
              + '-DSKIP_DEPS=libssl ',
  run_test='',
  allow_fail=allow_fail,
);

[
  linux_pipeline('Debian sid (amd64)', docker_base + 'debian-sid'),
  // The arm builders run out of memory above 4 concurrent compiles.
  linux_pipeline('Debian bookworm (arm64)',
                 docker_base + 'debian-bookworm',
                 arch='arm64',
                 jobs=4,
                 apt_sources=['deb http://deb.debian.org/debian bookworm-backports main'],
                 meson='meson/bookworm-backports'),
  // Nothing packaged for jammy is new enough, not even in backports, and meson is pure Python.
  linux_pipeline('Ubuntu jammy (amd64)',
                 docker_base + 'ubuntu-jammy',
                 meson='python3-pip',
                 meson_setup=['pip3 install --no-cache-dir meson==1.7.0']),
  // armhf is built on an arm64 machine, as the 32-bit runners are.
  linux_pipeline('Debian trixie (armhf)', docker_base + 'debian-trixie/arm32v7', arch='arm64', jobs=4),

  // The test binary is built static, so wine can run it without the cross toolchain's DLLs.
  linux_pipeline('Windows x64 (mingw)',
                 docker_base + 'debian-sid',
                 extra_pkgs='g++-mingw-w64-x86-64-posix wine',
                 cmake_extra='-DCMAKE_TOOLCHAIN_FILE=../test/cross/mingw-x64.cmake ',
                 run_test='WINEDEBUG=-all wine ./deps-test.exe'),

  mac_pipeline('macOS (ARM)', arch='arm64'),
  mac_pipeline('macOS (Intel)'),

  // The two ABIs Session ships, plus x86_64 for the emulator most Android development runs on.  x86
  // can be added here if it is ever worth the build time.
  android_pipeline('arm64-v8a'),
  android_pipeline('armeabi-v7a'),
  android_pipeline('x86_64'),

  ios_pipeline('iOS (device)', 'OS64'),
  ios_pipeline('iOS (simulator)', 'SIMULATORARM64'),
]
