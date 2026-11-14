-- libarchive's CMake project: the library with the dependencies of the options, given to CMake by their files, and the
-- NDK's zlib. What it installs: libarchive.a, or libarchive.so with its links (and libarchive.a beside it, which is not
-- returned).
function build(slice, options, deps)
    if options.xml == "libxml2" and tonumber(slice.android.api) < 28 then
        error("libarchive takes libxml2 only with iconv, which Android has from API level 28 (this project's is "
            .. slice.android.api .. "): choose xml = \"expat\" or a later API level")
    end
    local defines = {
        ENABLE_TEST = false, ENABLE_WERROR = false, ENABLE_COVERAGE = false, ENABLE_INSTALL = true,
        ENABLE_TAR = false, ENABLE_UNZIP = false, ENABLE_CPIO = false, ENABLE_CAT = false,
        ENABLE_ZLIB = options.zlib, ENABLE_BZip2 = options.bzip2, ENABLE_LZMA = options.lzma, ENABLE_LZ4 = options.lz4,
        ENABLE_ZSTD = options.zstd, ENABLE_LIBB2 = false, ENABLE_LZO = false, ENABLE_MD = false, ENABLE_BSDXML = false,
        ENABLE_EXPAT = options.xml == "expat", ENABLE_LIBXML2 = options.xml == "libxml2", ENABLE_WIN32_XMLLITE = false,
        ENABLE_OPENSSL = options.crypto == "openssl", ENABLE_MBEDTLS = false, ENABLE_NETTLE = false, ENABLE_CNG = false,
        ENABLE_PCREPOSIX = false, ENABLE_PCRE2POSIX = false, ENABLE_LIBGCC = false,
        ENABLE_ACL = false, ENABLE_XATTR = true, ENABLE_ICONV = true, POSIX_REGEX_LIB = "LIBC",
    }
    if options.bzip2 then
        defines.BZIP2_INCLUDE_DIR = deps.bzip2.include
        defines.BZIP2_LIBRARY_RELEASE = deps.bzip2.libraries.bz2
    end
    if options.lzma then
        defines.LIBLZMA_INCLUDE_DIR = deps.lzma.include
        defines.LIBLZMA_LIBRARY_RELEASE = deps.lzma.libraries.lzma
    end
    if options.lz4 then
        defines.LZ4_INCLUDE_DIR = deps.lz4.include
        defines.LZ4_LIBRARY = deps.lz4.libraries.lz4
    end
    if options.zstd then
        defines.ZSTD_INCLUDE_DIR = deps.zstd.include
        defines.ZSTD_LIBRARY = deps.zstd.libraries.zstd
    end
    if options.xml == "expat" then
        defines.EXPAT_INCLUDE_DIR = deps.expat.include
        defines.EXPAT_LIBRARY = deps.expat.libraries.expat
    elseif options.xml == "libxml2" then
        defines.LIBXML2_INCLUDE_DIR = deps.libxml2.include
        defines.LIBXML2_LIBRARY = deps.libxml2.libraries.xml2
        -- A static libxml2 needs libm, which libarchive's CMake does not link (libarchive.so).
        if deps.libxml2.linkage == "static" then defines.CMAKE_C_STANDARD_LIBRARIES = "-lm" end
    end
    if options.crypto == "openssl" then
        defines.OPENSSL_ROOT_DIR = deps.openssl.prefix
        defines.OPENSSL_USE_STATIC_LIBS = deps.openssl.linkage == "static"
        defines.OPENSSL_INCLUDE_DIR = deps.openssl.include
        defines.OPENSSL_CRYPTO_LIBRARY = deps.openssl.libraries.crypto
        defines.OPENSSL_SSL_LIBRARY = deps.openssl.libraries.ssl
    end
    otok.cmake{ defines = defines }
    local p = slice.prefix
    local lib = otok.glob(slice.linkage == "static" and "lib/libarchive.a" or "lib/libarchive.so", p)[1]
    return { libraries = { archive = lib }, headers = p .. "/include" }
end
