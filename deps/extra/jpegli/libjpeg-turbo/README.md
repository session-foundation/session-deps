# libjpeg-turbo headers for jpegli

jpegli implements the libjpeg API, and rather than carry its own copy of libjpeg's declarations its
build copies these three files out of a libjpeg-turbo git submodule.  A commit tarball of jpegli
does not include submodule contents, so `deps/jpegli.cmake` copies these into the extracted source
at `third_party/libjpeg-turbo/` instead.

They are unmodified copies from libjpeg-turbo commit `8ecba3647edb6dd940463fedf38ca33a8e2a73d1`,
the commit jpegli's own `third_party/libjpeg-turbo` submodule pins.  On a jpegli bump, check which
commit the new version pins and refresh these if it has changed:

    https://raw.githubusercontent.com/libjpeg-turbo/libjpeg-turbo/<commit>/<file>

They are covered by libjpeg-turbo's license (the IJG license and the modified BSD license); see
https://github.com/libjpeg-turbo/libjpeg-turbo/blob/main/LICENSE.md.
