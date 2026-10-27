-- The CMake project without its command line tools, translations and documentation: liblzma.a,
-- liblzma.so with its links, liblzma.dylib, or lzma.lib (with liblzma.dll) with MSVC.
function build(slice, options, deps)
    otok.cmake{
        defines = {
            XZ_NLS = false, XZ_DOC = false, XZ_SANDBOX = "no",
            XZ_TOOL_XZ = false, XZ_TOOL_XZDEC = false, XZ_TOOL_LZMADEC = false, XZ_TOOL_LZMAINFO = false, XZ_TOOL_SCRIPTS = false,
        },
    }
    local p = slice.prefix
    local dll = otok.glob("bin/*lzma*.dll", p)[1]
    if dll then
        return { libraries = { lzma = { link = otok.glob("lib/*lzma*.lib", p)[1], runtime = dll } }, headers = p .. "/include" }
    end
    local lib = otok.glob("lib/liblzma.so", p)[1] or otok.glob("lib/liblzma.dylib", p)[1] or otok.glob("lib/liblzma.a", p)[1]
        or otok.glob("lib/*lzma*.lib", p)[1]
    return { libraries = { lzma = lib }, headers = p .. "/include" }
end
