-- The CMake project with gmock, without its own tests: libgtest.a and libgmock.a (not the main libraries, see
-- recipe.toml), and one include/ with gtest/ and gmock/.
function build(slice, options, deps)
    otok.cmake{
        defines = { BUILD_GMOCK = true, INSTALL_GTEST = true },
    }
    local p = slice.prefix
    local libraries = {}
    for _, name in ipairs{ "gtest", "gmock" } do
        libraries[name] = p .. "/lib/lib" .. name .. ".a"
    end
    return { libraries = libraries, headers = p .. "/include" }
end
