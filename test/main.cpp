// Calls something trivial from each dependency that was built.  Linking alone proves very little
// about a static archive: nothing references it, so no member is pulled in and a library whose
// symbols are missing or whose headers do not exist links exactly as well as one that works.  A
// call per library is enough to make the linker go and find it.
//
// The results are printed rather than discarded so that the calls cannot be optimised away, and
// because a version per library is worth having in the CI log.
//
// HAVE_DEP_* comes from CMakeLists.txt, which defines one per recipe it actually built, so that
// SKIP_DEPS drops the check along with the library.

#include <cstdio>

#ifdef HAVE_DEP_EXPAT
#include <expat.h>
#endif
#ifdef HAVE_DEP_GNUTLS
#include <gnutls/gnutls.h>
#endif
#ifdef HAVE_DEP_ICU_IO
#include <unicode/ucol.h>
#include <unicode/ustdio.h>
#include <unicode/uversion.h>
#endif
#ifdef HAVE_DEP_LIBCURL
#include <curl/curl.h>
#endif
#ifdef HAVE_DEP_LIBEVENT_CORE
#include <event2/event.h>
#endif
#ifdef HAVE_DEP_LIBGMP
#include <gmp.h>
#endif
#ifdef HAVE_DEP_LIBIDN2
#include <idn2.h>
#endif
#ifdef HAVE_DEP_LIBMICROHTTPD
#include <microhttpd.h>
#endif
#ifdef HAVE_DEP_LIBNGTCP2
#include <ngtcp2/ngtcp2.h>
#endif
#ifdef HAVE_DEP_LIBSODIUM
#include <sodium.h>
#endif
#ifdef HAVE_DEP_LIBTASN1
#include <libtasn1.h>
#endif
#ifdef HAVE_DEP_LIBUNBOUND
#include <unbound.h>
#endif
#ifdef HAVE_DEP_LIBUNISTRING
#include <unistr.h>
#endif
#ifdef HAVE_DEP_LIBUTF8PROC
#include <utf8proc.h>
#endif
#ifdef HAVE_DEP_LIBZMQ
#include <zmq.h>
#endif
#ifdef HAVE_DEP_LIBZSTD
#include <zstd.h>
#endif
#ifdef HAVE_DEP_NETTLE
#include <nettle/version.h>
#endif
#ifdef HAVE_DEP_QRCODEGENCPP
#include <qrcodegen.hpp>
#endif
#ifdef HAVE_DEP_SIMDUTF
#include <simdutf.h>
#endif
#if defined(HAVE_DEP_SQLITE3) || defined(HAVE_DEP_SQLITE3MC)
#include <sqlite3.h>
#endif
#ifdef HAVE_DEP_ZLIB
#include <zlib.h>
#endif

int main() {
#ifdef HAVE_DEP_EXPAT
    std::printf("expat: %s\n", XML_ExpatVersion());
#endif
#ifdef HAVE_DEP_GNUTLS
    std::printf("gnutls: %s\n", gnutls_check_version(nullptr));
#endif
#ifdef HAVE_DEP_ICU_IO
    // One call each into icuuc, icui18n and icuio, which are three separate archives.
    UFILE* icu_out = u_finit(stdout, nullptr, nullptr);
    if (!icu_out) {
        std::fprintf(stderr, "icu: u_finit failed\n");
        return 1;
    }
    u_fclose(icu_out);
    UVersionInfo icu_version;
    u_getVersion(icu_version);
    char icu_version_str[U_MAX_VERSION_STRING_LENGTH];
    u_versionToString(icu_version, icu_version_str);
    // Counting collators reads the locale data, so this is also the check that libicudata is the
    // real thing rather than the placeholder that icu installs when its data packaging goes wrong:
    // with the stub it links and runs perfectly well and knows about nothing.
    int32_t icu_collators = ucol_countAvailable();
    std::printf("icu: %s, %d collators\n", icu_version_str, icu_collators);
    if (icu_collators <= 0) {
        std::fprintf(stderr, "icu: no collators; libicudata carries no locale data\n");
        return 1;
    }
#endif
#ifdef HAVE_DEP_LIBCURL
    std::printf("libcurl: %s\n", curl_version());
#endif
#ifdef HAVE_DEP_LIBEVENT_CORE
    std::printf("libevent: %s\n", event_get_version());
#endif
#ifdef HAVE_DEP_LIBGMP
    std::printf("libgmp: %s\n", gmp_version);
#endif
#ifdef HAVE_DEP_LIBIDN2
    std::printf("libidn2: %s\n", idn2_check_version(nullptr));
#endif
#ifdef HAVE_DEP_LIBMICROHTTPD
    std::printf("libmicrohttpd: %s\n", MHD_get_version());
#endif
#ifdef HAVE_DEP_LIBNGTCP2
    std::printf("libngtcp2: %s\n", ngtcp2_version(0)->version_str);
#endif
#ifdef HAVE_DEP_LIBSODIUM
    if (sodium_init() < 0) {
        std::fprintf(stderr, "libsodium: sodium_init failed\n");
        return 1;
    }
    std::printf("libsodium: %s\n", sodium_version_string());
#endif
#ifdef HAVE_DEP_LIBTASN1
    std::printf("libtasn1: %s\n", asn1_check_version(nullptr));
#endif
#ifdef HAVE_DEP_LIBUNBOUND
    std::printf("libunbound: %s\n", ub_version());
#endif
#ifdef HAVE_DEP_LIBUNISTRING
    std::printf("libunistring: u8_strlen %zu\n", u8_strlen((const uint8_t*)"session"));
#endif
#ifdef HAVE_DEP_LIBUTF8PROC
    std::printf("libutf8proc: %s\n", utf8proc_version());
#endif
#ifdef HAVE_DEP_LIBZMQ
    int zmq_major, zmq_minor, zmq_patch;
    zmq_version(&zmq_major, &zmq_minor, &zmq_patch);
    std::printf("libzmq: %d.%d.%d\n", zmq_major, zmq_minor, zmq_patch);
#endif
#ifdef HAVE_DEP_LIBZSTD
    std::printf("libzstd: %s\n", ZSTD_versionString());
#endif
#ifdef HAVE_DEP_NETTLE
    std::printf("nettle: %d.%d\n", nettle_version_major(), nettle_version_minor());
#endif
#ifdef HAVE_DEP_QRCODEGENCPP
    auto qr = qrcodegen::QrCode::encodeText("session", qrcodegen::QrCode::Ecc::LOW);
    std::printf("qrcodegencpp: %d modules\n", qr.getSize());
#endif
#ifdef HAVE_DEP_SIMDUTF
    const auto simdutf_name = simdutf::get_active_implementation()->name();
    std::printf("simdutf: %.*s, validate_utf8 %s\n",
                static_cast<int>(simdutf_name.size()), simdutf_name.data(),
                simdutf::validate_utf8("session", 7) ? "ok" : "failed");
#endif
#if defined(HAVE_DEP_SQLITE3) || defined(HAVE_DEP_SQLITE3MC)
    // deps/sqlite3.cmake is an alias that bundles sqlite3mc, so both recipes are the same library
    // and one call covers them.
    std::printf("sqlite3: %s\n", sqlite3_libversion());
#endif
#ifdef HAVE_DEP_ZLIB
    std::printf("zlib: %s\n", zlibVersion());
#endif

    return 0;
}
