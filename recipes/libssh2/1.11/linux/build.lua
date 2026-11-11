-- libssh2's CMake project, the library only, with the OpenSSL of deps.openssl given explicitly (so FindOpenSSL looks nowhere
-- else) and zlib compression.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    local ssl = deps.openssl
    local defines = {
        BUILD_STATIC_LIBS = static, BUILD_EXAMPLES = false, BUILD_TESTING = false, ENABLE_ZLIB_COMPRESSION = true,
        CRYPTO_BACKEND = "OpenSSL", OPENSSL_ROOT_DIR = ssl.prefix, OPENSSL_USE_STATIC_LIBS = ssl.linkage == "static",
        OPENSSL_INCLUDE_DIR = ssl.include, OPENSSL_SSL_LIBRARY = ssl.libraries.ssl, OPENSSL_CRYPTO_LIBRARY = ssl.libraries.crypto,
    }
    -- FindZLIB takes a static zlib only when told to look for one
    if deps.zlib then defines.ZLIB_USE_STATIC_LIBS = deps.zlib.linkage == "static" end
    otok.cmake{ defines = defines }
    local p = slice.prefix
    return { libraries = { ssh2 = otok.glob(static and "lib/libssh2.a" or "lib/libssh2.so", p)[1] }, headers = p .. "/include" }
end
