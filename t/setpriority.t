#
# setpriority.t
#

use BSD::Resource;

$debug = 1;

print "1..3\n";

$origprio = getpriority(PRIO_PROCESS, 0);

print "# origprio = $origprio ($!)\n" if ($debug);

$gotlower = setpriority(PRIO_PROCESS, 0, $origprio + 1);

print "# gotlower = $gotlower ($!)\n" if ($debug);

# we must use getpriority() to find out whether setpriority() really worked

$lowerprio = getpriority(PRIO_PROCESS, 0);

print "# lowerprio = $lowerprio ($!)\n" if ($debug);

$fail = (not $gotlower or not $lowerprio == $origprio + 1);

print 'not '
  if ($fail);
print "ok 1\n";
if ($fail) {
  print "# syserr = '$!' (",$!+0,"), ruid = $<, euid = $>\n";
  print "# gotlower = $gotlower, lowerprio = $lowerprio\n";
}

if ($origprio == 0) {

  $gotlower = setpriority();

  print "# gotlower = $gotlower ($!)\n" if ($debug);

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
} else {
  print "ok 2 # skipped (origprio = $origprio)\n";
}

if ($> == 0) { # only effective uid root can even attempt this
  $gothigher = setpriority(PRIO_PROCESS, 0, -5);
  print "# gothigher = $gothigher\n" if ($debug);
  $higherprio = getpriority(PRIO_PROCESS, 0);
  print "# higherprio = $higherprio\n" if ($debug);
  $fail = (not $gothigher or not $higherprio == -5);
  print 'not '
    if ($fail);
  if ($fail) {
    print "# syserr = '$!' (",$!+0,"), ruid = $<, euid = $>\n";
    print "# gothigher = $gothigher, higherprio = $higherprio\n";
  }
  print "ok 3 # (euid = $>) \n";
} else {
  print "ok 3 # skipped (euid = $>)\n";
}

# eof
