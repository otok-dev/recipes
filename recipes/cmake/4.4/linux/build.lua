-- The release binaries of the build machine, copied whole into the prefix: cmake finds its modules (share/cmake-4.4)
-- beside its bin/. Kitware's are for glibc: on a machine of musl (no resource active) CMake is built from source, by
-- its bootstrap with the Ninja of the toolchain (MAKE), without OpenSSL (a build tool here: the builds run offline).
function build(slice, options, deps)
    local r = slice.resources
    local release = r.linux_x86_64 or r.linux_arm64
    local p = slice.prefix
    if release then
        for _, dir in ipairs{ "bin", "share" } do
            otok.copy(release .. "/" .. dir, p .. "/" .. dir)
        end
    else
        local ninja = slice.toolchains.ninja
        otok.run({ slice.source .. "/bootstrap", "--prefix=" .. p, "--generator=Ninja", "--parallel=" .. slice.jobs, "--",
                   "-DCMAKE_USE_OPENSSL=OFF", "-DBUILD_TESTING=OFF", "-DCMAKE_BUILD_TYPE=Release" },
                 { cwd = slice.build, env = { MAKE = ninja, CC = slice.toolchain.cc, CXX = slice.toolchain.cxx } })
        otok.run({ ninja, "install" }, { cwd = slice.build })
    end
    return { programs = { cmake = p .. "/bin/cmake", ctest = p .. "/bin/ctest", cpack = p .. "/bin/cpack" } }
end
