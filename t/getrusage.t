#
# getrusage.t
#
# We will test only the user time and system time resources
# of all the resources returned by getrusage() as they are
# probably the most portable of them all.
#

use BSD::Resource;

my $debug = 1;

$| = 1 if ($debug);

print "1..2\n";

$time0 = time();

# burn some time and CPU

sub fac { $_[0] < 2 ? 1 : $_[0] * fac($_[0] - 1) }

my $t0 = time();
while (time() - $t0 < 3) {
  for (1..1E4) { my $x = time() x $_}
  for (1..1E3) { mkdir "x"; rmdir "x" }
}

fac(10);
fac(15);
fac(20);

# we will compare the user/system times as returned by getrusage()

print "# getrusage\n" if ($debug);

@ru = getrusage(RUSAGE_SELF);

print "# ru = @ru\n" if ($debug);

# to the respective times returned by times() (if available)

print "# times\n" if ($debug);

eval '($tsu, $tss) = times()';

print "# tsu = $tsu, tss = $tss\n" if ($debug);

# and to the real (wallclock) time returned by time()

$nap = 6;

die "$0: naptime '$nap' too fast\n" if ($nap < 3);

print "# sleep($nap)\n" if ($debug);

sleep($nap);	# this sleep because we want some real time to pass

$real = time() - $time0;

print "# real = $real\n" if ($debug);

($ruu, $rus) = @ru;

$ruc = $ruu + $rus;

$tsc = $tsu + $tss;

# relatively far

sub far ($$$) {
  my ($a, $b, $r) = @_;

  print "# far: a = $a, b = $b, r = $r\n" if $debug;
  print "# far: abs(a/b-1) = ", $b ? abs($a/$b-1) : "-", "\n" if $debug; 
  $b == 0 ? 0 : (abs($a/$b-1) > $r);
}

if ($debug) {
  print "# ruu = $ruu, tsu = $tsu\n";
  print "# rus = $rus, tss = $tss\n";
  print "# ruc = $ruc, tsc = $tsc\n";
  print "# real = $real\n";
}

print 'not '
  if (far($ruu, $tsu, 0.20)
      or
      far($rus, $tss, 0.40)
      or
      $ruc > $real);
print "ok 1\n";

# burn some time and CPU once more

$t0 = time();
while (time() - $t0 < 3) {
  for (1..1E4) { my $x = time() x $_ }
  for (1..1E3) { mkdir "x"; rmdir "x" }
}

$ru = getrusage();
@ru = getrusage();

print "# \@ru = (@ru)\n" if ($debug);

print 'not '
  if (far($ru->utime, $ru[0], 0.20)
      or
      far($ru->stime, $ru[1], 0.40)
     );

print "ok 2\n";

# eof
