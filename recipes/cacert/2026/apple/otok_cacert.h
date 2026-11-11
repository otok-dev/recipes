/* The CA certificates of Mozilla, as the otok recipe `cacert` delivers them. */
#ifndef OTOK_CACERT_H
#define OTOK_CACERT_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* The bundle, PEM, as the library holds it (the option `data` = static): a NUL-terminated string of otok_cacert_pem_size()
   bytes, for CURLOPT_CAINFO_BLOB, mbedtls_x509_crt_parse, X509_STORE and the like. With `data` = file the library holds
   no bundle: the pointer is NULL and the size 0, and the bundle is data/cacert.pem of the output. */
const char* otok_cacert_pem(void);
size_t otok_cacert_pem_size(void);

#ifdef __cplusplus
}
#endif

#endif
