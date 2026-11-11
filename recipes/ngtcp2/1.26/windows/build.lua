-- ngtcp2's CMake project, libngtcp2 and libngtcp2_crypto_ossl only, static, with the OpenSSL of deps.openssl given explicitly
-- (its libraries, so FindOpenSSL looks nowhere else): no examples and no tests. What it installs: ngtcp2.lib and
-- ngtcp2_crypto_ossl.lib.
function build(slice, options, deps)
    local ssl = deps.openssl
    otok.cmake{ defines = {
        ENABLE_LIB_ONLY = true, ENABLE_OPENSSL = true, ENABLE_STATIC_LIB = true, ENABLE_SHARED_LIB = false, BUILD_TESTING = false,
        ENABLE_STATIC_CRT = false,
        OPENSSL_ROOT_DIR = ssl.prefix, OPENSSL_USE_STATIC_LIBS = ssl.linkage == "static", OPENSSL_INCLUDE_DIR = ssl.include,
        OPENSSL_SSL_LIBRARY = ssl.libraries.ssl, OPENSSL_CRYPTO_LIBRARY = ssl.libraries.crypto,
    } }
    local p = slice.prefix
    return {
        libraries = { ngtcp2 = otok.glob("lib/ngtcp2.lib", p)[1], ngtcp2_crypto_ossl = otok.glob("lib/ngtcp2_crypto_ossl.lib", p)[1] },
        headers = p .. "/include",
    }
end
