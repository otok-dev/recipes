/* The <unistd.h> flex needs from MSVC's C library, for building flex on Windows (the otok recipe apotocki/flex):
 * isatty, fileno, dup, dup2, close and unlink of <io.h>; its scanner scan.c includes it too. */
#ifndef OTOK_FLEX_UNISTD_H
#define OTOK_FLEX_UNISTD_H
#include <io.h>
#include <process.h>
#endif
