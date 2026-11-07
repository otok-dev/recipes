-- dav1d's meson build, the library only. otok builds are meson's "plain" build type
-- (build-lua-api.md 6.2), so trim_dsp, which follows the build type, follows the configuration here.
function build(slice, options, deps)
    local args = {}
    if slice.environment == "windows/msvc" and slice.arch == "arm64" then
        -- MSVC assembles arm64 with armasm64 through gas-preprocessor.pl, which meson.build finds as a program: a machine file
        -- of its own beside otok's names it, run by the perl of the recipe; a cross file when the build machine is not arm64
        local file = slice.build .. "/gas-preprocessor.ini"
        otok.write(file, "[binaries]\ngas-preprocessor.pl = ['" .. slice.toolchains.perl:gsub("\\", "/") .. "', '"
            .. slice.resources.gas_preprocessor:gsub("\\", "/") .. "']\n")
        local cross = slice.host:match("%-(.*)$") ~= slice.arch
        args[1] = (cross and "--cross-file=" or "--native-file=") .. file
    end
    otok.meson{ args = args, options = {
        enable_tools = false, enable_tests = false, enable_examples = false, enable_docs = false,
        trim_dsp = slice.configuration == "release",
    } }
    local p = slice.prefix
    -- meson names a static library libdav1d.a with MSVC too
    local lib = otok.glob("lib/dav1d.lib", p)[1] or otok.glob("lib/libdav1d.a", p)[1]
    local dll = otok.glob("bin/*dav1d*.dll", p)[1]
    if dll then return { libraries = { dav1d = { link = lib, runtime = dll } }, headers = p .. "/include" } end
    return { libraries = { dav1d = lib }, headers = p .. "/include" }
end
