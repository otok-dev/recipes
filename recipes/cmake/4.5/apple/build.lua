-- The release binaries, copied whole into the prefix from CMake.app/Contents: cmake finds its modules (share/cmake-4.4)
-- beside its bin/.
function build(slice, options, deps)
    local release = slice.resources.macos .. "/CMake.app/Contents"
    local p = slice.prefix
    for _, dir in ipairs{ "bin", "share" } do
        otok.copy(release .. "/" .. dir, p .. "/" .. dir)
    end
    return { programs = { cmake = p .. "/bin/cmake", ctest = p .. "/bin/ctest", cpack = p .. "/bin/cpack" } }
end
