#
# Copyright (c) 1995-9,2000 Jarkko Hietaniemi. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Resource.pm
#

require 5.002;

package BSD::Resource;

use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use strict;

use Carp;
use AutoLoader;

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw(
	     PRIO_MIN PRIO_MAX PRIO_USER PRIO_PGRP PRIO_PROCESS
	     getpriority setpriority
	     RLIMIT_CPU RLIMIT_FSIZE RLIMIT_DATA
	     RLIMIT_NOFILE RLIMIT_OPEN_MAX RLIMIT_OFILE
	     RLIMIT_AS RLIMIT_VMEM
	     RLIMIT_STACK RLIMIT_CORE RLIMIT_RSS
	     RLIMIT_MEMLOCK RLIMIT_NPROC
	     RLIMIT_AIO_MEM RLIMIT_AIO_OPS
	     RLIMIT_TCACHE
	     RLIM_NLIMITS RLIM_INFINITY RLIM_SAVED_CUR RLIM_SAVEWD_MAX
	     getrlimit setrlimit
	     RUSAGE_BOTH RUSAGE_SELF RUSAGE_CHILDREN RUSAGE_THREAD
	     getrusage	
	     get_rlimits
);

Exporter::export_tags();

@EXPORT_OK = qw(times);

# Grandfather old foo_h form to new :foo_h form
sub import {
    my $this = shift;
    my @list = map { m/^\w+_h$/ ? ":$_" : $_ } @_;
    local $Exporter::ExportLevel = 1;
    Exporter::import($this,@list);
}

bootstrap BSD::Resource;

my $EINVAL = constant("EINVAL", 0);
my $EAGAIN = constant("EAGAIN", 0);

sub AUTOLOAD {
    if ($AUTOLOAD =~ /::(_?[a-z])/) {
        $AutoLoader::AUTOLOAD = $AUTOLOAD;
        goto &AutoLoader::AUTOLOAD;
    }
    local $! = 0;
    my $constname = $AUTOLOAD;
    $constname =~ s/.*:://;
    return if $constname eq 'DESTROY';
    my $val = constant($constname, @_ ? $_[0] : 0);
    no strict 'refs';
    if ($! == 0) {
        *$AUTOLOAD = sub { $val };
    }
    elsif ($! == $EAGAIN) {     # Not really a constant, so always call.
        *$AUTOLOAD = sub { constant($constname, $_[0]) };
    }
    elsif ($! == $EINVAL) {
        croak "$constname is not a valid BSD::Resource macro";
    }
    else {
        croak "Your vendor has not defined BSD::Resource macro $constname, used";
    }
    use strict 'refs';

    goto &$AUTOLOAD;
}
use strict;

=pod

=head1 NAME

BSD::Resource - BSD process resource limit and priority functions

=head1 SYNOPSIS

	use BSD::Resource;

	#
	# the process resource consumption so far
	#

	($usertime, $systemtime,
	 $maxrss, $ixrss, $idrss, $isrss, $minflt, $majflt, $nswap,
	 $inblock, $oublock, $msgsnd, $msgrcv,
	 $nsignals, $nvcsw, $nivcsw) = getrusage($ru_who);

	$rusage = getrusage($ru_who);

	#
	# the process resource limits
	#

	($nowsoft, $nowhard) = getrlimit($resource);

	$rlimit = getrlimit($resource);

	$success = setrlimit($resource, $newsoft, $newhard);

	#
	# the process scheduling priority
	#

	$nowpriority = getpriority($pr_which, $pr_who);

	$success = setpriority($pr_which, $pr_who, $priority);

	# The following is not a BSD function.
	# It is a Perlish utility for the users of BSD::Resource.

	$rlimits = get_rlimits();

=head1 DESCRIPTION

=head2 getrusage

	($usertime, $systemtime,
	 $maxrss, $ixrss, $idrss, $isrss, $minflt, $majflt, $nswap,
	 $inblock, $oublock, $msgsnd, $msgrcv,
	 $nsignals, $nvcsw, $nivcsw) = getrusage($ru_who);

	$rusage = getrusage($ru_who);

	# $ru_who argument is optional; it defaults to RUSAGE_SELF

	$rusage = getrusage();

The $ru_who argument is either C<RUSAGE_SELF> (the current process) or
C<RUSAGE_CHILDREN> (all the child processes of the current process)
or it maybe left away in which case C<RUSAGE_SELF> is used.

The C<RUSAGE_CHILDREN> is the total sum of all the so far
I<terminated> (either successfully or unsuccessfully) child processes:
there is no way to find out information about child processes still
running.

On some systems (those supporting both getrusage() and the POSIX
threads) there is also C<RUSAGE_THREAD>. The BSD::Resource supports the
C<RUSAGE_THREAD> if it is present but understands nothing more about the
POSIX threads themselves.  Similarly for C<RUSAGE_BOTH>: some systems
support retrieving the sums of the self and child resource consumptions
simultaneously.

In list context getrusage() returns the current resource usages as a
list. On failure it returns an empty list.

The elements of the list are, in order:
	index	name		meaning usually (quite system dependent)

	 0	utime		user time
	 1	stime		system time
    	 2	maxrss		maximum shared memory or current resident set
	 3	ixrss		integral shared memory
	 4	idrss		integral or current unshared data
	 5	isrss		integral or current unshared stack
	 6	minflt		page reclaims
	 7	majflt		page faults
    	 8	nswap		swaps
	 9	inblock		block input operations
	10	oublock		block output operations
	11	msgsnd		messages sent
	12	msgrcv		messaged received
	13	nsignals	signals received
	14	nvcsw		voluntary context switches
	15	nivcsw		involuntary context switches

In scalar context getrusage() returns the current resource usages as a
an object. The object can be queried via methods named exactly like
the middle column, I<name>, in the above table.

	$ru = getrusage();
	print $ru->stime, "\n";

	$total_context_switches = $ru->nvcsw + $ru->nivcsw;

For a detailed description about the values returned by getrusage()
please consult your usual C programming documentation about
getrusage() and also the header file C<E<lt>sys/resource.hE<gt>>.
(In B<Solaris>, this might be C<E<lt>sys/rusage.hE<gt>>).

Note 1: officially B<HP-UX> does not support getrusage() at all but for
the time being, it does seem to.

Note 2: Because not all kernels are BSD and also because of the sloppy
support of getrusage() by many vendors many of the values may not be
updated.

For example B<Solaris 1> claims in C<E<lt>sys/rusage.hE<gt>> that the
C<ixrss> and the C<isrss> fields are always zero.

In B<SunOS 5.5 and 5.6> the getrusage() leaves most of the fiels zero
and therefore getrusage() is not even used, instead of that the
B</proc> interface is used.  The mapping is not perfect: the maxrss
field is really the B<current> resident size instead of the maximum,
the idrss is really the B<current> heap size instead of the integral
data, the isrss is really the B<current> stack size instead of the
integral stack.  The ixrss has no sensible counterpart at all so it
stays zero.

=head2 getrlimit

	($nowsoft, $nowhard) = getrlimit($resource);

	$rlimit = getrlimit($resource);

The $resource argument can be one of

	$resource		usual meaning		usual unit

	RLIMIT_CPU		CPU time		seconds

        RLIMIT_FSIZE		file size		bytes

	RLIMIT_DATA		data size		bytes
        RLIMIT_STACK		stack size		bytes
        RLIMIT_CORE		coredump size		bytes
        RLIMIT_RSS		resident set size	bytes
    	RLIMIT_MEMLOCK		memory locked data size	bytes

        RLIMIT_NPROC		number of processes	1

	RLIMIT_NOFILE		number of open files	1
	RLIMIT_OFILE		number of open files	1
        RLIMIT_OPEN_MAX		number of open files	1

	RLIMIT_AS		(virtual) address space	bytes
        RLIMIT_VMEM		virtual memory (space)	bytes

	RLIMIT_TCACHE		maximum number of	1
				cached threads

	RLIMIT_AIO_MEM		maximum memory locked	bytes
				for POSIX AIO
	RLIMIT_AIO_OPS		maximum number		1
				for POSIX AIO ops

B<What limits are available depends on the operating system>.
See below for C<get_rlimits()> on how to find out which limits are
available, for the exact documentation consult the documentation of
your operatgiing system.  The two groups (C<NOFILE>, CC<OFILE>,
<OPEN_MAX>) and (C<AS>, C<VMEM>) are aliases within themselves.

Two meta-resource-symbols might exist

	RLIM_NLIMITS
	RLIM_INFINITY

C<RLIM_NLIMITS> being the number of possible (but not necessarily fully
supported) resource limits, see also the get_rlimits() call below.
C<RLIM_INFINITY> is useful in setrlimit(), the C<RLIM_INFINITY> is
represented as -1.

In list context C<getrlimit()> returns the current soft and hard resource
limits as a list.  On failure it returns an empty list.

Processes have soft and hard resource limits.  On crossing the soft
limit they receive a signal (for example the C<SIGXCPU> or C<SIGXFSZ>,
corresponding to the C<RLIMIT_CPU> and C<RLIMIT_FSIZE>, respectively).
The processes can trap and handle some of these signals, please see
L<perlipc/Signals>.  After the hard limit the processes will be
ruthlessly killed by the C<KILL> signal which cannot be caught.

B<NOTE>: the level of 'support' for a resource varies. Not all the systems

	a) even recognise all those limits
	b) really track the consumption of a resource
	c) care (send those signals) if a resource limit is exceeded

Again, please consult your usual C programming documentation.

One notable exception for the better: officially B<HP-UX> does not
support getrlimit() at all but for the time being, it does seem to.

In scalar context getrlimit() returns the current soft and hard
resource limits as an object. The object can be queried via methods
C<cur> and C<max>, the current and maximum resource limits for the
C<$resource>, respectively.

=head2 getpriority

	$nowpriority = getpriority($pr_which, $pr_who);

	# the default $pr_who is 0 (the current $pr_which)

	$nowpriority = getpriority($pr_which);

	# the default $pr_which is PRIO_PROCESS (the process priority)

	$nowpriority = getpriority();

getpriority() returns the current priority. B<NOTE>: getpriority()
can return zero or negative values completely legally. On failure
getpriority() returns C<undef> (and C<$!> is set as usual).

The priorities returned by getpriority() are in the (inclusive) range
C<PRIO_MIN>...C<PRIO_MAX>.  The $pr_which argument can be any of
PRIO_PROCESS (a process) C<PRIO_USER> (a user), or C<PRIO_PGRP> (a
process group). The $pr_who argument tells which process/user/process
group, 0 signifying the current one.

Usual values for C<PRIO_MIN>, C<PRIO_MAX>, are -20, 20. A negative
value means better priority (more impolite process), a positive value
means worse priority (more polite process).

B<NOTE>: in B<AIX> if the BSD compatibility library is not installed or
not found by the installation procedure of the BSD::Resource the
C<PRIO_MIN> is 0 (corresponding to -20) and C<PRIO_MAX> is 39 (corresponding
to 19, the BSD priority 20 is unreachable).

=head2 setrlimit

	$success = setrlimit($resource, $newsoft, $newhard);

setrlimit() returns true on success and C<undef> on failure.

B<NOTE>: A normal user process can only lower its resource limits.
Soft or hard limit C<RLIM_INFINITY> means as much as possible, the
real hard limits are normally buried inside the kernel and are B<very>
system-dependent.

=head2 setpriority

	$success = setpriority($pr_which, $pr_who, $priority);

	# NOTE! If there are two arguments the second one is
	# the new $priority (not $pr_who) and the $pr_who is
	# defaulted to 0 (the current $pr_which)

	$success = setpriority($pr_which, $priority);

	# The $pr_who defaults to 0 (the current $pr_which) and
	# the $priority defaults to half of the PRIO_MAX, usually
	# that amounts to 10 (being a nice $pr_which).

	$success = setpriority($pr_which);

	# The $pr_which defaults to PRIO_PROCESS, 

	$success = setpriority();

setpriority() is used to change the scheduling priority.  A positive
priority means a more polite process/process group/user; a negative
priority means a more impoite process/process group/user.
The priorities handled by setpriority() are [C<PRIO_MIN>,C<PRIO_MAX>].
A normal user process can only lower its priority (make it more positive).

B<NOTE>: A successful call returns C<1>, a failed one C<0>.

=head2 times

	use BSD::Resource qw(times);

	($user, $system, $child_user, $child_system) = times();

The BSD::Resource module offers a times() implementation that has
usually slightly better time granularity than the times() by Perl
core.  The time granularity of the latter is usually 1/60 seconds
while the former may achieve submilliseconds.

B<NOTE>: The current implementation uses two getrusage() system calls:
one with RUSAGE_SELF and one with RUSAGE_CHILDREN.  Therefore the
operation is not `atomic': the times for the children are recorded
a little bit later.

B<NOTE>: times() is not imported by default by BSD::Resource.
  You need to tell that you want to use it.

B<NOTE: This is not a real BSD function.>

=head2 get_rlimits

	$rlimits = get_rlimits();

B<NOTE: This is not a real BSD function. It is a convenience function.>

get_rlimits() returns a reference to hash which has the names of the
available resource limits as keys and their indices (those which
are needed as the first argument to getrlimit() and setrlimit())
as values. For example:

	$r = get_rlimits();
	print "ok.\n" if ($r->{'RLIM_STACK'} == RLIM_STACK);

=head1 ERRORS

=over 4

=item *

	Your vendor has not defined BSD::Resource macro RLIMIT_...

The code tried to call getrlimit/setrlimit for a resource limit that
your operating system vendor/supplier does not support.  Portable code
should use get_rlimits() to check which resource limits are defined.

=back

=head1 EXAMPLES

	# the user and system times so far by the process itself

	($usertime, $systemtime) = getrusage();

	# ditto in OO way

	$ru = getrusage();

	$usertime   = $ru->utime;
	$systemtime = $ru->stime;

	# get the current priority level of this process

	$currprio = getpriority();

=head1 VERSION

Release 1.08

=head1 AUTHOR

Jarkko Hietaniemi, C<jhi@iki.fi>

=cut

1;
__END__

sub getrusage (;$) {
    my @rusage = _getrusage(@_);

    if (wantarray) {
	@rusage;
    } else {
	my $rusage = {};
	my $key;

	for $key (qw(utime stime maxrss ixrss idrss isrss minflt majflt nswap
		     inlock oublock msgsnd msgrcv nsignals nvcsw nivcsw)) {
	    $rusage->{$key} = shift(@rusage);
	}
	
	bless $rusage;
    }
}

sub _g {
    exists $_[0]->{$_[1]} ?
	$_[0]->{$_[1]} : die "BSD::Resource: no method '$_[1]',";
}

sub utime    { _g($_[0], 'utime'   ) }
sub stime    { _g($_[0], 'stime'   ) }
sub maxrss   { _g($_[0], 'maxrss'  ) }
sub ixrss    { _g($_[0], 'ixrss'   ) }
sub idrss    { _g($_[0], 'idrss'   ) }
sub minflt   { _g($_[0], 'minflt'  ) }
sub majflt   { _g($_[0], 'majflt'  ) }
sub nswap    { _g($_[0], 'nswap'   ) }
sub inblock  { _g($_[0], 'inblock' ) }
sub oublock  { _g($_[0], 'oublock' ) }
sub msgsnd   { _g($_[0], 'msgsnd'  ) }
sub msgrcv   { _g($_[0], 'msgrcv'  ) }
sub nsignals { _g($_[0], 'nsignals') }
sub nvcsw    { _g($_[0], 'nvcsw'   ) }
sub nivcsw   { _g($_[0], 'nivcsw'  ) }

sub getrlimit ($) {
    my @rlimit = _getrlimit($_[0]);

    if (wantarray) {
	@rlimit;
    } else {
	my $rlimit = {};
	my $key;

	for $key (qw(soft hard)) {
	    $rlimit->{$key} = shift(@rlimit);
	}

	bless $rlimit;
    }
}

sub soft   { _g($_[0], 'soft') }
sub hard   { _g($_[0], 'hard') }

sub get_rlimits () {
    _get_rlimits();
}

sub getpriority (;$$) {
    _getpriority(@_);
}

sub setrlimit ($$$) {
    _setrlimit($_[0], $_[1], $_[2]);
}

sub setpriority (;$$$) {
    _setpriority(@_);
}

sub times {
    use BSD::Resource qw(RUSAGE_SELF RUSAGE_CHILDREN);

    my ($u,  $s ) = _getrusage(RUSAGE_SELF);
    my ($cu, $cs) = _getrusage(RUSAGE_CHILDREN);

    return ($u, $s, $cu, $cs);
}

1;
