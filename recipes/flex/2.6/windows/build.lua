-- winflexbison's CMake project, its win_flex only. Its cmake_minimum_required(3.0) is below what CMake 4 accepts, hence
-- CMAKE_POLICY_VERSION_MINIMUM; it puts its programs in bin/<configuration> of the source, not in the build directory,
-- and installs them with the rest of its package flat into the prefix: the program is copied instead.
function build(slice, options, deps)
    otok.cmake{ defines = { CMAKE_POLICY_VERSION_MINIMUM = "3.5" }, targets = { "win_flex" }, install = false }
    local built = otok.glob("bin/**/win_flex.exe", slice.source)
    if #built ~= 1 then error("win_flex.exe not found once in bin/ of the source (" .. #built .. " found)") end
    local program = slice.prefix .. "/bin/win_flex.exe"
    otok.copy(built[1], program)
    -- the header of C++ scanners (%option c++), which they include
    otok.copy(slice.source .. "/flex/src/FlexLexer.h", slice.prefix .. "/include/FlexLexer.h")
    return { programs = { flex = program } }
end
