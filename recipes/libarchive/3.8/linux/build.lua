-- libarchive's CMake project: the library with the dependencies of the options, given to CMake by their files; in the tool
-- slice also bsdtar and bsdunzip, linked with the static library. libacl is found by CMake's check of a library named
-- `acl` alone, so the ACL part of CMakeLists.txt is given the library and its headers. What it installs: libarchive.a, or
-- libarchive.so with its links (and libarchive.a beside it, which is not returned).
local function replace_once(text, from, to)
    local s, e = text:find(from, 1, true)
    if not s then error("libarchive's CMakeLists.txt has no '" .. from .. "' to patch") end
    return text:sub(1, s - 1) .. to .. text:sub(e + 1)
end

-- libacl's headers for the checks of sys/acl.h and acl/libacl.h, which come before the ACL part (the checks between them
-- that set CMAKE_REQUIRED_INCLUDES restore it), and for the compilation; the library for the checks of its functions.
local function patch_acl(acl)
    local text = otok.read("CMakeLists.txt")
    text = replace_once(text, "SET(CMAKE_REQUIRED_FLAGS)\n",
        'SET(CMAKE_REQUIRED_FLAGS)\nSET(CMAKE_REQUIRED_INCLUDES "' .. acl.include .. '")\nINCLUDE_DIRECTORIES("' .. acl.include .. '")\n')
    text = replace_once(text, 'CHECK_LIBRARY_EXISTS(acl "acl_get_file" "" HAVE_LIBACL)', "SET(HAVE_LIBACL TRUE)")
    text = replace_once(text, 'SET(CMAKE_REQUIRED_LIBRARIES "acl")',
        'SET(CMAKE_REQUIRED_LIBRARIES "' .. acl.libraries.acl .. '")\n    SET(ACL_LIBRARY "' .. acl.libraries.acl .. '")')
    otok.write("CMakeLists.txt", text)
end

function build(slice, options, deps)
    local defines = {
        ENABLE_TEST = false, ENABLE_WERROR = false, ENABLE_COVERAGE = false, ENABLE_INSTALL = true,
        ENABLE_TAR = slice.is_tool, ENABLE_UNZIP = slice.is_tool, ENABLE_CPIO = false, ENABLE_CAT = false,
        ENABLE_ZLIB = options.zlib, ENABLE_BZip2 = options.bzip2, ENABLE_LZMA = options.lzma, ENABLE_LZ4 = options.lz4,
        ENABLE_ZSTD = options.zstd, ENABLE_LIBB2 = false, ENABLE_LZO = false, ENABLE_MD = false, ENABLE_BSDXML = false,
        ENABLE_EXPAT = options.xml == "expat", ENABLE_LIBXML2 = options.xml == "libxml2", ENABLE_WIN32_XMLLITE = false,
        ENABLE_OPENSSL = options.crypto == "openssl", ENABLE_MBEDTLS = false, ENABLE_NETTLE = false, ENABLE_CNG = false,
        ENABLE_PCREPOSIX = false, ENABLE_PCRE2POSIX = false, ENABLE_LIBGCC = false,
        ENABLE_ACL = options.acl, ENABLE_XATTR = true, ENABLE_ICONV = true, POSIX_REGEX_LIB = "LIBC",
    }
    if options.zlib then
        defines.ZLIB_INCLUDE_DIR = deps.zlib.include
        defines.ZLIB_LIBRARY = deps.zlib.libraries.z
    end
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
        -- A static libxml2 needs libm, which libarchive's CMake does not link (bsdtar, bsdunzip, libarchive.so).
        if deps.libxml2.linkage == "static" then defines.CMAKE_C_STANDARD_LIBRARIES = "-lm" end
    end
    if options.crypto == "openssl" then
        defines.OPENSSL_ROOT_DIR = deps.openssl.prefix
        defines.OPENSSL_USE_STATIC_LIBS = deps.openssl.linkage == "static"
        defines.OPENSSL_INCLUDE_DIR = deps.openssl.include
        defines.OPENSSL_CRYPTO_LIBRARY = deps.openssl.libraries.crypto
        defines.OPENSSL_SSL_LIBRARY = deps.openssl.libraries.ssl
    end
    if options.acl then patch_acl(deps.libacl) end
    otok.cmake{ defines = defines }
    local p = slice.prefix
    local lib = otok.glob(slice.linkage == "static" and "lib/libarchive.a" or "lib/libarchive.so", p)[1]
    local out = { libraries = { archive = lib }, headers = p .. "/include" }
    if slice.is_tool then out.programs = { bsdtar = p .. "/bin/bsdtar", bsdunzip = p .. "/bin/bsdunzip" } end
    return out
end
