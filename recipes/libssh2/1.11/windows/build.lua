-- libssh2's CMake project, the library only, with zlib compression and the crypto backend of the option: WinCNG, or the
-- OpenSSL of deps.openssl given explicitly (FindOpenSSL looks nowhere else). What it installs: libssh2.lib, a static archive,
-- or the import library with libssh2.dll.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    local defines = {
        BUILD_STATIC_LIBS = static, BUILD_EXAMPLES = false, BUILD_TESTING = false, ENABLE_ZLIB_COMPRESSION = true,
        -- FindZLIB takes MSVC's static zlib only when told to look for one
        ZLIB_USE_STATIC_LIBS = deps.zlib.linkage == "static",
    }
    if options.crypto == "openssl" then
        local ssl = deps.openssl
        defines.CRYPTO_BACKEND = "OpenSSL"
        defines.OPENSSL_ROOT_DIR = ssl.prefix
        defines.OPENSSL_USE_STATIC_LIBS = ssl.linkage == "static"
        defines.OPENSSL_INCLUDE_DIR = ssl.include
        defines.OPENSSL_SSL_LIBRARY = ssl.libraries.ssl
        defines.OPENSSL_CRYPTO_LIBRARY = ssl.libraries.crypto
    else
        defines.CRYPTO_BACKEND = "WinCNG"
        defines.ENABLE_ECDSA_WINCNG = true
    end
    otok.cmake{ defines = defines }
    local p = slice.prefix
    local lib = otok.glob("lib/libssh2.lib", p)[1]
    if static then return { libraries = { ssh2 = lib }, headers = p .. "/include" } end
    return { libraries = { ssh2 = { link = lib, runtime = otok.glob("bin/libssh2.dll", p)[1] } }, headers = p .. "/include" }
end
