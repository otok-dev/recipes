/* <sys/wait.h> for building flex on Windows (the otok recipe apotocki/flex): its configure asks for the header; flex
 * waits for no child there, its filters running one after the other (the recipe's patch). */
#ifndef OTOK_FLEX_SYS_WAIT_H
#define OTOK_FLEX_SYS_WAIT_H
#endif
