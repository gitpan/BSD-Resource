require 5.001;

use ExtUtils::MakeMaker;
# $Id: Makefile.PL,v 1.4 1996/02/17 14:14:33 jhi Exp $
# Time-stamp:	<96/02/17 15:59:52 jhi>
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# The Solaris -L/usr/ucblib and -I/usr/ucbinclude just break things.

WriteMakefile(
    'NAME'	=> 'BSD::Resource',
    'VERSION'	=> '1.03',
    'LIBS'	=> ['-lucb -lbsd'],
    'DEFINE'	=> '',
    'INC'	=> ''
);
