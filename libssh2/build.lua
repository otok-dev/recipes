-- The CMake project, the library only, with the OpenSSL of deps.openssl given explicitly (its static
-- libraries, so FindOpenSSL looks nowhere else) and zlib from the SDK.
function build(slice, options, deps)
    local ssl = deps.openssl
    otok.cmake{
        defines = {
            BUILD_STATIC_LIBS = true, BUILD_EXAMPLES = false, BUILD_TESTING = false, ENABLE_ZLIB_COMPRESSION = true,
            CRYPTO_BACKEND = "OpenSSL", OPENSSL_ROOT_DIR = ssl.prefix, OPENSSL_USE_STATIC_LIBS = true,
            OPENSSL_INCLUDE_DIR = ssl.include, OPENSSL_SSL_LIBRARY = ssl.libraries.ssl, OPENSSL_CRYPTO_LIBRARY = ssl.libraries.crypto,
        },
    }
    return { libraries = { ssh2 = slice.prefix .. "/lib/libssh2.a" }, headers = slice.prefix .. "/include" }
end
