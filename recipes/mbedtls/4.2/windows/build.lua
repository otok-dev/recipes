-- Mbed TLS's CMake project, the libraries only, with the default configuration (include/mbedtls/mbedtls_config.h and
-- TF-PSA-Crypto's include/psa/crypto_config.h). Python, which the project looks for only to check the configuration,
-- is not looked for: nothing of the machine.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = {
        ENABLE_PROGRAMS = false, ENABLE_TESTING = false, GEN_FILES = false,
        MBEDTLS_FATAL_WARNINGS = false, TF_PSA_CRYPTO_FATAL_WARNINGS = false,
        USE_STATIC_MBEDTLS_LIBRARY = static, USE_SHARED_MBEDTLS_LIBRARY = not static,
        USE_STATIC_TF_PSA_CRYPTO_LIBRARY = static, USE_SHARED_TF_PSA_CRYPTO_LIBRARY = not static,
        CMAKE_DISABLE_FIND_PACKAGE_Python3 = true,
    } }
    local p = slice.prefix
    -- tfpsacrypto.lib, mbedx509.lib, mbedtls.lib
    local lib = function(name) return p .. "/lib/" .. name .. ".lib" end
    return {
        libraries = { mbedtls = lib("mbedtls"), mbedx509 = lib("mbedx509"), tfpsacrypto = lib("tfpsacrypto") },
        headers = p .. "/include",
    }
end
