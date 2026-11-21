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
    -- lzma.h declares its functions dllimport unless LZMA_API_STATIC is defined, which liblzma's own build adds for a
    -- static library to the pkg-config file and the CMake package only; the header of a static build says it itself
    -- (found by otok-dev/examples lzma/basic)
    local header = p .. "/include/lzma.h"
    local text, count = otok.read(header):gsub("(#ifndef LZMA_API_IMPORT)", "#ifndef LZMA_API_STATIC\n#define LZMA_API_STATIC\n#endif\n\n%1", 1)
    if count ~= 1 then error("lzma.h has no LZMA_API_IMPORT definition of the expected form") end
    otok.write(header, text)
    return { libraries = { lzma = lib }, headers = p .. "/include" }
end
