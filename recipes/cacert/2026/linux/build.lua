-- The bundle, made from certdata.txt by curl's mk-ca-bundle.pl (-n: nothing is downloaded; the script takes certdata.txt
-- from the current directory), then libcacert through the recipe's CMakeLists.txt with cacert.c, which this writes: the bundle
-- as an array of bytes (MSVC limits a string literal to 64 KB) behind otok_cacert_pem(), or nothing for data = file.
-- What it installs: libcacert.a, or libcacert.so with its links.

-- The script puts the time of certdata.txt into its header, which is the time of the copy: the commit says which data it is.
-- A perl for Windows writes the line ends of Windows; the bundle is the same on every target.
local function bundle(slice)
    otok.copy(slice.resources.certdata, slice.build .. "/certdata.txt")
    otok.run({ slice.toolchains.perl, slice.source .. "/scripts/mk-ca-bundle.pl", "-n", "-q", "cacert.pem" }, { cwd = slice.build })
    local text = otok.read(slice.build .. "/cacert.pem"):gsub("\r\n", "\n")
    local count
    text, count = text:gsub("## Certificate data from Mozilla as of: [^\n]*",
        "## Certificate data from Mozilla, certdata.txt of the firefox commit 7ff62457dcf126523608e2f4b90d232d49d58185 (2026-10-21)", 1)
    if count ~= 1 then error("the bundle has no line telling when the data is from") end
    return text
end

local function source_of(text)
    local lines = { '#include "otok_cacert.h"', "" }
    if text then
        table.insert(lines, "static const unsigned char bundle[] = {")
        for i = 1, #text, 32 do table.insert(lines, table.concat({ text:byte(i, math.min(i + 31, #text)) }, ",") .. ",") end
        table.insert(lines, "0 };")
        table.insert(lines, "const char* otok_cacert_pem(void) { return (const char*)bundle; }")
        table.insert(lines, "size_t otok_cacert_pem_size(void) { return sizeof bundle - 1; }")
    else
        table.insert(lines, "const char* otok_cacert_pem(void) { return NULL; }")
        table.insert(lines, "size_t otok_cacert_pem_size(void) { return 0; }")
    end
    table.insert(lines, "")
    return table.concat(lines, "\n")
end

function build(slice, options, deps)
    local text = bundle(slice)
    local file = options.data == "file"
    otok.write(slice.source .. "/cacert.c", source_of(not file and text or nil))
    otok.copy(slice.recipe .. "/CMakeLists.txt", slice.source .. "/CMakeLists.txt")
    otok.copy(slice.recipe .. "/otok_cacert.h", slice.source .. "/otok_cacert.h")
    otok.cmake{}
    local p = slice.prefix
    local lib = otok.glob(slice.linkage == "static" and "lib/libcacert.a" or "lib/libcacert.so", p)[1]
    local result = { libraries = { cacert = lib }, headers = p .. "/include" }
    if file then
        otok.write(p .. "/share/cacert.pem", text)
        result.data = { ["cacert.pem"] = p .. "/share/cacert.pem" }
    end
    return result
end
