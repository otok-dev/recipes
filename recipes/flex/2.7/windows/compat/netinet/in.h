/* <netinet/in.h> for building flex on Windows (the otok recipe apotocki/flex): htonl and htons for its tables files,
 * big-endian; Windows runs little-endian on every architecture. */
#ifndef OTOK_FLEX_NETINET_IN_H
#define OTOK_FLEX_NETINET_IN_H
#include <stdlib.h>
#define htonl(n) _byteswap_ulong(n)
#define htons(n) _byteswap_ushort(n)
#endif
