-- The interpreter of the build machine, a python-build-standalone build copied as it is laid out: bin/python3 beside
-- lib/python3.14.
function build(slice, options, deps)
    local r = slice.resources
    local standalone = r.macos_arm64 or r.macos_x86_64
    if not standalone then error("no prebuilt Python for this build machine") end
    for _, dir in ipairs{ "bin", "lib" } do
        otok.copy(standalone .. "/" .. dir, slice.prefix .. "/" .. dir)
    end
    return { programs = { python = slice.prefix .. "/bin/python3" } }
end
