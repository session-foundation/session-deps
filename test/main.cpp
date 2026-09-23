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

#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <initializer_list>

#ifdef HAVE_DEP_CGIF
#include <cgif.h>
#endif
#ifdef HAVE_DEP_DAV1D
#include <dav1d/dav1d.h>
#endif
#ifdef HAVE_DEP_EXPAT
#include <expat.h>
#endif
#ifdef HAVE_DEP_GLIB_2_0
#include <glib.h>
#endif
#ifdef HAVE_DEP_GNUTLS
#include <gnutls/gnutls.h>
#endif
#ifdef HAVE_DEP_ICU_IO
#include <unicode/ucol.h>
#include <unicode/ustdio.h>
#include <unicode/uversion.h>
#endif
#ifdef HAVE_DEP_IMAGEQUANT
#include <libimagequant.h>
#endif
#ifdef HAVE_DEP_LCMS2
#include <lcms2.h>
#endif
#ifdef HAVE_DEP_LIBCURL
#include <curl/curl.h>
#endif
#ifdef HAVE_DEP_LIBDE265
#include <libde265/de265.h>
#endif
#ifdef HAVE_DEP_LIBEVENT_CORE
#include <event2/event.h>
#endif
#ifdef HAVE_DEP_LIBEXIF
#include <libexif/exif-tag.h>
#endif
#ifdef HAVE_DEP_LIBFFI
#include <ffi.h>
#endif
#ifdef HAVE_DEP_LIBGMP
#include <gmp.h>
#endif
#ifdef HAVE_DEP_LIBHEIF
#include <libheif/heif.h>
#endif
#ifdef HAVE_DEP_LIBHWY
#include <hwy/targets.h>
#endif
#ifdef HAVE_DEP_LIBICONV
#include <iconv.h>
#endif
#ifdef HAVE_DEP_LIBIDN2
#include <idn2.h>
#endif
#ifdef HAVE_DEP_LIBJPEG
#include <jpeglib.h>
#endif
#ifdef HAVE_DEP_LIBMICROHTTPD
#include <microhttpd.h>
#endif
#ifdef HAVE_DEP_LIBNGTCP2
#include <ngtcp2/ngtcp2.h>
#endif
#ifdef HAVE_DEP_LIBPCRE2_8
#define PCRE2_CODE_UNIT_WIDTH 8
#include <pcre2.h>
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
#ifdef HAVE_DEP_LIBWEBP
#include <webp/decode.h>
#include <webp/encode.h>
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
#ifdef HAVE_DEP_PROXY_LIBINTL
#include <libintl.h>
#endif
#ifdef HAVE_DEP_QRCODEGENCPP
#include <qrcodegen.hpp>
#endif
#ifdef HAVE_DEP_SIMDUTF
#include <simdutf.h>
#endif
#ifdef HAVE_DEP_SPNG
#include <spng.h>
#endif
#if defined(HAVE_DEP_SQLITE3) || defined(HAVE_DEP_SQLITE3MC)
#include <sqlite3.h>
#endif
#ifdef HAVE_DEP_VIPS
#include <vips/vips.h>
#endif
#ifdef HAVE_DEP_ZLIB
#include <zlib.h>
#endif

#ifdef HAVE_DEP_CGIF
// cgif has no version call and always writes somewhere; this is where.
static int cgif_discard(void*, const uint8_t*, const size_t) {
    return 0;
}
#endif

int main() {
#ifdef HAVE_DEP_CGIF
    // A 1x1 single-colour frame, which runs the encoder end to end.
    uint8_t cgif_palette[3] = {0, 0, 0};
    uint8_t cgif_pixel = 0;
    CGIF_Config cgif_config;
    std::memset(&cgif_config, 0, sizeof cgif_config);
    cgif_config.width = 1;
    cgif_config.height = 1;
    cgif_config.pGlobalPalette = cgif_palette;
    cgif_config.numGlobalPaletteEntries = 1;
    cgif_config.pWriteFn = cgif_discard;
    CGIF_FrameConfig cgif_frame;
    std::memset(&cgif_frame, 0, sizeof cgif_frame);
    cgif_frame.pImageData = &cgif_pixel;
    CGIF* cgif = cgif_newgif(&cgif_config);
    bool cgif_ok = cgif && cgif_addframe(cgif, &cgif_frame) == CGIF_OK;
    if (cgif)
        cgif_ok = cgif_close(cgif) == CGIF_OK && cgif_ok;
    std::printf("cgif: %s\n", cgif_ok ? "encoded" : "failed");
    if (!cgif_ok)
        return 1;
#endif
#ifdef HAVE_DEP_DAV1D
    std::printf("dav1d: %s\n", dav1d_version());
#endif
#ifdef HAVE_DEP_EXPAT
    std::printf("expat: %s\n", XML_ExpatVersion());
#endif
#ifdef HAVE_DEP_GLIB_2_0
    // GRegex is implemented on pcre2, so this reaches through glib into it as well.
    GRegex* glib_re = g_regex_new("^s(e+)ssion$", G_REGEX_DEFAULT, G_REGEX_MATCH_DEFAULT, nullptr);
    bool glib_match = glib_re && g_regex_match(glib_re, "session", G_REGEX_MATCH_DEFAULT, nullptr);
    if (glib_re)
        g_regex_unref(glib_re);
    std::printf("glib: %u.%u.%u, GRegex %s\n", glib_major_version, glib_minor_version,
                glib_micro_version, glib_match ? "ok" : "failed");
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
#ifdef HAVE_DEP_IMAGEQUANT
    liq_attr* liq = liq_attr_create();
    std::printf("imagequant: max colours %d\n", liq ? liq_get_max_colors(liq) : -1);
    if (liq)
        liq_attr_destroy(liq);
#endif
#ifdef HAVE_DEP_LCMS2
    std::printf("lcms2: %d\n", cmsGetEncodedCMMversion());
#endif
#ifdef HAVE_DEP_LIBCURL
    std::printf("libcurl: %s\n", curl_version());
#endif
#ifdef HAVE_DEP_LIBDE265
    std::printf("libde265: %s\n", de265_get_version());
#endif
#ifdef HAVE_DEP_LIBEVENT_CORE
    std::printf("libevent: %s\n", event_get_version());
#endif
#ifdef HAVE_DEP_LIBEXIF
    std::printf("libexif: tag 0x0112 is %s\n", exif_tag_get_name(EXIF_TAG_ORIENTATION));
#endif
#ifdef HAVE_DEP_LIBFFI
    ffi_cif ffi_cif_int;
    ffi_type* ffi_args[1] = {&ffi_type_sint};
    std::printf("libffi: ffi_prep_cif %s\n",
                ffi_prep_cif(&ffi_cif_int, FFI_DEFAULT_ABI, 1, &ffi_type_sint, ffi_args) == FFI_OK
                        ? "ok"
                        : "failed");
#endif
#ifdef HAVE_DEP_LIBGMP
    std::printf("libgmp: %s\n", gmp_version);
#endif
#ifdef HAVE_DEP_LIBHEIF
    // The decoders are separate libraries that libheif only reaches through its own registry, so
    // asking it for them is what shows libde265 and dav1d actually made it in.
    bool heif_hevc = heif_have_decoder_for_format(heif_compression_HEVC);
    bool heif_av1 = heif_have_decoder_for_format(heif_compression_AV1);
    std::printf("libheif: %s, HEVC decoder %s, AV1 decoder %s\n", heif_get_version(),
                heif_hevc ? "yes" : "NO", heif_av1 ? "yes" : "NO");
    if (!heif_hevc || !heif_av1)
        return 1;
#endif
#ifdef HAVE_DEP_LIBHWY
    std::printf("libhwy: supported targets 0x%llx\n",
                static_cast<unsigned long long>(hwy::SupportedTargets()));
#endif
#ifdef HAVE_DEP_LIBICONV
    iconv_t iconv_cd = iconv_open("UTF-8", "ISO-8859-1");
    std::printf("libiconv: iconv_open %s\n", iconv_cd != (iconv_t)-1 ? "ok" : "failed");
    if (iconv_cd != (iconv_t)-1)
        iconv_close(iconv_cd);
#endif
#ifdef HAVE_DEP_LIBIDN2
    std::printf("libidn2: %s\n", idn2_check_version(nullptr));
#endif
#ifdef HAVE_DEP_LIBJPEG
    jpeg_compress_struct jpeg_cinfo;
    jpeg_error_mgr jpeg_err;
    jpeg_cinfo.err = jpeg_std_error(&jpeg_err);
    jpeg_create_compress(&jpeg_cinfo);
    jpeg_destroy_compress(&jpeg_cinfo);
    std::printf("libjpeg: API %d\n", JPEG_LIB_VERSION);
#endif
#ifdef HAVE_DEP_LIBMICROHTTPD
    std::printf("libmicrohttpd: %s\n", MHD_get_version());
#endif
#ifdef HAVE_DEP_LIBNGTCP2
    std::printf("libngtcp2: %s\n", ngtcp2_version(0)->version_str);
#endif
#ifdef HAVE_DEP_LIBPCRE2_8
    char pcre2_version[32];
    pcre2_config(PCRE2_CONFIG_VERSION, pcre2_version);
    std::printf("libpcre2-8: %s\n", pcre2_version);
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
#ifdef HAVE_DEP_LIBWEBP
    std::printf("libwebp: encoder 0x%x, decoder 0x%x\n", WebPGetEncoderVersion(),
                WebPGetDecoderVersion());
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
#ifdef HAVE_DEP_PROXY_LIBINTL
    // A stub: it hands back whatever it is given.
    std::printf("proxy-libintl: %s\n", gettext("untranslated"));
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
#ifdef HAVE_DEP_SPNG
    std::printf("spng: %s\n", spng_version_string());
#endif
#if defined(HAVE_DEP_SQLITE3) || defined(HAVE_DEP_SQLITE3MC)
    // deps/sqlite3.cmake is an alias that bundles sqlite3mc, so both recipes are the same library
    // and one call covers them.
    std::printf("sqlite3: %s\n", sqlite3_libversion());
#endif
#ifdef HAVE_DEP_VIPS
    // vips_init() registers every loader and saver built in, which makes this the place to catch
    // one that should not be there: libvips enables whatever it finds unless told otherwise, and
    // picks a loader by sniffing content, so anything present is reachable from any input.
    if (vips_init("deps-test")) {
        std::fprintf(stderr, "vips: vips_init failed\n");
        return 1;
    }
    int vips_bad = 0;
    for (const char* op : {"jpegload", "pngload", "webpload", "gifload", "heifload",
                           "jpegsave", "pngsave", "webpsave", "gifsave"})
        if (!vips_type_find("VipsOperation", op)) {
            std::fprintf(stderr, "vips: %s missing\n", op);
            vips_bad++;
        }
    for (const char* op :
         {"svgload", "magickload", "pdfload", "jxlload", "openslideload", "tiffload"})
        if (vips_type_find("VipsOperation", op)) {
            std::fprintf(stderr, "vips: %s present but should be disabled\n", op);
            vips_bad++;
        }
    std::printf("vips: %s, loaders %s\n", vips_version_string(), vips_bad ? "WRONG" : "as expected");
    vips_shutdown();
    if (vips_bad)
        return 1;
#endif
#ifdef HAVE_DEP_ZLIB
    std::printf("zlib: %s\n", zlibVersion());
#endif

    return 0;
}
