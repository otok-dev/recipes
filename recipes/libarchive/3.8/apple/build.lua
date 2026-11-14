-- libarchive's CMake project: the library with the dependencies of the options, given to CMake by their files, and the
-- SDK's zlib and iconv; in the tool slice also bsdtar and bsdunzip, linked with the static library. What it installs:
-- libarchive.a, or libarchive.dylib with its links (and libarchive.a beside it, which is not returned).
function build(slice, options, deps)
    local defines = {
        ENABLE_TEST = false, ENABLE_WERROR = false, ENABLE_COVERAGE = false, ENABLE_INSTALL = true,
        ENABLE_TAR = slice.is_tool, ENABLE_UNZIP = slice.is_tool, ENABLE_CPIO = false, ENABLE_CAT = false,
        ENABLE_ZLIB = options.zlib, ENABLE_BZip2 = options.bzip2, ENABLE_LZMA = options.lzma, ENABLE_LZ4 = options.lz4,
        ENABLE_ZSTD = options.zstd, ENABLE_LIBB2 = false, ENABLE_LZO = false, ENABLE_MD = false, ENABLE_BSDXML = false,
        ENABLE_EXPAT = options.xml == "expat", ENABLE_LIBXML2 = options.xml == "libxml2", ENABLE_WIN32_XMLLITE = false,
        ENABLE_OPENSSL = false, ENABLE_MBEDTLS = false, ENABLE_NETTLE = false, ENABLE_CNG = false,
        ENABLE_PCREPOSIX = false, ENABLE_PCRE2POSIX = false, ENABLE_LIBGCC = false,
        ENABLE_ACL = true, ENABLE_XATTR = true, ENABLE_ICONV = true, POSIX_REGEX_LIB = "LIBC",
        CMAKE_INSTALL_RPATH = "@loader_path",
    }
    local p = slice.platform
    if p == "watchos" or p == "watchossim" or p == "tvos" or p == "tvossim" then
        -- watchOS and tvOS declare fork, vfork and posix_spawn unavailable, though CMake's checks link them: without them
        -- the filters through external programs (filter_fork_posix.c) are left out
        defines.HAVE_FORK = false
        defines.HAVE_VFORK = false
        defines.HAVE_POSIX_SPAWNP = false
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
    end
    otok.cmake{ defines = defines }
    local prefix = slice.prefix
    local lib = otok.glob(slice.linkage == "static" and "lib/libarchive.a" or "lib/libarchive.dylib", prefix)[1]
    local out = { libraries = { archive = lib }, headers = prefix .. "/include" }
    if slice.is_tool then out.programs = { bsdtar = prefix .. "/bin/bsdtar", bsdunzip = prefix .. "/bin/bsdunzip" } end
    return out
end
