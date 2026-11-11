-- libjpeg-turbo's CMake project, the libraries only (no tools, no tests, no Java). What it installs: jpeg-static.lib and
-- turbojpeg-static.lib (static), or jpeg.lib with jpeg62.dll and turbojpeg.lib with turbojpeg.dll.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    local turbo = options.api == "turbojpeg"
    otok.cmake{ defines = {
        ENABLE_STATIC = static, ENABLE_SHARED = not static, WITH_TURBOJPEG = turbo, WITH_TOOLS = false,
        WITH_TESTS = false, WITH_CRT_DLL = true,
        CMAKE_ASM_NASM_COMPILER = slice.toolchains.nasm,
    } }
    local p = slice.prefix
    local libraries = {}
    if static then
        libraries[turbo and "turbojpeg" or "jpeg"] = otok.glob(turbo and "lib/turbojpeg-static.lib" or "lib/jpeg-static.lib", p)[1]
    elseif turbo then
        libraries.turbojpeg = { link = otok.glob("lib/turbojpeg.lib", p)[1], runtime = otok.glob("bin/turbojpeg.dll", p)[1] }
    else
        libraries.jpeg = { link = otok.glob("lib/jpeg.lib", p)[1], runtime = otok.glob("bin/jpeg*.dll", p)[1] }
    end
    return { libraries = libraries, headers = p .. "/include" }
end
