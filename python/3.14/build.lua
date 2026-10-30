-- The interpreter of the build machine, copied whole into the prefix: the embeddable package (python.exe beside its
-- python314.zip and DLLs) into bin/; a python-build-standalone build as it is laid out, bin/python3 beside lib/python3.14.
function build(slice, options, deps)
    local r = slice.resources
    local p = slice.prefix
    local embeddable = r.windows_x86_64 or r.windows_arm64
    if embeddable then
        otok.copy(embeddable, p .. "/bin")
        return { programs = { python = p .. "/bin/python.exe" } }
    end
    local standalone = r.macos_arm64 or r.macos_x86_64 or r.linux_x86_64 or r.linux_arm64
    if not standalone then error("no prebuilt Python for this build machine") end
    for _, dir in ipairs{ "bin", "lib" } do
        otok.copy(standalone .. "/" .. dir, p .. "/" .. dir)
    end
    return { programs = { python = p .. "/bin/python3" } }
end
