-- winflexbison's CMake project, its win_bison only. Its cmake_minimum_required(3.0) is below what CMake 4 accepts, hence
-- CMAKE_POLICY_VERSION_MINIMUM; it puts its programs in bin/<configuration> of the source, not in the build directory,
-- and installs them with the rest of its package flat into the prefix: the program is copied instead, with data/, the
-- skeletons, which win_bison finds beside itself (GetModuleFileNameA: an ANSI path).
function build(slice, options, deps)
    otok.cmake{ defines = { CMAKE_POLICY_VERSION_MINIMUM = "3.5" }, targets = { "win_bison" }, install = false }
    local built = otok.glob("bin/**/win_bison.exe", slice.source)
    if #built ~= 1 then error("win_bison.exe not found once in bin/ of the source (" .. #built .. " found)") end
    local program = slice.prefix .. "/bin/win_bison.exe"
    otok.copy(built[1], program)
    otok.copy(slice.source .. "/bison/data", slice.prefix .. "/bin/data")
    return { programs = { bison = program } }
end
