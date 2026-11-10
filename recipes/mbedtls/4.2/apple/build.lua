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
    -- the headers of Everest, the variant of X25519 the default configuration leaves out (MBEDTLS_ECDH_VARIANT_EVEREST_ENABLED):
    -- they are no part of the module of the product, whose headers each compile alone
    otok.remove(p .. "/include/tf-psa-crypto/private/everest")
    -- libtfpsacrypto.a or libtfpsacrypto.dylib, and so on
    local lib = function(name) return p .. "/lib/lib" .. name .. (static and ".a" or ".dylib") end
    return {
        libraries = { mbedtls = lib("mbedtls"), mbedx509 = lib("mbedx509"), tfpsacrypto = lib("tfpsacrypto") },
        headers = p .. "/include",
    }
end
