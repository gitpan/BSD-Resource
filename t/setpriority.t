use BSD::Resource;

print "1..2\n";

$lower = setpriority(PRIO_PROCESS, 0, 5);

# we must use getpriority() to find out whether setpriority() really worked

$lowerprio = getpriority(PRIO_PROCESS, 0);

print 'not '
  if ($lower == 0
      or
      $lowerprio != 5);
print "ok 1\n";

if ($> == 0) {
  $higher = setpriority(PRIO_PROCESS, 0, -5);
  $higherprio = getpriority(PRIO_PROCESS, 0);
  print 'not'
    if ($higher == 0
	or
	$higherprio != -5);
}
print "ok 2\n";

# eof
