-- libpsl's meson build, the library only (no tests, no documentation), static, with the built-in list and no IDNA library.
-- What it installs: libpsl.a or psl.lib, whichever the toolchain names a static library (MSVC's: libpsl.a).
function build(slice, options, deps)
    otok.meson{ options = { runtime = "no", builtin = true, tests = false, docs = false } }
    local p = slice.prefix
    -- libpsl.h declares its functions dllimport unless PSL_STATIC is defined, which libpsl's own build adds for static
    -- libraries to the pkg-config file only; this recipe builds nothing else, so the header says it itself
    local header = p .. "/include/libpsl.h"
    local text, count = otok.read(header):gsub("(#ifndef PSL_API)", "#ifndef PSL_STATIC\n#define PSL_STATIC\n#endif\n\n%1", 1)
    if count ~= 1 then error("libpsl.h has no PSL_API definition of the expected form") end
    otok.write(header, text)
    local lib = otok.glob("lib/psl.lib", p)[1] or otok.glob("lib/libpsl.a", p)[1]
    return { libraries = { psl = lib }, headers = p .. "/include" }
end
