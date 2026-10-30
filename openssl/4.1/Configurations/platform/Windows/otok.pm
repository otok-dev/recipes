package platform::Windows::otok;

# The platform of the otok-windows targets of 60-otok.conf: the names of Windows::MSVC, the GNU
# assembler sources that the Unix makefile template assembles (.s, not nasm's or masm's .asm), and the
# answers of platform::Unix the template asks for: no dependency generator (the builds are configured with
# no-makedepend), no shared library names without the version.

use strict;
use warnings;

use vars qw(@ISA);

require platform::Windows::MSVC;
@ISA = qw(platform::Windows::MSVC);

sub asmext              { '.s' }
sub makedepcmd          { undef }
sub sharedlib_simple    { undef }

1;
