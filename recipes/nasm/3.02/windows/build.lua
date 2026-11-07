-- nmake with nasm's Mkfiles/msvc.mak, cl of Visual Studio's environment; the generated sources are in the archive, and
-- without perl the makefile leaves them as they are. nmake takes no MAKEFLAGS of make (the jobserver's).
function build(slice, options, deps)
    -- nasmlib/file.c includes <stringapiset.h> without <windows.h>, whose winnt.h then knows no architecture: CL, which cl
    -- adds to its command lines, names it
    local machine = slice.arch == "arm64" and "_ARM64_" or "_AMD64_"
    otok.run({ "nmake", "/nologo", "/f", "Mkfiles/msvc.mak", "nasm.exe" },
        { cwd = slice.source, env = { MAKEFLAGS = false, MFLAGS = false, CL = "/D" .. machine } })
    local program = slice.prefix .. "/bin/nasm.exe"
    otok.copy(slice.source .. "/nasm.exe", program)
    return { programs = { nasm = program } }
end
