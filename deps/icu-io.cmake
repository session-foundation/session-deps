set(ICU-IO_VERSION 78.3)
set(ICU-IO_MIRROR
    https://github.com/unicode-org/icu/releases/download/release-${ICU-IO_VERSION})
set(ICU-IO_SOURCE icu4c-${ICU-IO_VERSION}-sources.tgz)
set(ICU-IO_HASH SHA512=04a49455e1489030c520a4bfd2664fa2171e7938d08f2acdbbcb1fda976639fd8b1f0704f2eec89ba59a7b6d118ceaab6ec5a096e40d9085a0895d91ce225245)
set(ICU-IO_DATA icu4c-${ICU-IO_VERSION}-data.zip)
set(ICU-IO_DATA_SHA512 d584523acb319be1e05489469cda580fb2929f0950c176a59244ef6565faf44f3506fd25d145dce6d8b57be3ff432af033e9ea6d324d2d3538944c5313edf327)

option(LIBICU_SQLITE_ONLY "Builds libicu without things that are used in sqlite's libicu support, such as non-UTF-8 charset handling, timezone, and currency symbols")

set(libicu_feature_excludes)
if(LIBICU_SQLITE_ONLY)
    set(libicu_feature_excludes "ICU_DATA_FILTER_FILE=${CMAKE_CURRENT_LIST_DIR}/extra/libicu_sqlite_excludes.json")
endif()

sessiondep_build_external(icu-io
    CONFIGURE_COMMAND
        ${CMAKE_COMMAND} -E env ${libicu_feature_excludes}
        ./source/configure ${sessiondeps_cross_host} --enable-static
        --disable-shared --disable-icu-config --disable-strict --disable-dyload
        --disable-tests --disable-samples --with-data-packaging=static
        --prefix=${SESSIONDEPS_DESTDIR}
        CC=${sessiondeps_cc}
        CXX=${sessiondeps_cxx}
        "CFLAGS=${sessiondeps_CFLAGS} -std=c11"
        "CXXFLAGS=${sessiondeps_CXXFLAGS} -std=c++20"
    BUILD_COMMAND 
        ${CMAKE_COMMAND} -E env ${libicu_feature_excludes}
        ${sessiondeps_make}
    BUILD_BYPRODUCTS
        ${SESSIONDEPS_DESTDIR}/lib/libicudata.a
        ${SESSIONDEPS_DESTDIR}/lib/libicui18n.a
        ${SESSIONDEPS_DESTDIR}/lib/libicuuc.a
        ${SESSIONDEPS_DESTDIR}/include/unicode/utypes.h
)

if(LIBICU_SQLITE_ONLY)
    set(icu_data_file "${SESSIONDEPS_SOURCEDIR}/src/${ICU-IO_DATA}")
    if(EXISTS "${icu_data_file}")
        file(SHA512 "${icu_data_file}" icudata_hash)
        if(NOT ${icudata_hash} STREQUAL ${ICU-IO_DATA_SHA512})
            message(WARNING "${ICU-IO_DATA} hash mismatch! Deleting invalid ${icu_data_file} to re-download")
            file(REMOVE "${icu_data_file}")
        endif()
    endif()

    if(NOT EXISTS "${icu_data_file}")
        message(STATUS "Downloading ICU data source to rebuild trimmed data (becuse LIBICU_SQLITE_ONLY=ON)")
        file(DOWNLOAD
            "${ICU-IO_MIRROR}/${ICU-IO_DATA}"
            "${icu_data_file}"
            EXPECTED_HASH SHA512=${ICU-IO_DATA_SHA512})
    endif()

    set(icu_src "${SESSIONDEPS_SOURCEDIR}/src/sessiondep_icu-io_external/source")
    ExternalProject_Add_Step(sessiondep_icu-io_external icu-io_data_overlay
        DEPENDEES download
        DEPENDERS configure
        DEPENDS "${icu_data_file}"

        COMMAND ${CMAKE_COMMAND} -E remove_directory "${icu_src}/data"
        COMMAND ${CMAKE_COMMAND} -E chdir "${icu_src}" ${CMAKE_COMMAND} -E tar xf "${icu_data_file}"
    )
endif()


# These are needed by virtually all libicu usage:
sessiondep_static_target(sessiondep_icudata icu-io libicudata.a)
sessiondep_static_target(sessiondep_icuuc icu-io libicuuc.a)
sessiondep_static_target(sessiondep_icui18n icu-io libicui18n.a sessiondep_icudata sessiondep_icuuc)
sessiondep_static_target(sessiondep_icuio icu-io libicuio.a sessiondep_icui18n)

# There are also libicutu.a (tools) and libicutest.a (test suite), which still get built because of
# limitations of icu's build system, but aren't really part of the main icu library interface that
# we are trying to provide:
#sessiondep_static_target(sessiondep_icutest libicutest.a)
#sessiondep_static_target(sessiondep_icutu libicutu.a)

sessiondep_bundle(icu-io sessiondep_icudata sessiondep_icuuc sessiondep_icui18n sessiondep_icuio)
