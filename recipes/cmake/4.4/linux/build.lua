-- The release binaries of the build machine, copied whole into the prefix: cmake finds its modules (share/cmake-4.4)
-- beside its bin/.
function build(slice, options, deps)
    local r = slice.resources
    local release = r.linux_x86_64 or r.linux_arm64
    if not release then error("CMake publishes no release binaries for this build machine") end
    local p = slice.prefix
    for _, dir in ipairs{ "bin", "share" } do
        otok.copy(release .. "/" .. dir, p .. "/" .. dir)
    end
    return { programs = { cmake = p .. "/bin/cmake", ctest = p .. "/bin/ctest", cpack = p .. "/bin/cpack" } }
end
