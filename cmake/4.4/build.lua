-- The release binaries of the build machine, copied whole into the prefix: cmake finds its modules (share/cmake-4.4)
-- beside its bin/. On macOS they are in CMake.app/Contents.
function build(slice, options, deps)
    local r = slice.resources
    local release = r.windows_x86_64 or r.windows_arm64 or r.macos or r.linux_x86_64 or r.linux_arm64
    if not release then error("CMake publishes no release binaries for this build machine") end
    if r.macos then release = release .. "/CMake.app/Contents" end
    local p = slice.prefix
    for _, dir in ipairs{ "bin", "share" } do
        otok.copy(release .. "/" .. dir, p .. "/" .. dir)
    end
    local exe = (r.windows_x86_64 or r.windows_arm64) and ".exe" or ""
    return { programs = { cmake = p .. "/bin/cmake" .. exe, ctest = p .. "/bin/ctest" .. exe, cpack = p .. "/bin/cpack" .. exe } }
end
