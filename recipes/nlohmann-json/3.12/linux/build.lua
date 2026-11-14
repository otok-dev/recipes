-- nlohmann/json: its headers (include/nlohmann, the multiple headers its CMake installs by default). The options that
-- upstream's CMake turns into compile definitions of its interface target are written into the headers instead, at the
-- top of nlohmann/detail/abi_macros.hpp, which every public header reaches before any of these macros is read, so that
-- every consumer compiles with them, also C++ on Apple, which the defines of a product do not reach without modules.
-- A consumer's own definition still wins, as with upstream's defaults.
local function define(name, value)
    return "#ifndef " .. name .. "\n#define " .. name .. " " .. value .. "\n#endif\n"
end

function build(slice, options, deps)
    local p = slice.prefix
    otok.copy(slice.source .. "/include/nlohmann", p .. "/include/nlohmann")
    local config = ""
    if options.diagnostics then config = config .. define("JSON_DIAGNOSTICS", "1") end
    if options["diagnostic-positions"] then config = config .. define("JSON_DIAGNOSTIC_POSITIONS", "1") end
    if not options["implicit-conversions"] then config = config .. define("JSON_USE_IMPLICIT_CONVERSIONS", "0") end
    if not options["global-udls"] then config = config .. define("JSON_USE_GLOBAL_UDLS", "0") end
    if options["disable-enum-serialization"] then config = config .. define("JSON_DISABLE_ENUM_SERIALIZATION", "1") end
    if options["legacy-discarded-value-comparison"] then
        config = config .. define("JSON_USE_LEGACY_DISCARDED_VALUE_COMPARISON", "1")
    end
    if config ~= "" then
        local header = p .. "/include/nlohmann/detail/abi_macros.hpp"
        local text, n = otok.read(header):gsub("#pragma once\r?\n", "#pragma once\n\n// otok: the recipe's options\n" .. config, 1)
        if n ~= 1 then error("no #pragma once in " .. header) end
        otok.write(header, text)
    end
    return { libraries = {}, headers = p .. "/include" }
end
