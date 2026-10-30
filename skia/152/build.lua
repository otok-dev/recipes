-- Skia's GN with the Visual Studio of the slice's environment and clang-cl and lld-link of the LLVM directory of the
-- toolchain clang-cl; ninja builds the target skia (skia.dll and skia.dll.lib, or skia.lib). The headers are published
-- as consumers include them: <skia/core/SkCanvas.h>, <skcms/skcms.h>.

local function gn_string(s)
    return '"' .. s:gsub("\\", "/"):gsub('"', '\\"') .. '"'
end

local function gn_list(values)
    local quoted = {}
    for _, v in ipairs(values) do table.insert(quoted, gn_string(v)) end
    return "[ " .. table.concat(quoted, ", ") .. " ]"
end

-- a directory of vcvars without its trailing separator
local function directory(path)
    return (path:gsub("[/\\]+$", ""))
end

-- the flags of otok and of the project Skia takes: the runtime, definitions, the C++ standard; GN chooses the rest
local function kept(flags, seen)
    local out = {}
    for _, f in ipairs(flags) do
        if (f:match("^[/-]M[DT]d?$") or f:match("^[/-]D") or f:match("^/std:")) and not seen[f] then
            seen[f] = true
            table.insert(out, f)
        end
    end
    return out
end

-- #include "include/core/…" → "skia/core/…", "modules/skcms/…" → "skcms/…"
local function publish_headers(from, to)
    for _, header in ipairs(otok.glob("**/*.h", from)) do
        local text = otok.read(header)
        text = text:gsub('#include "include/', '#include "skia/'):gsub('#include "modules/skcms/', '#include "skcms/')
        otok.write(to .. "/" .. header:sub(#from + 2), text)
    end
end

function build(slice, options, deps)
    local env = slice.toolchain.env
    for _, name in ipairs{ "VCINSTALLDIR", "VCToolsVersion", "WindowsSdkDir", "WindowsSDKVersion" } do
        if not env[name] then error("Skia builds for Windows only: the slice's environment has no " .. name .. " of Visual Studio") end
    end
    local llvm = slice.toolchains["clang-cl"]:gsub("\\", "/"):match("^(.*)/bin/[^/]*$")
    local debug = slice.configuration == "debug"
    local seen = {}
    local cflags = kept(slice.toolchain.cflags, seen)
    local cxxflags = kept(slice.toolchain.cxxflags, seen)

    local args = {
        "is_debug = " .. tostring(debug),
        "is_official_build = " .. tostring(not debug),
        "is_component_build = " .. tostring(slice.linkage == "dynamic"),
        "target_cpu = " .. gn_string(slice.arch == "x86_64" and "x64" or slice.arch),
        "win_vc = " .. gn_string(directory(env.VCINSTALLDIR)),
        "win_toolchain_version = " .. gn_string(env.VCToolsVersion),
        "win_sdk = " .. gn_string(directory(env.WindowsSdkDir)),
        "win_sdk_version = " .. gn_string(directory(env.WindowsSDKVersion)),
        "clang_win = " .. gn_string(llvm),
        "skia_use_egl = false",
        "skia_use_dawn = false",
        "skia_use_gl = false",
        "skia_use_direct3d = true",
        -- raw_ptr as a plain pointer: skia.dll would not load partition_alloc's DLLs anyway
        "skia_use_partition_alloc = false",
        -- debug builds would check SkSL's SPIR-V with spirv-tools: SPIR-V is Vulkan's, which this build has not
        "skia_enable_spirv_validation = false",
        "skia_enable_skshaper = true",
        "skia_enable_skparagraph = true",
        -- the libraries of third_party/externals, not the system's (Windows has none)
        "skia_use_system_expat = false",
        "skia_use_system_harfbuzz = false",
        "skia_use_system_libjpeg_turbo = false",
        "skia_use_system_libpng = false",
        "skia_use_system_libwebp = false",
        "skia_use_system_zlib = false",
        "extra_cflags = " .. gn_list(cflags),
        "extra_cflags_cc = " .. gn_list(cxxflags),
    }
    local out = slice.source .. "/out/otok"
    otok.write(out .. "/args.gn", table.concat(args, "\n") .. "\n")
    otok.run({ slice.toolchains.gn, "gen", "out/otok", "--script-executable=" .. slice.toolchains.python }, { cwd = slice.source })
    otok.run({ slice.toolchains.ninja, "-C", "out/otok", "skia" }, { cwd = slice.source })

    publish_headers(slice.source .. "/include", slice.prefix .. "/include/skia")
    for _, header in ipairs{ "skcms.h", "src/skcms_public.h" } do
        otok.copy(slice.source .. "/modules/skcms/" .. header, slice.prefix .. "/include/skcms/" .. header)
    end
    local skia
    if slice.linkage == "dynamic" then
        otok.copy(out .. "/skia.dll", slice.prefix .. "/bin/skia.dll")
        otok.copy(out .. "/skia.dll.lib", slice.prefix .. "/lib/skia.dll.lib")
        skia = { link = slice.prefix .. "/lib/skia.dll.lib", runtime = slice.prefix .. "/bin/skia.dll" }
    else
        otok.copy(out .. "/skia.lib", slice.prefix .. "/lib/skia.lib")
        skia = slice.prefix .. "/lib/skia.lib"
    end
    return { libraries = { skia = skia }, headers = slice.prefix .. "/include" }
end
