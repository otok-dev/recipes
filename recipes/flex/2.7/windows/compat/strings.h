/* The <strings.h> flex needs from MSVC's C library, for building flex on Windows (the otok recipe apotocki/flex). */
#ifndef OTOK_FLEX_STRINGS_H
#define OTOK_FLEX_STRINGS_H
#include <string.h>
#define strcasecmp _stricmp
#define strncasecmp _strnicmp
#endif
