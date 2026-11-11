-- curl's CMake project, libcurl only, with exactly the libraries asked for: what curl looks for besides them (pkg-config,
-- CMake packages, optional libraries) is switched off, so that nothing of the machine reaches the library. No CA bundle or
-- directory is searched for or built in: the program names the certificates.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    local tls = options.tls
    local defines = {
        BUILD_CURL_EXE = false, BUILD_TESTING = false, BUILD_EXAMPLES = false, BUILD_LIBCURL_DOCS = false,
        BUILD_MISC_DOCS = false, ENABLE_CURL_MANUAL = false, BUILD_STATIC_LIBS = static,
        CURL_USE_PKGCONFIG = false, CURL_USE_CMAKECONFIG = false,
        CURL_BROTLI = options.brotli and "ON" or "OFF", CURL_ZSTD = options.zstd and "ON" or "OFF", USE_NGHTTP2 = options.http2, CURL_USE_LIBPSL = options.psl, USE_LIBIDN2 = options.idn,
        CURL_USE_LIBSSH2 = options.ssh, CURL_USE_LIBSSH = false, CURL_USE_GSSAPI = false, CURL_DISABLE_LDAP = true,
        CURL_ENABLE_SSL = tls ~= "none", CURL_USE_OPENSSL = tls == "openssl", CURL_USE_MBEDTLS = tls == "mbedtls",
        CURL_CA_BUNDLE = "none", CURL_CA_PATH = "none",
        -- FindZLIB takes a static zlib only when told to look for one
        CURL_ZLIB = "ON", ZLIB_USE_STATIC_LIBS = deps.zlib.linkage == "static",
    }
    if tls == "openssl" then
        local ssl = deps.openssl
        defines.OPENSSL_ROOT_DIR = ssl.prefix
        defines.OPENSSL_USE_STATIC_LIBS = ssl.linkage == "static"
        defines.OPENSSL_INCLUDE_DIR = ssl.include
        defines.OPENSSL_SSL_LIBRARY = ssl.libraries.ssl
        defines.OPENSSL_CRYPTO_LIBRARY = ssl.libraries.crypto
    elseif tls == "mbedtls" then
        local mbed = deps.mbedtls
        defines.MBEDTLS_USE_STATIC_LIBS = mbed.linkage == "static"
        defines.MBEDTLS_INCLUDE_DIR = mbed.include
        defines.MBEDTLS_LIBRARY = mbed.libraries.mbedtls
        defines.MBEDX509_LIBRARY = mbed.libraries.mbedx509
        defines.MBEDCRYPTO_LIBRARY = mbed.libraries.tfpsacrypto
    end
    if options.ssh then
        local ssh = deps.libssh2
        defines.LIBSSH2_INCLUDE_DIR = ssh.include
        defines.LIBSSH2_LIBRARY = ssh.libraries.ssh2
        defines.LIBSSH2_USE_STATIC_LIBS = ssh.linkage == "static"
    end
    if options.idn then
        local idn = deps.libidn2
        defines.LIBIDN2_INCLUDE_DIR = idn.include
        defines.LIBIDN2_LIBRARY = idn.libraries.idn2
        defines.LIBIDN2_USE_STATIC_LIBS = idn.linkage == "static"
    end
    if options.psl then
        local psl = deps.libpsl
        defines.LIBPSL_INCLUDE_DIR = psl.include
        defines.LIBPSL_LIBRARY = psl.libraries.psl
    end
    if options.http2 then
        local h2 = deps.nghttp2
        defines.NGHTTP2_USE_STATIC_LIBS = h2.linkage == "static"
        defines.NGHTTP2_INCLUDE_DIR = h2.include
        defines.NGHTTP2_LIBRARY = h2.libraries.nghttp2
    end
    if options.brotli then
        local brotli = deps.brotli
        defines.BROTLI_USE_STATIC_LIBS = brotli.linkage == "static"
        defines.BROTLI_INCLUDE_DIR = brotli.include
        defines.BROTLIDEC_LIBRARY = brotli.libraries.brotlidec
        defines.BROTLICOMMON_LIBRARY = brotli.libraries.brotlicommon
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
