use BSD::Resource;

require 't/scanrlimits';

@LIM = scanrlimits();

$maxt = scalar @LIM + 1;

print "1..$maxt @LIM\n";

print 'not '
  unless (@LIM);
print "ok 1\n";

$it = 2;

for $lim (@LIM) {
  print 'not ' unless (eval "getrlimit($lim)");
  print "ok $it\n";
  $it++;
}

# eof

