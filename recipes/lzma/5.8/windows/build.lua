-- The CMake project without its command line tools, translations and documentation: lzma.lib, or
-- lzma.lib with liblzma.dll.
function build(slice, options, deps)
    otok.cmake{
        defines = {
            XZ_NLS = false, XZ_DOC = false, XZ_SANDBOX = "no",
            XZ_TOOL_XZ = false, XZ_TOOL_XZDEC = false, XZ_TOOL_LZMADEC = false, XZ_TOOL_LZMAINFO = false, XZ_TOOL_SCRIPTS = false,
        },
    }
    local p = slice.prefix
    local lib = otok.glob("lib/*lzma*.lib", p)[1]
    local dll = otok.glob("bin/*lzma*.dll", p)[1]
    if dll then return { libraries = { lzma = { link = lib, runtime = dll } }, headers = p .. "/include" } end
    return { libraries = { lzma = lib }, headers = p .. "/include" }
end
