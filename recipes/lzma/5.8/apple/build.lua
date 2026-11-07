-- The CMake project without its command line tools, translations and documentation: liblzma.a.
function build(slice, options, deps)
    otok.cmake{
        defines = {
            XZ_NLS = false, XZ_DOC = false, XZ_SANDBOX = "no",
            XZ_TOOL_XZ = false, XZ_TOOL_XZDEC = false, XZ_TOOL_LZMADEC = false, XZ_TOOL_LZMAINFO = false, XZ_TOOL_SCRIPTS = false,
        },
    }
    local p = slice.prefix
    return { libraries = { lzma = p .. "/lib/liblzma.a" }, headers = p .. "/include" }
end
