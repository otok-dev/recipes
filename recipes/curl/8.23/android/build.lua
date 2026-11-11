-- curl's CMake project, libcurl only, with exactly the libraries asked for: what curl looks for besides them (pkg-config,
-- CMake packages, optional libraries) is switched off, so that nothing of the machine reaches the library. No CA bundle is built in; the
-- certificates are looked for in Android's own directory of them. zlib is the NDK's.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    local tls = options.tls
    local defines = {
        BUILD_CURL_EXE = false, BUILD_TESTING = false, BUILD_EXAMPLES = false, BUILD_LIBCURL_DOCS = false,
        BUILD_MISC_DOCS = false, ENABLE_CURL_MANUAL = false, BUILD_STATIC_LIBS = static,
        CURL_USE_PKGCONFIG = false, CURL_USE_CMAKECONFIG = false,
        CURL_BROTLI = "OFF", CURL_ZSTD = options.zstd and "ON" or "OFF", USE_NGHTTP2 = false, CURL_USE_LIBPSL = false, USE_LIBIDN2 = false,
        CURL_USE_LIBSSH2 = false, CURL_USE_LIBSSH = false, CURL_USE_GSSAPI = false, CURL_DISABLE_LDAP = true,
        CURL_ENABLE_SSL = tls ~= "none", CURL_USE_OPENSSL = false, CURL_USE_MBEDTLS = tls == "mbedtls",
        CURL_CA_BUNDLE = "none", CURL_CA_PATH = "/system/etc/security/cacerts",
        CURL_ZLIB = "ON",
    }
    if tls == "mbedtls" then
        local mbed = deps.mbedtls
        defines.MBEDTLS_USE_STATIC_LIBS = mbed.linkage == "static"
        defines.MBEDTLS_INCLUDE_DIR = mbed.include
        defines.MBEDTLS_LIBRARY = mbed.libraries.mbedtls
        defines.MBEDX509_LIBRARY = mbed.libraries.mbedx509
        defines.MBEDCRYPTO_LIBRARY = mbed.libraries.tfpsacrypto
    end
    if options.zstd then
        local zstd = deps.zstd
        defines.ZSTD_USE_STATIC_LIBS = zstd.linkage == "static"
        defines.ZSTD_INCLUDE_DIR = zstd.include
        defines.ZSTD_LIBRARY = zstd.libraries.zstd
    end
    otok.cmake{ defines = defines }
    local p = slice.prefix
    local lib = otok.glob(static and "lib/libcurl.a" or "lib/libcurl.so", p)[1]
    return { libraries = { curl = lib }, headers = p .. "/include" }
end
