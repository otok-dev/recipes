-- curl's CMake project, libcurl only, static, with exactly the libraries asked for: what curl looks for besides them (CMake
-- packages, optional libraries, the Windows LDAP) is switched off, so that nothing of the machine reaches the library. Schannel
-- uses the system's certificates; with OpenSSL or Mbed TLS no CA bundle is built in or searched for (in PATH either), the
-- program names the certificates. What it installs: libcurl.lib (libcurl-d.lib in debug).
function build(slice, options, deps)
    local tls = options.tls
    local defines = {
        BUILD_CURL_EXE = false, BUILD_TESTING = false, BUILD_EXAMPLES = false, BUILD_LIBCURL_DOCS = false,
        BUILD_MISC_DOCS = false, ENABLE_CURL_MANUAL = false, BUILD_STATIC_LIBS = true,
        CURL_USE_PKGCONFIG = false, CURL_USE_CMAKECONFIG = false,
        CURL_BROTLI = options.brotli and "ON" or "OFF", CURL_ZSTD = options.zstd and "ON" or "OFF", USE_NGHTTP2 = options.http2, CURL_USE_LIBPSL = false, USE_LIBIDN2 = false,
        USE_WIN32_IDN = false, USE_WIN32_LDAP = false, CURL_DISABLE_LDAP = true,
        CURL_USE_LIBSSH2 = options.ssh, CURL_USE_LIBSSH = false, CURL_USE_GSSAPI = false,
        CURL_ENABLE_SSL = tls ~= "none", CURL_USE_SCHANNEL = tls == "schannel",
        CURL_USE_OPENSSL = tls == "openssl", CURL_USE_MBEDTLS = tls == "mbedtls",
        CURL_CA_BUNDLE = "none", CURL_CA_PATH = "none", CURL_DISABLE_CA_SEARCH = true,
        -- the CRT is the slice's (/MD, /MDd); FindZLIB takes MSVC's static zlib only when told to look for one
        CURL_STATIC_CRT = false, CURL_ZLIB = "ON", ZLIB_USE_STATIC_LIBS = deps.zlib.linkage == "static",
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
        defines.MBEDTLS_USE_STATIC_LIBS = true
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
    return { libraries = { curl = otok.glob("lib/libcurl*.lib", p)[1] }, headers = p .. "/include" }
end
