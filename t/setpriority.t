#
# setpriority.t
#

use BSD::Resource;

$debug = 1;

print "1..3\n";

$gotlower = setpriority(PRIO_PROCESS, 0, 5);

print "# gotlower = $gotlower\n" if ($debug);

# we must use getpriority() to find out whether setpriority() really worked

$lowerprio = getpriority(PRIO_PROCESS, 0);

print "# lowerprio = $lowerprio\n" if ($debug);

$fail = (not $gotlower or not $lowerprio == 5);

print 'not '
  if ($fail);
print "ok 1\n";
if ($fail) {
  print "# syserr = '$!' (",$!+0,"), ruid = $<, euid = $>\n";
  print "# gotlower = $gotlower, lowerprio = $lowerprio\n";
}

$gotlower = setpriority();

print "# gotlower = $gotlower\n" if ($debug);

# we must use getpriority() to find out whether setpriority() really worked

$lowerprio = getpriority();

print "# lowerprio = $lowerprio\n" if ($debug);

$fail = (not $gotlower or not $lowerprio == 10);

print 'not '
  if ($fail);
print "ok 2\n";
if ($fail) {
  print "# syserr = '$!' (",$!+0,"), ruid = $<, euid = $>\n";
  print "# gotlower = $gotlower, lowerprio = $lowerprio\n";
}

if ($> == 0) { # only effective uid root can even attempt this
  $gothigher = setpriority(PRIO_PROCESS, 0, -5);
  print "# gothigher = $gothigher\n" if ($debug);
  $higherprio = getpriority(PRIO_PROCESS, 0);
  print "# higherprio = $higherprio\n" if ($debug);
  $fail = (not $gothigher or not $higherprio == -5);
  print 'not '
    if ($fail);
} else {
  $fail = 0;
}
print "ok 3\n";
if ($fail) {
  print "# syserr = '$!' (",$!+0,"), ruid = $<, euid = $>\n";
  print "# gothigher = $gothigher, higherprio = $higherprio\n";
}

# eof
