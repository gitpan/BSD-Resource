# $Id: setrlimit.t,v 1.4 1995/12/18 10:14:04 jhi Exp jhi $

use BSD::Resource;

require 't/scanrlimits';

@LIM = scanrlimits();

@LIM{@LIM} = undef;

@test = ();

$debug = 1;

sub newlim {
  my $old = shift;

  return ($old == RLIM_INFINITY) ? $old : ($old ? int(.9 * $old) : 1);
}

sub test {
  my ($lim) = shift;
  my ($oldsoft, $oldhard, $newsoft, $newhard, $nowsoft, $nowhard, $set);

  if (exists $LIM{$lim}) {
    print "$lim\n" if ($debug);
    $lim = eval '&'.$lim;
    ($oldsoft, $oldhard) = getrlimit($lim);
    print "RLIM_INFINITY = ", RLIM_INFINITY, "\n" if ($debug);
    print "lim = $lim, oldsoft = $oldsoft, oldhard = $oldhard\n" if ($debug);
    $newsoft = newlim($oldsoft);
    $newhard = newlim($oldhard);
    print "lim = $lim, newsoft = $newsoft, newhard = $newhard\n" if ($debug);
    $set = setrlimit($lim, $newsoft, $newhard);
    ($nowsoft, $nowhard) = getrlimit($lim);
    print "set = $set, nowsoft = $nowsoft, nowhard = $nowhard\n" if ($debug);
    push(@test,
	 ($set == 0
	  or
	  $nowsoft != $newsoft
	  or
	  $nowhard != $newhard
	  ));
  }
}

# getrlimit needed to test whether setrlimit() really works

for $lim (@LIM) { test($lim) }

if (@test) {
  $ntest = scalar @test;
  print "1..$ntest\n";
  for $i (1..$ntest) {
    print 'not ' if ($test[$i-1]);
    print "ok $i\n";
  }
} else {
  die "could not find any resource limits to test\n";
}

# eof
