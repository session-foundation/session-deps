# ngtcp2's crypto backends export the same symbols whichever TLS library they wrap, so having two
# of them in one process is not a configuration but a coin flip: whichever the dynamic loader
# reaches first satisfies every library's undefined references, not just its own.  We only ever
# build and link the gnutls backend (see libngtcp2.cmake), so a system libcurl carrying a different
# one can leave liboxenquic calling into that instead, handing a gnutls_session_t to
# SSL_do_handshake().  It segfaults on the first QUIC connection.
#
# The test is for the ngtcp2 backend rather than for openssl: a libcurl built against openssl but
# without HTTP/3 brings no ngtcp2 backend at all and is perfectly usable, which covers the distro
# packages predating HTTP/3 being enabled.  Testing for openssl instead would also be unreliable,
# since `pkg-config --static --libs libcurl` reports -lssl and -lcrypto even for the gnutls build,
# by way of libssh2 and krb5.

execute_process(
    COMMAND ${PKG_CONFIG_EXECUTABLE} --print-requires-private libcurl
    OUTPUT_VARIABLE sdep_curl_requires
    RESULT_VARIABLE sdep_curl_requires_result
    ERROR_QUIET)

# An unknown answer is not a wrong one: if pkg-config cannot tell us, leave the system library
# alone rather than forcing a static build on a guess.
if(sdep_curl_requires_result EQUAL 0
        AND sdep_curl_requires MATCHES "ngtcp2_crypto_"
        AND NOT sdep_curl_requires MATCHES "ngtcp2_crypto_gnutls")
    set(sessiondep_reject_system "uses an ngtcp2 crypto backend other than gnutls")
endif()

unset(sdep_curl_requires)
unset(sdep_curl_requires_result)
