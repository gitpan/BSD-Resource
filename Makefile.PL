#
# Makefile.PL
#
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#

require 5.001;

$PACKAGE = 'BSD::Resource';
$VERSION = 1.09;

use Config;
use ExtUtils::MakeMaker;
use File::Basename;

sub try_compile_and_link {
    my ($c, %opt) = @_;

    my ($ok) = 0;
    my ($tmp) = "tmp$$";
    local(*TMPC);

    unlink("$tmp.c", "$tmp.o");

    if (open(TMPC, ">$tmp.c")) {
	print TMPC $c;
	close(TMPC);
	my $cc = exists $ENV{CC} ? $ENV{CC} : $Config{'cc'};
	$cc = basename($cc) unless -x $cc;
	my $cccmd = "$cc -c -o $tmp.o $Config{'ccflags'} $tmp.c 2>/dev/null";
	if (system($cccmd) == 0) {
	    $ok = -s "$tmp.o";
	}
	unlink("$tmp.c", "$tmp.o");
    }
    
    $ok;
}

# This is unused for now.
sub try_cpp_and_grep {
    my ($c, %opt) = @_;

    my @g;
    my ($tmp) = "tmp$$";
    local(*TMPC);

    unlink("$tmp.c", "$tmp.o");

    if (open(TMPC, ">$tmp.c")) {
	print TMPC $c;
	close(TMPC);
	my $cc = $Config{'cc'};
	$cc = basename($cc) unless -x $cc;
	my $cccmd = "$cc -E $Config{'ccflags'} $tmp.c 2>/dev/null";
	local(*TMPE);
	if (open(TMPE, "$cccmd|")) {
	    while (<TMPE>) {
		push @g, /$opt{re}/g;
	    }
	    close(TMPE);
	}
	unlink("$tmp.c");
    }
    
    @g;
}

sub has_resource_h () {
    return 1 if
    try_compile_and_link(<<EOM);
#include <sys/resource.h>
static int foo;
EOM

    return 2 if
    try_compile_and_link(<<EOM);
#include <sys/types.h>
#include <sys/time.h> 
#include <sys/resource.h>
static int foo;
EOM

    # Solaris 1 weirdo header

    return 3 if
    try_compile_and_link(<<EOM);
#include <sys/rusage.h>
static int foo;
EOM

    return 0;
}

sub init {
    die <<EOM unless has_resource_h();
Your operating system does not seem to have <sys/resource.h> or <sys/rusage.h>.

There is no way $PACKAGE is going to work.

I am awfully sorry but I cannot go further.

Aborting configuration of $PACKAGE $VERSION.
EOM

    $DEFINE = '';

    # old Solarises had this oddity.
    $DEFINE .= ' -DI_SYS_RUSAGE' if (-r '/usr/include/sys/rusage.h');

    # ucb is poison for Solaris.
    $LIBS = $Config{'osname'} eq 'solaris' ? [''] : ['-lucb -lbsd'];
}

sub find_Rlim_t {
	my ($tmp) = "rlim$$";
	my ($worrynot) = 0;

	print "You seem ";
	my $has = try_compile_and_link(<<EOM);
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef I_SYS_TYPES
#include <sys/types.h>
#endif
#include <sys/resource.h>
static rlim_t foo = 0;
EOM
        if ($has) {
	    $DEFINE .= ' -DRlim_t=rlim_t';
	} else {
	    print "not ";
	    $worrynot = 1;
	}

	print "to have rlim_t defined (";
	print $worrynot ? "this is okay" : "which is nice";
	print ").\n\n";
}

sub configure {
    find_Rlim_t;
    if ($^O eq 'solaris' &&
	$Config{ccflags} =~ /-D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64/ &&
	$Config{use64bitall} ne 'define') {
	if (open(PROCFS, "/usr/include/sys/procfs.h")) {
	    my $noprocfs;
	    while (<PROCFS>) {
		if (/^#error.*Cannot use.*procfs.*large file.*/) {
		    $noprocfs = 1;
		    last;
		}
	    }
	    close(PROCFS);
	    if ($noprocfs) {
		$DEFINE .= ' -DSOLARIS_NO_PROCFS';
	    }
	}
    }
}

sub doMakefile {
    print  <<EOM if ($$LIBS[0] ne '');
Looking for libraries...
Note: it is ok if none of the libraries '@$LIBS' is found.

EOM
    WriteMakefile(
    'NAME'	=> $PACKAGE,
    'VERSION'	=> $VERSION,
    'LIBS'	=> $LIBS,
    'DEFINE'	=> $DEFINE,
# do not even think about 'INC' => '-I/usr/ucbinclude', Solaris will avenge.
    'dist'      => { 'COMPRESS' => 'gzip' },
);
}

sub main {
    print <<EOM;

Configuring $PACKAGE $VERSION...

EOM

    init;
    configure;
    doMakefile;
    if ($] > 5.001 &&
	(! -e 'Resource.c' || -M 'Resource.xs' < -M 'Resource.c' )) {
print  <<EOM;

Note: you may safely ignore the possible message:

  Please specify prototyping behavior for Resource.xs (see perlxs manual)

It is nothing serious.
EOM
    }
print  <<EOM;

Done configuring $PACKAGE $VERSION.

Now you may issue 'make'.  Do not forget also 'make test'.

EOM
}

&main;

# EOF
