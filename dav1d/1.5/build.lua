-- dav1d's meson build, the library only. otok builds are meson's "plain" build type
-- (build-lua-api.md 6.2), so trim_dsp, which follows the build type, follows the configuration here.
function build(slice, options, deps)
    otok.meson{ options = {
        enable_tools = false, enable_tests = false, enable_examples = false, enable_docs = false,
        trim_dsp = slice.configuration == "release",
        -- the AArch64 assembly assumes 64-bit pointers: the structure offsets it checks differ on arm64_32
        enable_asm = slice.arch ~= "arm64_32",
    } }
    local p = slice.prefix
    local dll = otok.glob("bin/*dav1d*.dll", p)[1]
    if dll then
        return { libraries = { dav1d = { link = otok.glob("lib/*dav1d*.lib", p)[1], runtime = dll } }, headers = p .. "/include" }
    end
    local lib = otok.glob("lib/libdav1d.so", p)[1] or otok.glob("lib/libdav1d.dylib", p)[1] or otok.glob("lib/libdav1d.a", p)[1]
        or otok.glob("lib/*dav1d*.lib", p)[1]
    return { libraries = { dav1d = lib }, headers = p .. "/include" }
end
