#
# times.t
#
# We will test only the user time and system time resources
# of all the resources returned by getrusage() as they are
# probably the most portable of them all.
#

use BSD::Resource qw(times);

my $debug = 1;

$| = 1 if ($debug);

print "1..2\n";

# burn some time and CPU

my $t0 = time();
while  (time() - $t0 < 5) {
  for (1..1E4) { my $x = time() x $_ }
  for (1..1E3) { mkdir "x", 0777; rmdir "x" }
}

sleep(2);

@t0 = CORE::times();
@t1 = times();
@t2 = BSD::Resource::times();

if ($debug) {
    print "# CORE::times()          = @t0\n";
    print "# times                  = @t1\n";
    print "# BSD::Resource::times() = @t2\n";
}

sub far ($$$) {
  my ($a, $b, $r) = @_;

  print "# far: a = $a, b = $b, r = $r\n" if $debug;
  print "# far: abs(a/b-1) = ", $b ? abs($a/$b-1) : "-", "\n" if $debug; 
  $b == 0 ? 0 : (abs($a/$b-1) > $r);
}

print 'not ' if far($t1[0], $t0[0], 0.10) or
	        far($t1[1], $t0[1], 0.50);
print "ok 1\n";

print 'not ' if far($t1[0], $t2[0], 0.10) or
	        far($t1[1], $t2[1], 0.10) or
                far($t1[2], $t2[2], 0.10) or
                far($t1[3], $t2[3], 0.10);
print "ok 2\n";

# eof
