#*
#* Copyright (c) 1995 Jarkko Hietaniemi. All rights reserved.
#* This program is free software; you can redistribute it and/or
#* modify it under the same terms as Perl itself.
#*
#* Time-stamp:	<95/12/07 18:27:40 jhi>
#*

require 5.001;

package BSD::Resource;

$SELF = 'BSD::Resource';

require Exporter;
require DynaLoader;
use Carp;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	     PRIO_MIN PRIO_MAX PRIO_USER PRIO_PGRP PRIO_PROCESS
	     getpriority setpriority
	     RLIMIT_CPU RLIMIT_FSIZE RLIMIT_DATA
	     RLIMIT_NOFILE RLIMIT_OPEN_MAX
	     RLIMIT_AS RLIMIT_VMEM
	     RLIMIT_STACK RLIMIT_CORE RLIMIT_RSS
	     RLIM_NLIMITS RLIM_INFINITY
	     getrlimit setrlimit
	     RUSAGE_SELF RUSAGE_CHILDREN RUSAGE_THREAD
	     getrusage	
);

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    if ($AUTOLOAD =~ /::(_?[a-z])/) {
        $AutoLoader::AUTOLOAD = $AUTOLOAD;
        goto &AutoLoader::AUTOLOAD
    }
    local($constname);
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val;
    $val = constant($constname, @_ ? ($_[0] =~ /^\d+/ ? $_[0] : 0) : 0);
    if ($!) {
      if ($! =~ /Invalid/) {
        my ($file, $line) = (caller)[1,2];
	die "$file:$line: $constname is not a valid $SELF macro.\n";
      }
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

use strict;

=head1 NAME

BSD::Resource - BSD process resource limit and priority functions

=head1 SYNOPSIS

	use BSD::Resource;

	($usertime, $systemtime,
	 $maxrss, $ixrss, $idrss, $isrss, $minflt, $majflt, $nswap,
	 $inblock, $oublock, $msgsnd, $msgrcv,
	 $nsignals, $nvcsw, $nivcsw) = getrusage($ru_who);

	($nowsoft, $nowhard) = getrlimit($resource);

	$nowpriority = getpriority($which, $pr_ywho);

	$success = setrlimit($resource, $newsoft, $newhard);

	$success = setpriority($which, $who, $priority);

=head1 DESCRIPTION

=head2 getrusage

For a detailed description about the values returned by getrusage()
please consult your usual C programming documentation about
getrusage() and also the header file C<sys/resource.h>.
The $ru_who argument is either RUSAGE_SELF (the current process) or
RUSAGE_CHILDREN (all the child processes of the current process).
On some (very few) systems (those supporting both getrusage() and the
POSIX threads) there is also RUSAGE_THREAD. The BSD::Resource supports
the _THREAD flag if it is present but understands nothing about the POSIX
threads themselves.

Note 1: officially HP-UX 9 does not support
getrusage() at all but for the time being, it does seem to.

Note 2: Solaris claims in C<sys/rusage.h> that the C<ixrss>
and the C<isrss> fields are always zero.

=head2 getrlimit

Processes have soft and hard resource limits.
At soft limit they receive a signal (XCPU or XFSZ, normally)
they can trap and handle and at hard limit they will
be ruthlessly killed by the KILL signal.
The $resource argument can be one of

	RLIMIT_CPU RLIMIT_FSIZE
	RLIMIT_DATA RLIMIT_STACK RLIMIT_CORE RLIMIT_RSS
	RLIMIT_NOFILE RLIMIT_OPEN_MAX
	RLIMIT_AS RLIMIT_VMEM

The last two pairs (NO_FILE, OPEN_MAX) and (AS, VMEM) mean the same,
the former being the BSD names and the latter SVR4 names.
Two meta-resource-symbols might exist

	RLIM_NLIMITS
	RLIM_INFINITY

NLIMITS being the number of possible (but not necessarily fully supported)
resource limits, INFINITY being useful in setrlimit().

B<NOTE>: the level of 'support' for a resource varies. Not all the systems

	a) even recognise all those limits
	b) really track the consumption of a resource
	c) care (send those signals) if a resource limit get exceeded

Again, please consult your usual C programming documentation.

One notable exception: officially HP-UX 9 does not support
getrlimit() at all but for the time being, it does seem to.

=head2 getpriority

The priorities returned by getpriority() are [PRIO_MIN,PRIO_MAX].
The $which argument can be any of PRIO_PROCESS (a process) PRIO_USER
(a user), or PRIO_PGRP (a process group). The $pr_who argument tells
which process/user/process group, 0 signifying the current one.

=head2 setrlimit

A normal user process can only lower its resource limits.
Soft or hard limit RLIM_INFINITY means as much as possible,
the real limits are normally buried inside the kernel.

=head2 setpriority

The priorities handled by setpriority() are [PRIO_MIN,PRIO_MAX].
A normal user process can only lower its priority (make it more positive).

=head1 EXAMPLES

	# the user and system times so far by the process itself

	($usertime, $systemtime) = getrusage(RUSAGE_SELF);

	# get the current priority level of this process

	$currprio = getpriority(PRIO_PROCESS, 0);

=head1 VERSION

v1.0, $Id: Resource.pm,v 1.6 1995/12/18 08:32:00 jhi Exp $

=head1 AUTHOR

Jarkko Hietaniemi, C<Jarkko.Hietaniemi@hut.fi>

=cut

bootstrap BSD::Resource;

# Preloaded methods go here.

# Autoload methods go after __END__,
# and are processed by the autosplit program.

1;
__END__

sub getrusage {
    usage('getrusage($who)', '@rusage') if @_ != 1;
    getrusage($_[0]);
}

sub getrlimit {
    usage ('getrlimit($resource)', '($nowsoft, $nowhard)') if @_ != 1;
    getrlimit($_[0]);
}

sub getpriority {
    usage('getpriority($which, $who)', '$nowprio') if @_ != 2;
    getpriority($_[0]);
}

sub setrlimit {
    usage('setrlimit($resource, $soft, $hard)', '$success') if @_ != 3;
    setrlimit($_[0], $_[1], $_[2]);
}

sub setpriority {
    usage('setpriority($which, $who, $priority)', '$success') if @_ != 3;
    setpriority($_[0]);
}

sub usage {
  croak "Usage: $_[1] = $_[0]\n";
}

1;
