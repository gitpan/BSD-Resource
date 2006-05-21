#
# setrlimit.t
#

use BSD::Resource;

$debug = 0;

$LIM = get_rlimits();

@LIM = keys %$LIM;

@LIM{@LIM} = undef;

@test = ();

sub newlim {
  my ($oldlim, $oldhard) = @_;

  my $newlim =
      ($oldlim == RLIM_INFINITY) ? $oldlim : $oldlim ? int(0.95 * $oldlim) : 1;
  
  # print "newlim/1 = $newlim\n";

  $newlim = $oldhard if $oldhard > 0 && $newlim > $oldhard;

  # print "newlim/2 = $newlim\n";

  return $newlim;
}

sub klim {
  print "# klim: $_[0]\n" if ($debug);
  $_[0] =~ /^RLIM_(?:AS|CORE|DATA|MEMLOCK|RSS|STACK|VMEM)$/;
}

sub test {
  my ($lim) = shift;
  my ($oldsoft, $oldhard, $newsoft, $newhard, $nowsoft, $nowhard, $set, $ser);

  if (exists $LIM{$lim}) {
    print "# $lim\n" if ($debug);
    $lim = eval '&'.$lim;
    ($oldsoft, $oldhard) = getrlimit($lim);
    print "# RLIM_INFINITY = ", RLIM_INFINITY, "\n" if ($debug);
    print "# lim = $lim, oldsoft = $oldsoft, oldhard = $oldhard\n" if ($debug);
    $newsoft = newlim($oldsoft, $oldhard);
    $newhard = newlim($oldhard, $oldhard);
    print "# lim = $lim, newsoft = $newsoft, newhard = $newhard\n" if ($debug);
    $set = setrlimit($lim, $newsoft, $newhard);
    $ser = $!;
    ($nowsoft, $nowhard) = getrlimit($lim);
    print "# set = $set ($ser), nowsoft = $nowsoft, nowhard = $nowhard\n" if ($debug);
    push @test,
	 $set == 0
	 ||
	 (($nowsoft != $newsoft && (!klim($lim) && sprintf("%x", $nowsoft) !~ /0{2,}$/)) && $newsoft > 0 && $nowsoft > 0)
	 ||
	 (($nowhard != $newhard && (!klim($lim) && sprintf("%x", $nowhard) !~ /0{2,}$/)) && $newhard > 0 && $nowhard > 0)
         ;
  }
}

# getrlimit needed to test whether setrlimit() really works

$! = 0;
for $lim (@LIM) { test($lim) }

if (@test) {
  $ntest = scalar @test;
  print "1..$ntest\n";
  for $i (1..$ntest) {
    my $ok = !$test[$i-1];
    if ($^O eq 'darwin' && $LIM[$i-1] eq 'RLIMIT_NPROC') {
	$ok = 1;
	if ($test[$i-1]) {
	    print STDERR "# The RLIMIT_NPROC test is known to fail in Mac OS X.\n";
	} else {
	    print STDERR "\n# The RLIMIT_NPROC test seems to work this time in Mac OS X.\n";
	}
    }
    printf "%s $i # $LIM[$i-1]\n", $ok ? "ok" : "not ok";
  }
} else {
  die "could not find any resource limits to test\n";
}

# eof
