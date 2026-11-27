-- nginx's configure and make in the source tree, then `make install` into slice.prefix as DESTDIR: the output is the tree
-- the server gets, `<prefix>/sbin/nginx` and the rest where the paths of the options put them.

-- the settings of configure the option `settings` may give, and whether the value is a path
local settings = {
    ["sbin-path"] = true, ["modules-path"] = true, ["conf-path"] = true, ["error-log-path"] = true, ["pid-path"] = true,
    ["lock-path"] = true, ["http-log-path"] = true, ["http-client-body-temp-path"] = true, ["http-proxy-temp-path"] = true,
    ["http-fastcgi-temp-path"] = true, ["http-uwsgi-temp-path"] = true, ["http-scgi-temp-path"] = true,
    user = false, group = false,
}

-- the parts of the option `modules` that configure names without `_module`
local plain = { mail = true, stream = true, threads = true, compat = true }

local function check_path(name, value)
    if value:sub(1, 1) ~= "/" or value:find("%.%.") or value:find("[%s'\"\\$`]") then
        error("the " .. name .. " '" .. value .. "' is not an absolute path without spaces, quotes or '..'")
    end
end

-- configure finds crypt() and crypt_r() in the C library, or with -lcrypt in libxcrypt's libcrypt.so.1 (auto/unix,
-- auto/os/linux): without the option `crypt` it is not given -lcrypt, so the program loads the C library alone (on glibc
-- auth_basic then has nginx's own hashes; musl's crypt() is in its C library)
local function without_libcrypt(source)
    for _, file in ipairs{ "auto/unix", "auto/os/linux" } do
        local path = source .. "/" .. file
        local text, libs = otok.read(path):gsub("ngx_feature_libs=%-lcrypt\n", "ngx_feature_libs=\n")
        local set
        text, set = text:gsub('CRYPT_LIB="%-lcrypt"', 'CRYPT_LIB=')
        if libs ~= 1 or set ~= 1 then error(file .. " does not look for crypt in -lcrypt as this recipe knows") end
        otok.write(path, text)
    end
end

function build(slice, options, deps)
    local p = slice.prefix
    check_path("prefix", options.prefix)
    if not options.crypt then without_libcrypt(slice.source) end
    local configure = { "sh", "./configure", "--prefix=" .. options.prefix }
    local sbin = options.prefix .. "/sbin/nginx"
    for _, setting in ipairs(options.settings) do
        local name, value = setting:match("^([%w-]+)=(.+)$")
        if not name or settings[name] == nil then error("'" .. setting .. "' in the option settings is not '<name>=<value>' of a known name") end
        if settings[name] then check_path(name, value) elseif not value:match("^[%w_.-]+$") then
            error("the " .. name .. " '" .. value .. "' is not a name")
        end
        if name == "sbin-path" then sbin = value end
        table.insert(configure, "--" .. name .. "=" .. value)
    end

    for _, module in ipairs(options.modules) do
        table.insert(configure, plain[module] and ("--with-" .. module) or ("--with-" .. module .. "_module"))
    end
    table.insert(configure, "--with-pcre")
    table.insert(configure, "--with-pcre-jit")
    if options.brotli then
        -- ngx_brotli looks for Brotli's headers in its submodule, deps/brotli/c/include, and links -lbrotlienc
        -- -lbrotlicommon: the headers of the dependency are put there, the libraries are found through --with-ld-opt
        otok.copy(deps.brotli.include, slice.source .. "/modules/ngx_brotli/deps/brotli/c/include")
        table.insert(configure, "--add-module=modules/ngx_brotli")
    end
    if options["headers-more"] then table.insert(configure, "--add-module=modules/headers-more") end

    -- the compiler and the flags of the slice, then the dependencies; nginx adds its own -O before them
    local cflags, ldflags = {}, {}
    for _, f in ipairs(slice.toolchain.cflags) do table.insert(cflags, f) end
    for _, f in ipairs(slice.toolchain.ldflags) do table.insert(ldflags, f) end
    for _, name in ipairs{ "openssl", "zlib", "pcre2", "brotli" } do
        local dep = deps[name]
        if dep then
            table.insert(cflags, "-I" .. dep.include)
            for _, dir in ipairs(dep.lib_dirs) do table.insert(ldflags, "-L" .. dir) end
        end
    end
    -- what `nginx -V` shows as the configure arguments: those above, not the compiler and the flags, which name the
    -- directories of this build and of otok's cache
    local shown = table.concat(configure, " ", 3)
    table.insert(configure, "--with-cc=" .. slice.toolchain.cc)
    table.insert(configure, "--with-cc-opt=" .. table.concat(cflags, " "))
    table.insert(configure, "--with-ld-opt=" .. table.concat(ldflags, " "))

    -- the flags only as configure is given them, not a second time from the environment
    local env = { CFLAGS = false, CXXFLAGS = false, CPPFLAGS = false, LDFLAGS = false }
    otok.run(configure, { env = env })
    local config_h = slice.source .. "/objs/ngx_auto_config.h"
    local text, found = otok.read(config_h):gsub('#define NGX_CONFIGURE "[^\n]*"', function()
        return '#define NGX_CONFIGURE " ' .. shown .. '"'
    end)
    if found ~= 1 then error("NGX_CONFIGURE is not defined once in objs/ngx_auto_config.h") end
    otok.write(config_h, text)
    -- configure goes on without crypt() when it finds none: the option asks for it
    if options.crypt and not text:find("#define NGX_HAVE_GNU_CRYPT_R", 1, true) and not text:find("#define NGX_HAVE_CRYPT ", 1, true) then
        error("the option crypt needs crypt() of libcrypt, which configure did not find: install the headers of libxcrypt (libcrypt-dev)")
    end
    otok.make{ env = env }
    otok.make{ "install", args = { "DESTDIR=" .. p }, env = env }
    return { programs = { nginx = p .. sbin } }
end
