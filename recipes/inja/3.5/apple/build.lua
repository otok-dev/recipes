-- inja: its headers (include/inja, the multiple headers its CMake installs by default), without the copy of
-- nlohmann/json in third_party/: inja's headers include <nlohmann/json.hpp>, which the dependency gives.
function build(slice, options, deps)
    local p = slice.prefix
    otok.copy(slice.source .. "/include/inja", p .. "/include/inja")
    return { libraries = {}, headers = p .. "/include" }
end
