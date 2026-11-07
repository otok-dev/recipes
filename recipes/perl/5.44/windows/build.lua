-- win32/Makefile with nmake of Visual Studio, in the source tree, where it works. The architecture is the slice's, not
-- that of the environment's PROCESSOR_ARCHITECTURE; no settings of the registry (HKCU/HKLM\Software\Perl), and no
-- version directories in the prefix. nmake takes no MAKEFLAGS of make (the jobserver's). perl.exe finds its lib\ beside
-- its bin\, so the prefix may move.
function build(slice, options, deps)
    local prefix = slice.prefix:gsub("/", "\\")
    local args = { "nmake", "-nologo", "CCTYPE=MSVC145", "INST_TOP=" .. prefix, "INST_VER=", "INST_ARCH=",
        "USE_NO_REGISTRY=define", "PROCESSOR_ARCHITECTURE=" .. (slice.arch == "arm64" and "ARM64" or "AMD64") }
    local win32 = slice.source .. "/win32"
    local env = { MAKEFLAGS = false, MFLAGS = false }
    otok.run(args, { cwd = win32, env = env })
    table.insert(args, "install")
    otok.run(args, { cwd = win32, env = env })
    return { programs = { perl = slice.prefix .. "/bin/perl.exe" } }
end
