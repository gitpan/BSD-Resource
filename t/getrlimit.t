#
# getrlimit.t
#

use BSD::Resource;

$debug = 1;

$LIM = get_rlimits();

@k = keys   %$LIM;

@v = values %$LIM;

$maxt = $#k + 2;

print "1..$maxt\n";

print "# k = @k, v = @v\n" if ($debug);

print 'not '
  unless (@k);
print "ok 1\n";

$it = 2;

for $lim (@k) {
  print 'not ' unless (eval "getrlimit($lim)");
  print "ok $it\n";
  $it++;
}

# eof



