-- libjpeg-turbo's CMake project, the libraries only (no tools, no tests, no Java). What it installs: libjpeg and libturbojpeg,
-- .a or .so with their links.
-- libjpeg-turbo sets CMAKE_INSTALL_RPATH to the install directory of the shared libraries itself, which would lead into otok's
-- directories: not that, the one the helper gives (the toolchain file's).
-- PIC always: the assembly of x86 (i386) gets -DPIC only with it or ENABLE_SHARED, and a static libjpeg goes into an app's
-- shared object anyway (Android refuses text relocations; libjpeg-turbo links simdcoverage against the static library).
function build(slice, options, deps)
    local file = slice.source .. "/CMakeLists.txt"
    otok.write(file, (otok.read(file):gsub("set%(CMAKE_INSTALL_RPATH %${CMAKE_INSTALL_FULL_LIBDIR}%)", "")))
    local static = slice.linkage == "static"
    local turbo = options.api == "turbojpeg"
    otok.cmake{ defines = {
        ENABLE_STATIC = static, ENABLE_SHARED = not static, WITH_TURBOJPEG = turbo, WITH_TOOLS = false,
        WITH_TESTS = false, CMAKE_INSTALL_LIBDIR = "lib", CMAKE_ASM_NASM_COMPILER = slice.toolchains.nasm,
        CMAKE_POSITION_INDEPENDENT_CODE = true,
    } }
    local p = slice.prefix
    local libraries = {}
    local name = turbo and "turbojpeg" or "jpeg"
    libraries[name] = otok.glob(static and "lib/lib" .. name .. ".a" or "lib/lib" .. name .. ".so", p)[1]
    return { libraries = libraries, headers = p .. "/include" }
end
