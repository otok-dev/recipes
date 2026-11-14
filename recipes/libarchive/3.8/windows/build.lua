-- libarchive's CMake project: the library with the dependencies of the options, given to CMake by their files; in the tool
-- slice also bsdtar and bsdunzip, linked with the static library. libarchive finds by trial builds which macros zlib,
-- bzip2 and liblzma need; Expat and libxml2, static only here, get XML_STATIC or LIBXML_STATIC from a file CMake includes
-- after project(). What it installs: archive.lib, a static archive, or the import library with archive.dll (and
-- archive_static.lib beside them, which is not returned).

-- A static libcrypto calls Windows libraries (the `link` of the OpenSSL recipe, Configure's ex_libs of the VC- targets),
-- which libarchive's CMake does not give with it: its checks of PBKDF2 and the digests would fail to link and leave
-- encryption and the digests out, and bsdtar would not link. Every use of the OpenSSL libraries gets them.
local openssl_system_libraries = "ws2_32;crypt32;advapi32;user32;gdi32"

local function patch_static_openssl()
    local text = otok.read("CMakeLists.txt")
    local total = 0
    for _, variable in ipairs{ "OPENSSL_CRYPTO_LIBRARY", "OPENSSL_LIBRARIES" } do
        local count
        text, count = text:gsub("%${" .. variable .. "}", "${" .. variable .. "};" .. openssl_system_libraries)
        total = total + count
    end
    if total < 4 then error("libarchive's CMakeLists.txt has fewer uses of the OpenSSL libraries than expected") end
    otok.write("CMakeLists.txt", text)
end

-- libarchive's CMake takes libxml2 only with iconv, for headers of a libxml2 built with it; the libxml2 recipe for Windows
-- builds without iconv, and libarchive converts with the Windows API here, so the condition goes.
local function patch_libxml2_without_iconv()
    local text, count = otok.read("CMakeLists.txt"):gsub("IF%(ENABLE_LIBXML2 AND HAVE_ICONV%)", "IF(ENABLE_LIBXML2)", 1)
    if count ~= 1 then error("libarchive's CMakeLists.txt has no libxml2 condition of the expected form") end
    otok.write("CMakeLists.txt", text)
end

function build(slice, options, deps)
    local static = slice.linkage == "static"
    local defines = {
        ENABLE_TEST = false, ENABLE_WERROR = false, ENABLE_COVERAGE = false, ENABLE_INSTALL = true,
        ENABLE_TAR = slice.is_tool, ENABLE_UNZIP = slice.is_tool, ENABLE_CPIO = false, ENABLE_CAT = false,
        ENABLE_ZLIB = options.zlib, ENABLE_BZip2 = options.bzip2, ENABLE_LZMA = options.lzma, ENABLE_LZ4 = options.lz4,
        ENABLE_ZSTD = options.zstd, ENABLE_LIBB2 = false, ENABLE_LZO = false, ENABLE_MD = false, ENABLE_BSDXML = false,
        ENABLE_EXPAT = options.xml == "expat", ENABLE_LIBXML2 = options.xml == "libxml2",
        ENABLE_WIN32_XMLLITE = options.xml == "xmllite",
        ENABLE_CNG = options.crypto == "cng", ENABLE_OPENSSL = options.crypto == "openssl", ENABLE_MBEDTLS = false,
        ENABLE_NETTLE = false, ENABLE_PCREPOSIX = false, ENABLE_PCRE2POSIX = false, ENABLE_LIBGCC = false,
        ENABLE_ACL = false, ENABLE_XATTR = false, ENABLE_ICONV = false, MSVC_USE_STATIC_CRT = false,
        POSIX_REGEX_LIB = "NONE",
    }
    if options.zlib then
        defines.ZLIB_USE_STATIC_LIBS = deps.zlib.linkage == "static"
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
    local static_define -- the macro a static XML library needs, for the whole build
    if options.xml == "expat" then
        defines.EXPAT_INCLUDE_DIR = deps.expat.include
        defines.EXPAT_LIBRARY = deps.expat.libraries.expat
        if deps.expat.linkage == "static" then static_define = "XML_STATIC" end
    elseif options.xml == "libxml2" then
        defines.LIBXML2_INCLUDE_DIR = deps.libxml2.include
        defines.LIBXML2_LIBRARY = deps.libxml2.libraries.xml2
        patch_libxml2_without_iconv()
        -- libarchive's trial of LIBXML_STATIC only compiles, so it never finds that a static libxml2 needs it
        if deps.libxml2.linkage == "static" then static_define = "LIBXML_STATIC" end
    end
    if static_define then
        local include = slice.build .. "/otok-project-include.cmake"
        otok.write(include, "add_compile_definitions(" .. static_define .. ")\n")
        defines.CMAKE_PROJECT_INCLUDE = include
    end
    if options.crypto == "openssl" then
        local ssl = deps.openssl
        defines.OPENSSL_ROOT_DIR = ssl.prefix
        defines.OPENSSL_USE_STATIC_LIBS = ssl.linkage == "static"
        defines.OPENSSL_INCLUDE_DIR = ssl.include
        defines.OPENSSL_CRYPTO_LIBRARY = ssl.libraries.crypto
        defines.OPENSSL_SSL_LIBRARY = ssl.libraries.ssl
        if ssl.linkage == "static" then patch_static_openssl() end
    end
    otok.cmake{ defines = defines }
    local p = slice.prefix
    local headers = p .. "/include"
    if static then
        -- archive.h and archive_entry.h declare the functions dllimport unless LIBARCHIVE_STATIC is defined, which only
        -- libarchive's own build defines: the headers of a static library say it themselves
        for _, name in ipairs{ "archive.h", "archive_entry.h" } do
            local path = headers .. "/" .. name
            local text, count = otok.read(path):gsub("(#if %(%(defined __WIN32__%) || %(defined _WIN32%) || defined%(__CYGWIN__%)%) && %(!defined LIBARCHIVE_STATIC%))",
                "#ifndef LIBARCHIVE_STATIC\n#define LIBARCHIVE_STATIC\n#endif\n%1", 1)
            if count ~= 1 then error(name .. " has no LIBARCHIVE_STATIC test of the expected form") end
            otok.write(path, text)
        end
    end
    local out = { headers = headers }
    if static then
        out.libraries = { archive = otok.glob("lib/archive.lib", p)[1] }
    else
        out.libraries = { archive = { link = otok.glob("lib/archive.lib", p)[1], runtime = otok.glob("bin/archive.dll", p)[1] } }
    end
    if slice.is_tool then out.programs = { bsdtar = p .. "/bin/bsdtar.exe", bsdunzip = p .. "/bin/bsdunzip.exe" } end
    return out
end
