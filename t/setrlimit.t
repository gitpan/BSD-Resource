#
# setrlimit.t
#

use BSD::Resource;

$debug = 1;

$LIM = get_rlimits();

@LIM = keys %$LIM;

@LIM{@LIM} = undef;

@test = ();

sub newlim {
  my $old = shift;

  return ($old == RLIM_INFINITY) ? $old : ($old ? int(0.95 * $old) : 1);
}

sub klim {
  print "# klim: $_[0]\n";
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
    $newsoft = newlim($oldsoft);
    $newhard = newlim($oldhard);
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
    print 'not ' if $test[$i-1];
    print "ok $i\n";
  }
} else {
  die "could not find any resource limits to test\n";
}

# eof
