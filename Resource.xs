/*
 * Copyright (c) 1995 Jarkko Hietaniemi. All rights reserved.
 * This program is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 *
 * Time-stamp:	<96/02/17 16:09:30 jhi>
 *
 * $Id: Resource.xs,v 1.11 1996/02/17 14:14:02 jhi Exp $
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* if this fails your vendor has failed you and Perl cannot help */
#include <sys/resource.h>

#if defined(__sun__) && defined(__svr4__)
#include <sys/rusage.h>
/* Solaris has no RUSAGE_* defined in <sys/resource.h>, ugh.
 * There is <sys/rusage.h> which has but this file is very non-standard.
 * More the fun, the file itself warns will not be there for long.
 * Thank you, Sun. */
#define SOLARIS
#define part_of_sec tv_nsec
#define part_in_sec 0.000001
/* Solaris uses timerstruc_t in struct rusage. According to the <sys/time.h>
 * tv_nsec in the timerstruc_t is nanoseconds (and the name also supports
 * that theory) BUT getrusage() seems to tick microseconds, not nano.
 * Amazing, Sun. */
#endif

#ifdef I_SYS_TIME
#   include <sys/time.h>
#endif

#ifdef I_SYS_SELECT
#   include <sys/select.h>	/* struct timeval might be hidden in here */
#endif

#ifndef part_of_sec
#define part_of_sec tv_usec
#define part_in_sec 0.000001
#endif

#define IDM ((double)part_in_sec)
#define TV2DS(tv) ((double)tv.tv_sec+(double)tv.part_of_sec*part_in_sec)

#ifndef HAS_GETRUSAGE
#  if defined(RUSAGE_SELF) || defined(SOLARIS)
#     define HAS_GETRUSAGE
#  endif
#endif

#if defined(__hpux)
/* there is getrusage() in HPUX but only as an indirect syscall */
#   define try_getrusage_as_syscall
/* some rlimits exist (but are officially unsupported by HP) */
#   define RLIMIT_CPU      0
#   define RLIMIT_FSIZE    1
#   define RLIMIT_DATA     2
#   define RLIMIT_STACK    3
#   define RLIMIT_CORE     4
#   define RLIMIT_RSS      5
#   define RLIMIT_NOFILE   6
#   define RLIMIT_OPEN_MAX RLIMIT_NOFILE
#   define RLIM_NLIMITS    7
#   define RLIM_INFINITY   0x7fffffff
#endif

#ifdef try_getrusage_as_syscall
#   include <sys/syscall.h>
#   if defined(SYS_GETRUSAGE)
#       define getrusage(a, b)	syscall(SYS_GETRUSAGE, (a), (b))
#	define HAS_GETRUSAGE
#   endif
#endif

#if defined(RLIM_INFINITY)	/* this is the only one we can count on (?) */
#define HAS_GETRLIMIT
#define HAS_SETRLIMIT
#endif

#if defined(PRIO_USER)
#define HAS_GETPRIORITY
#define HAS_SETPRIORITY
#endif

#ifndef HAS_GETPRIORITY
#define getpriority(a) not_here("getpriority")
#endif

#ifndef HAS_GETRLIMIT
#define getrlimit(a) not_here("getrlimit")
#endif

#ifndef HAS_GETRUSAGE
#define getrusage(a) not_here("getrusage")
#endif

#ifndef HAS_SETPRIORITY
#define setpriority(a) not_here("setpriority")
#endif

#ifndef HAS_SETRLIMIT
#define setrlimit(a,b,c) not_here("setrlimit")
#endif

static int
not_here(s)
char *s;
{
    croak("BSD::Resource::%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'P':
	if (strnEQ(name, "PRIO_", 4)) {
	    if (strEQ(name, "PRIO_MIN"))
#ifdef PRIO_MIN
		return PRIO_MIN;
#else
		goto not_there;
#endif
	    if (strEQ(name, "PRIO_MAX"))
#ifdef PRIO_MAX
		return PRIO_MAX;
#else
		goto not_there;
#endif
	    if (strEQ(name, "PRIO_USER"))
#ifdef PRIO_USER
		return PRIO_USER;
#else
		goto not_there;
#endif
	    if (strEQ(name, "PRIO_PGRP"))
#ifdef PRIO_PGRP
		return PRIO_PGRP;
#else
		goto not_there;
#endif
	    if (strEQ(name, "PRIO_PROCESS"))
#ifdef PRIO_PROCESS
		return PRIO_PROCESS;
#else
		goto not_there;
#endif
	}
    goto not_there;
    case 'R':
	if (strnEQ(name, "RLIM", 4)) {
	    if (strEQ(name, "RLIMIT_CPU"))
#ifdef RLIMIT_CPU
		return RLIMIT_CPU;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_FSIZE"))
#ifdef RLIMIT_FSIZE
		return RLIMIT_FSIZE;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_DATA"))
#ifdef RLIMIT_DATA
		return RLIMIT_DATA;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_NOFILE"))
#ifdef RLIMIT_NOFILE
		return RLIMIT_NOFILE;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_OPEN_MAX"))
#ifdef RLIMIT_OPEN_MAX
		return RLIMIT_OPEN_MAX;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_AS"))
#ifdef RLIMIT_AS
		return RLIMIT_AS;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_VMEM"))
#ifdef RLIMIT_VMEM
		return RLIMIT_VMEM;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_STACK"))
#ifdef RLIMIT_STACK
		return RLIMIT_STACK;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_CORE"))
#ifdef RLIMIT_CORE
		return RLIMIT_CORE;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_RSS"))
#ifdef RLIMIT_RSS
		return RLIMIT_RSS;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIM_NLIMITS"))
#ifdef RLIM_NLIMITS
		return RLIM_NLIMITS;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIM_INFINITY"))
#ifdef RLIM_INFINITY
		return RLIM_INFINITY;
#else
		goto not_there;
#endif
	    break;
	 }
	if (strnEQ(name, "RUSAGE_", 7)) {
	    if (strEQ(name, "RUSAGE_SELF"))
#ifdef RUSAGE_SELF
		return RUSAGE_SELF;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RUSAGE_CHILDREN"))
#ifdef RUSAGE_CHILDREN
		return RUSAGE_CHILDREN;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RUSAGE_THREAD"))
#ifdef RUSAGE_THREAD
		return RUSAGE_THREAD;
#else
		goto not_there;
#endif
	    break;
	 }
    goto not_there;

    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
    }
}

MODULE = BSD::Resource		PACKAGE = BSD::Resource

double
constant(name,arg)
	char *		name
	int		arg

int
getpriority(which,who)
	int		which
	int		who

int
getrlimit(resource)
	int		resource
    PPCODE:
	struct rlimit buf;
	if (getrlimit(resource,&buf) >= 0) {
	    EXTEND(sp, 2);
	    PUSHs(newSViv((unsigned long)buf.rlim_cur));
	    PUSHs(newSViv((unsigned long)buf.rlim_max));
	}

int
getrusage(who)
	int		who
    PPCODE:
	struct rusage buf;
	if (getrusage(who,&buf) >= 0) {
	    EXTEND(sp, 16);
	    PUSHs(newSVnv(TV2DS(buf.ru_utime)));
	    PUSHs(newSVnv(TV2DS(buf.ru_stime)));
	    PUSHs(newSViv((I32)buf.ru_maxrss));
	    PUSHs(newSViv((I32)buf.ru_ixrss));
	    PUSHs(newSViv((I32)buf.ru_idrss));
	    PUSHs(newSViv((I32)buf.ru_isrss));
	    PUSHs(newSViv((I32)buf.ru_minflt));
	    PUSHs(newSViv((I32)buf.ru_majflt));
	    PUSHs(newSViv((I32)buf.ru_nswap));
	    PUSHs(newSViv((I32)buf.ru_inblock));
	    PUSHs(newSViv((I32)buf.ru_oublock));
	    PUSHs(newSViv((I32)buf.ru_msgsnd));
	    PUSHs(newSViv((I32)buf.ru_msgrcv));
	    PUSHs(newSViv((I32)buf.ru_nsignals));
	    PUSHs(newSViv((I32)buf.ru_nvcsw));
	    PUSHs(newSViv((I32)buf.ru_nivcsw));
	}

int
setpriority(which,who,priority)
	int		which
	int		who
	int		priority
    CODE:
	RETVAL = setpriority(which,who,priority) == 0 ? 1 : 0;
    OUTPUT:
	RETVAL

int
setrlimit(resource,soft,hard)
	int		resource
	unsigned long	soft
	unsigned long	hard
    CODE:
	struct rlimit buf;
	buf.rlim_cur = soft;
	buf.rlim_max = hard;
	RETVAL = setrlimit(resource,&buf) == 0 ? 1 : 0;
    OUTPUT:
	RETVAL
