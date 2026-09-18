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
// calls into every library and is what catches one that links but does not work.
local build_commands(jobs, cmake_extra='', run_test='./deps-test') = [
  'mkdir build',
  'cd build',
  'cmake ../test -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_COLOR_DIAGNOSTICS=ON '
  + cmake_extra + local_mirror,
  'ninja -j' + jobs + ' -v',
  run_test,
];

local linux_pipeline(name,
                     image,
                     arch='amd64',
                     extra_pkgs='',
                     cmake_extra='',
                     jobs=6,
                     run_test='./deps-test',
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
      apt_get_quiet + ' update',
      apt_get_quiet + ' install -y eatmydata',
      'eatmydata ' + apt_get_quiet + ' install --no-install-recommends -y ninja-build '
      + build_tools + ' ' + extra_pkgs,
    ] + build_commands(jobs, cmake_extra, run_test),
  }],
};

local mac_pipeline(name, arch='amd64', jobs=6, allow_fail=false) = {
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
    ] + build_commands(jobs),
  }],
};

[
  linux_pipeline('Debian sid (amd64)', docker_base + 'debian-sid'),
  // The arm builders run out of memory above 4 concurrent compiles.
  linux_pipeline('Debian bookworm (arm64)', docker_base + 'debian-bookworm', arch='arm64', jobs=4),
  linux_pipeline('Ubuntu jammy (amd64)', docker_base + 'ubuntu-jammy'),
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
]
