#
# getpriority.t
#

use BSD::Resource;

use Config;

$debug = 1;

print "1..3\n";

# AIX without BSD libs has 0..39 priorities, not -20..20.
$okpriopat = $Config{'osname'} eq 'aix' ? '0|19' : '0';

$okpriopat = "^($okpriopat)";

$nowprio1 = getpriority(PRIO_PROCESS, 0);

print "# nowprio1 = $nowprio1\n" if ($debug);

print 'not ' unless ($nowprio1 =~ /$okpriopat/);
print "ok 1\n";

$nowprio2 = getpriority(PRIO_PROCESS);

print "# nowprio2 = $nowprio2\n" if ($debug);

print 'not ' unless ($nowprio2 =~ /$okpriopat/ and $nowprio1 == $nowprio2);
print "ok 2\n";

$nowprio3 = getpriority();

print "# nowprio3 = $nowprio3\n" if ($debug);

print 'not ' unless ($nowprio3 =~ /$okpriopat/ and $nowprio2 == $nowprio3);
print "ok 3\n";

# eof
