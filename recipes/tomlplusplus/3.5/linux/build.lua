-- toml++: its headers (include/toml++), or with the option `compiled` the library of src/toml.cpp through the
-- recipe's CMakeLists.txt. The headers of a compiled toml++ state TOML_HEADER_ONLY 0 (and TOML_SHARED_LIB 1 for a
-- shared library) themselves, in toml++/impl/preprocessor.hpp, so that every consumer compiles with the configuration
-- the library was built with, also C++ on Apple, which the defines of a product do not reach without modules.
function build(slice, options, deps)
    local p = slice.prefix
    if not options.compiled then
        otok.copy(slice.source .. "/include/toml++", p .. "/include/toml++")
        return { libraries = {}, headers = p .. "/include" }
    end
    otok.copy(slice.recipe .. "/CMakeLists.txt", slice.source .. "/CMakeLists.txt")
    otok.cmake{}
    local config = "#ifndef TOML_HEADER_ONLY\n#define TOML_HEADER_ONLY 0\n#endif\n"
    if slice.linkage == "dynamic" then config = config .. "#ifndef TOML_SHARED_LIB\n#define TOML_SHARED_LIB 1\n#endif\n" end
    local header = p .. "/include/toml++/impl/preprocessor.hpp"
    local text, n = otok.read(header):gsub("#pragma once\r?\n", "#pragma once\n\n// otok: toml++ compiled as a library\n" .. config, 1)
    if n ~= 1 then error("no #pragma once in " .. header) end
    otok.write(header, text)
    local lib = otok.glob(slice.linkage == "static" and "lib/libtomlplusplus.a" or "lib/libtomlplusplus.so", p)[1]
    return { libraries = { tomlplusplus = lib }, headers = p .. "/include" }
end
