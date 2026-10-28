-- The CMake project with gmock, without its own tests: libgtest.a, libgtest_main.a, libgmock.a,
-- libgmock_main.a, or gtest.lib and the others with MSVC, and one include/ with gtest/ and gmock/.
function build(slice, options, deps)
    otok.cmake{
        -- otok's flags choose the MSVC runtime (/MD): gtest would otherwise pick /MT
        defines = { BUILD_GMOCK = true, INSTALL_GTEST = true, gtest_force_shared_crt = true },
    }
    local p = slice.prefix
    local libraries = {}
    for _, name in ipairs{ "gtest", "gtest_main", "gmock", "gmock_main" } do
        libraries[name] = otok.glob("lib/lib" .. name .. ".a", p)[1] or otok.glob("lib/" .. name .. ".lib", p)[1]
            or otok.glob("lib/" .. name .. "d.lib", p)[1]
    end
    return { libraries = libraries, headers = p .. "/include" }
end
