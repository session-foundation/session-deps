// Compiled apart from main.cpp: jpegli's headers put its own copy of <jpeglib.h> ahead of
// libjpeg-turbo's, which main.cpp's libjpeg calls must not see.

#include <csetjmp>
#include <cstdio>
#include <cstdlib>
#include <vector>

#include "lib/jpegli/encode.h"

namespace {
struct error_mgr {
    jpeg_error_mgr pub;
    std::jmp_buf jump;
};

[[noreturn]] void on_error(j_common_ptr cinfo) {
    std::longjmp(reinterpret_cast<error_mgr*>(cinfo->err)->jump, 1);
}
}  // namespace

bool test_jpegli() {
    constexpr int w = 16, h = 16;
    std::vector<unsigned char> rgb(w * h * 3);
    for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++) {
            unsigned char* p = &rgb[(y * w + x) * 3];
            p[0] = x * 16, p[1] = y * 16, p[2] = 128;
        }

    jpeg_compress_struct cinfo;
    error_mgr err;
    unsigned char* out = nullptr;
    unsigned long out_size = 0;
    cinfo.err = jpegli_std_error(&err.pub);
    err.pub.error_exit = on_error;
    if (setjmp(err.jump)) {
        jpegli_destroy_compress(&cinfo);
        std::free(out);
        std::fprintf(stderr, "jpegli: encoding failed\n");
        return false;
    }
    jpegli_create_compress(&cinfo);
    jpegli_mem_dest(&cinfo, &out, &out_size);
    cinfo.image_width = w;
    cinfo.image_height = h;
    cinfo.input_components = 3;
    cinfo.in_color_space = JCS_RGB;
    jpegli_set_defaults(&cinfo);
    jpegli_set_quality(&cinfo, 80, TRUE);
    jpegli_start_compress(&cinfo, TRUE);
    while (cinfo.next_scanline < cinfo.image_height) {
        JSAMPROW row = &rgb[cinfo.next_scanline * w * 3];
        jpegli_write_scanlines(&cinfo, &row, 1);
    }
    jpegli_finish_compress(&cinfo);
    jpegli_destroy_compress(&cinfo);

    bool ok = out_size > 4 && out[0] == 0xFF && out[1] == 0xD8 && out[out_size - 2] == 0xFF &&
              out[out_size - 1] == 0xD9;
    std::printf("jpegli: encoded %dx%d to %lu bytes, %s\n", w, h, out_size,
                ok ? "valid JPEG markers" : "BAD OUTPUT");
    std::free(out);
    return ok;
}
