-- dav1d's meson build, the library only. otok builds are meson's "plain" build type
-- (build-lua-api.md 6.2), so trim_dsp, which follows the build type, follows the configuration here.
function build(slice, options, deps)
    otok.meson{ options = {
        enable_tools = false, enable_tests = false, enable_examples = false, enable_docs = false,
        trim_dsp = slice.configuration == "release",
    } }
    local p = slice.prefix
    local lib = otok.glob(slice.linkage == "static" and "lib/libdav1d.a" or "lib/libdav1d.so", p)[1]
    return { libraries = { dav1d = lib }, headers = p .. "/include" }
end
