use BSD::Resource;

# we will test only the user time and system time resources
# of all the resources returned by getrusage() as they are
# probably the most portable of them all.

print "1..1\n";

$time0 = time();

# we will compare the user/system times as returned by getrusage()

@ru = getrusage(RUSAGE_SELF);

# to the respective times returned by times() (if available)

eval '($tsu, $tss) = times()';

# and to the real (wallclock) time returned by time()

sleep(3);	# this sleep because we want some real time to pass

$real = time() - $time0;

($ruu, $rus) = @ru;

$ruc = $ruu + $rus;

$tsc = $tsu + $tss;

# relatively far

sub far {
  my ($a, $b, $r) = @_;

  ($b == 0) ? 0 : (abs($a/$b-1) > $r);
}

print 'not '
  if (far($ruu, $tsu, 0.25)	# 25% leeway allowed
      or
      far($rus, $tss, 0.25)
      or
      far($ruc, $tsc, 0.25)
      or
      $ruc > $real);
print "ok 1\n";

# eof
