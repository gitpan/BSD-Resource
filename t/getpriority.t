use BSD::Resource;

print "1..1\n";

$nowprio = getpriority(PRIO_PROCESS, 0);

print 'not ' unless ($nowprio == 0);
print "ok 1\n";

# eof
