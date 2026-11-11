-- libjpeg-turbo's CMake project, the libraries only (no tools, no tests, no Java). What it installs: libjpeg and libturbojpeg,
-- .a or .dylib with their links.
-- libjpeg-turbo sets CMAKE_INSTALL_RPATH to the install directory of the shared libraries itself, which would lead into otok's
-- directories: not that, the one the helper gives (the toolchain file's).
function build(slice, options, deps)
    local file = slice.source .. "/CMakeLists.txt"
    otok.write(file, (otok.read(file):gsub("set%(CMAKE_INSTALL_RPATH %${CMAKE_INSTALL_FULL_LIBDIR}%)", "")))
    local static = slice.linkage == "static"
    local turbo = options.api == "turbojpeg"
    otok.cmake{ defines = {
        ENABLE_STATIC = static, ENABLE_SHARED = not static, WITH_TURBOJPEG = turbo, WITH_TOOLS = false,
        WITH_TESTS = false, CMAKE_INSTALL_LIBDIR = "lib", CMAKE_ASM_NASM_COMPILER = slice.toolchains.nasm,
    } }
    local p = slice.prefix
    local libraries = {}
    local name = turbo and "turbojpeg" or "jpeg"
    libraries[name] = otok.glob(static and "lib/lib" .. name .. ".a" or "lib/lib" .. name .. ".dylib", p)[1]
    return { libraries = libraries, headers = p .. "/include" }
end
