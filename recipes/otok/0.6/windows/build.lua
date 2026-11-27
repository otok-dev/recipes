-- otok's CMake project with the dependencies of the recipe. Its CMakeLists.txt finds them with find_package(), as it
-- finds vcpkg's: the recipe writes a package configuration file for each of them, which has CMake prefer them to its
-- find modules. They all include otok-deps.cmake, an imported target per library of the dependencies, each linking
-- what it needs. Detours is found by its header and library, given to CMake. otok's CMake project installs nothing:
-- otok.exe and otok-sandbox.dll, which otok injects into sandboxed builds, are copied from the build tree.

-- otok-deps.cmake from { name, library (nil: headers only), include, defines, links } in the order given
local function write_targets(dir, targets)
    local lines = { "# written by the otok recipe of otok", "include_guard(GLOBAL)" }
    for _, t in ipairs(targets) do
        lines[#lines + 1] = "add_library(" .. t.name .. (t.library and " STATIC" or " INTERFACE") .. " IMPORTED)"
        lines[#lines + 1] = "set_target_properties(" .. t.name .. " PROPERTIES"
        if t.library then lines[#lines + 1] = "    IMPORTED_LOCATION \"" .. t.library .. "\"" end
        if t.include then lines[#lines + 1] = "    INTERFACE_INCLUDE_DIRECTORIES \"" .. t.include .. "\"" end
        if t.defines then lines[#lines + 1] = "    INTERFACE_COMPILE_DEFINITIONS \"" .. table.concat(t.defines, ";") .. "\"" end
        if t.links then lines[#lines + 1] = "    INTERFACE_LINK_LIBRARIES \"" .. table.concat(t.links, ";") .. "\"" end
        lines[#lines + 1] = ")"
    end
    otok.write(dir .. "/otok-deps.cmake", table.concat(lines, "\n") .. "\n")
end

local function write_config(dir, package)
    otok.write(dir .. "/" .. package .. "Config.cmake", "# written by the otok recipe of otok\n" ..
        "include(${CMAKE_CURRENT_LIST_DIR}/otok-deps.cmake)\nset(" .. package .. "_FOUND TRUE)\n")
end

local function add(targets, name, dep, library, links, defines)
    targets[#targets + 1] = { name = name, library = library and dep.libraries[library], include = dep.include,
        links = links, defines = defines }
end

function build(slice, options, deps)
    local t = {}
    add(t, "tomlplusplus::tomlplusplus", deps.tomlplusplus, "tomlplusplus")
    add(t, "nlohmann_json::nlohmann_json", deps["nlohmann-json"])
    add(t, "pantor::inja", deps.inja, nil, { "nlohmann_json::nlohmann_json" })
    add(t, "otok_dep::z", deps.zlib, "z")
    add(t, "otok_dep::bz2", deps.bzip2, "bz2")
    add(t, "otok_dep::lzma", deps.lzma, "lzma")
    add(t, "otok_dep::lz4", deps.lz4, "lz4")
    add(t, "otok_dep::zstd", deps.zstd, "zstd")

    -- the defines and system libraries of the CURL product of the curl recipe, Schannel's among them
    add(t, "CURL::libcurl", deps.curl, "curl",
        { "otok_dep::z", "ws2_32", "bcrypt", "advapi32", "crypt32", "secur32", "iphlpapi" }, { "CURL_STATICLIB" })

    -- the headers of a static libarchive define LIBARCHIVE_STATIC themselves; CNG's bcrypt is linked whatever `crypto` is
    local archive = deps.libarchive.options
    local archive_links = {}
    for option, target in pairs{ zlib = "z", bzip2 = "bz2", lzma = "lzma", lz4 = "lz4", zstd = "zstd" } do
        if archive[option] then archive_links[#archive_links + 1] = "otok_dep::" .. target end
    end
    table.sort(archive_links)
    archive_links[#archive_links + 1] = "bcrypt"
    if archive.xml == "xmllite" then
        archive_links[#archive_links + 1] = "xmllite"
        archive_links[#archive_links + 1] = "uuid"
    end
    add(t, "LibArchive::LibArchive", deps.libarchive, "archive", archive_links)

    local dir = slice.build .. "/otok-packages"
    write_targets(dir, t)
    for _, package in ipairs{ "tomlplusplus", "nlohmann_json", "inja", "CURL", "LibArchive" } do write_config(dir, package) end

    otok.cmake{
        defines = {
            OTOK_BUILD_TESTS = false,
            OTOK_REVISION = "v" .. slice.version,
            CMAKE_FIND_PACKAGE_PREFER_CONFIG = true,
            tomlplusplus_DIR = dir, nlohmann_json_DIR = dir, inja_DIR = dir, CURL_DIR = dir, LibArchive_DIR = dir,
            OTOK_DETOURS_INCLUDE_DIR = deps.detours.include,
            OTOK_DETOURS_LIBRARY_RELEASE = deps.detours.libraries.detours,
        },
        targets = { "otok" },
        install = false,
    }

    local bin = slice.prefix .. "/bin"
    otok.copy(slice.build .. "/otok.exe", bin .. "/otok.exe")
    otok.copy(slice.build .. "/otok-sandbox.dll", bin .. "/otok-sandbox.dll")
    return { programs = { otok = bin .. "/otok.exe" } }
end
