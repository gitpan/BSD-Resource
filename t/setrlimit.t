#
# setrlimit.t
#

use BSD::Resource;

# use strict;

my @LIM = sort keys %{ get_rlimits() };

print "1..", scalar @LIM, "\n";;

my $test_no = 1;

for my $lim (@LIM) {
    print "# lim = $lim\n";
    my ($old_soft, $old_hard) = getrlimit($lim);
    print "# old_soft = $old_soft, old_hard = $old_hard\n";
    my ($try_soft,  $try_hard ) =
	map { ($_ == RLIM_INFINITY) ? RLIM_INFINITY : int(0.95 * $_) }
            ($old_soft, $old_hard);
    print "# try_soft = $try_soft, try_hard = $try_hard\n";
    if ($try_soft == RLIM_INFINITY) {
	print "ok $test_no # SKIP soft_limit == RLIM_INFINITY\n";
    } else {
	my $success = setrlimit($lim, $try_soft, $try_hard);
	if ($success) {
	    print "# setrlimit($lim, $try_soft) = OK\n";
	    my $new_soft = getrlimit($lim);
	    print "# getrlimit($lim) = $new_soft\n";
	    if (($new_soft > 0 || $old_soft == 0) && $new_soft <= $try_soft) {
		print "ok $test_no # $try_soft <= $new_soft\n";
	    } else {
		print "NOT ok $test_no # $try_soft > $new_soft\n";
	    }
	} else {
	    print "NOT ok $test_no # setrlimit($lim, $try_soft, $try_hard) failed: $!\n";
	}
    }
    $test_no++;
}

exit(0);

