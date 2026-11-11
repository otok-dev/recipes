-- ngtcp2's CMake project, libngtcp2 and libngtcp2_crypto_ossl only, with the OpenSSL of deps.openssl given explicitly (its
-- libraries, so FindOpenSSL looks nowhere else): no examples and no tests. What it installs: libngtcp2 and
-- libngtcp2_crypto_ossl, .a or .so with their links.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    local ssl = deps.openssl
    otok.cmake{ defines = {
        ENABLE_LIB_ONLY = true, ENABLE_OPENSSL = true, ENABLE_STATIC_LIB = static, ENABLE_SHARED_LIB = not static, BUILD_TESTING = false,
        OPENSSL_ROOT_DIR = ssl.prefix, OPENSSL_USE_STATIC_LIBS = ssl.linkage == "static", OPENSSL_INCLUDE_DIR = ssl.include,
        OPENSSL_SSL_LIBRARY = ssl.libraries.ssl, OPENSSL_CRYPTO_LIBRARY = ssl.libraries.crypto,
    } }
    local p = slice.prefix
    local libraries = {}
    for _, name in ipairs{ "ngtcp2_crypto_ossl", "ngtcp2" } do
        libraries[name] = otok.glob(static and "lib/lib" .. name .. ".a" or "lib/lib" .. name .. ".so", p)[1]
    end
    return { libraries = libraries, headers = p .. "/include" }
end
