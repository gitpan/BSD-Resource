/*
 * Copyright (c) 1995-8 Jarkko Hietaniemi. All rights reserved.
 * This program is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 *
 * Resource.xs
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* if this fails your vendor has failed you and Perl cannot help. */
#include <sys/resource.h>

#if defined(__sun__) && defined(__svr4__)
#   define SOLARIS
#   ifdef I_SYS_RUSAGE
#       include <sys/rusage.h>
/* Some old Solarises have no RUSAGE_* defined in <sys/resource.h>.
 * There is <sys/rusage.h> which has but this file is very non-standard.
 * More the fun, the file itself warns will not be there for long. */
#       define part_of_sec tv_nsec
#   endif
/* Solaris uses timerstruc_t in struct rusage. According to the <sys/time.h>
 * in old Solarises tv_nsec in the timerstruc_t is nanoseconds (and the name
 * also supports that theory) BUT getrusage() seems after al to tick
 * microseconds, not nano. */
#   define part_in_sec 0.000001
#
/* Newer Solarises (5.5, 5.6) have much better support for rusage-kinda
 * things via the proc interface. */
#   define _STRUCTURED_PROC 1
#   include <sys/procfs.h>
#   include <fcntl.h>

#   ifdef PIOCUSAGE
#       undef SOLARIS_STRUCTURED_PROC
#   else
#       define SOLARIS_STRUCTURED_PROC
#   endif

#   ifdef SOLARIS_STRUCTURED_PROC
#       define Struct_psinfo  struct psinfo
#       define Struct_pstatus struct pstatus
#   else
#       define Struct_psinfo  struct prpsinfo
#       define Struct_pstatus struct prstatus
#   endif
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

#if defined(OS2) && !defined(PRIO_PROCESS)
#   define PRIO_PROCESS 0	/* This argument is ignored anyway. */
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

#ifndef Rlim_t
#   ifdef Quad_t
#       define Rlim_t Quad_t
#   else
#       define Rlim_t unsigned long
#   endif
#endif

#if defined(RLIM_INFINITY)	/* this is the only one we can count on (?) */
#define HAS_GETRLIMIT
#define HAS_SETRLIMIT
#endif

#ifndef PRIO_MAX
#   define PRIO_MAX  20
#endif

#ifndef PRIO_MIN
#   define PRIO_MIN -20
#endif

#if defined(PRIO_USER)
#define HAS_GETPRIORITY
#define HAS_SETPRIORITY
#endif

#ifndef HAS_GETPRIORITY
#define _getpriority(a,b)   not_here("getpriority")
#endif

#ifndef HAS_GETRLIMIT
#define _getrlimit(a,b)     not_here("getrlimit")
#endif

#ifndef HAS_GETRUSAGE
#define _getrusage(a,b)     not_here("getrusage")
#endif

#ifndef HAS_SETPRIORITY
#define _setpriority(a,b,c) not_here("setpriority")
#endif

#ifndef HAS_SETRLIMIT
#define _setrlimit(a,b)     not_here("setrlimit")
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
    case 'E':
	if (strEQ(name, "EINVAL"))
#ifdef EINVAL
	  return EINVAL;
#else
	  goto not_there;
#endif
	if (strEQ(name, "ENOENT"))
#ifdef ENOENT
	  return ENOENT;
#else
	  goto not_there;
#endif
      break;
    case 'P':
	if (strnEQ(name, "PRIO_", 5)) {
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
	    if (strEQ(name, "RLIMIT_MEMLOCK"))
#ifdef RLIMIT_MEMLOCK
		return RLIMIT_MEMLOCK;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_NPROC"))
#ifdef RLIMIT_NPROC
		return RLIMIT_NPROC;
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
		return -1.0;	/* trust me */
#else
		goto not_there;
#endif
	    break;
	 }
	if (strnEQ(name, "RUSAGE_", 7)) {
	    if (strEQ(name, "RUSAGE_BOTH"))
#ifdef RUSAGE_BOTH
		return RUSAGE_BOTH;
#else
		goto not_there;
#endif
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
    }

    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

MODULE = BSD::Resource		PACKAGE = BSD::Resource

# No, I won't. 5.001m xsubpp chokes on this.
# PROTOTYPES: enable

double
constant(name,arg)
	char *		name
	int		arg

void
_getpriority(which = PRIO_PROCESS, who = 0)
	int		which
	int		who
    CODE:
	{
	  int		prio;

	  ST(0) = sv_newmortal();
	  errno = 0; /* getpriority() can successfully return <= 0 */
	  prio = getpriority(which, who);
	  if (errno == 0) 
	    sv_setiv(ST(0), prio);
	  else
	    ST(0) = &sv_undef;
	}

void
_getrlimit(resource)
	int		resource
    PPCODE:
	struct rlimit rl;
	if (getrlimit(resource, &rl) == 0) {
	    EXTEND(sp, 2);
	    PUSHs(sv_2mortal(newSVnv((double)(rl.rlim_cur == RLIM_INFINITY ? -1.0 : rl.rlim_cur))));
	    PUSHs(sv_2mortal(newSVnv((double)(rl.rlim_max == RLIM_INFINITY ? -1.0 : rl.rlim_max))));
	}

void
_getrusage(who = RUSAGE_SELF)
	int		who
    PPCODE:
	{
	  struct rusage ru;
#ifdef SOLARIS
	  Struct_psinfo  psi;
	  Struct_pstatus pst;
	  struct prusage pru;
	  pid_t  pid = getpid();
	  int    res, fd;
	  char psib[40], pstb[40], prub[40];
	  ru.ru_utime.tv_sec   = 0;
	  ru.ru_utime.tv_usec  = 0;
	  ru.ru_stime.tv_sec   = 0;
	  ru.ru_stime.tv_usec  = 0;
          ru.ru_maxrss   = 0;
          ru.ru_ixrss    = 0;
	  ru.ru_idrss    = 0;
	  ru.ru_isrss    = 0;
	  ru.ru_minflt   = 0;
	  ru.ru_majflt   = 0;
	  ru.ru_nswap    = 0;
	  ru.ru_inblock  = 0;
	  ru.ru_oublock  = 0;
	  ru.ru_msgsnd   = 0;
	  ru.ru_msgrcv   = 0;
	  ru.ru_nsignals = 0;
       	  ru.ru_nvcsw    = 0;
	  ru.ru_nivcsw   = 0;
#   ifndef SOLARIS_STRUCTURED_PROC
/* The time fields come okay from getrusage() but would be bad
 * from PIOCUSAGE.  Argh. */
	  res = getrusage(who, &ru);
	  if (res)
	     goto failed;
#   endif
/* With 64-bit pids "/proc/18446744073709551616/psinfo" takes 34 bytes. */
	  sprintf(psib, "/proc/%d", pid);
	  sprintf(pstb, "/proc/%d", pid);
	  sprintf(prub, "/proc/%d", pid);
#   ifdef SOLARIS_STRUCTURED_PROC
	  res = strlen(psib);
	  sprintf(psib + res, "/psinfo");
	  sprintf(pstb + res, "/status");
	  sprintf(prub + res, "/usage" );
#   endif
	  fd = open(psib, O_RDONLY);
	  if (fd >= 0) {
#   ifdef SOLARIS_STRUCTURED_PROC
	      res = read(fd, &psi, sizeof(psi));
              if (res == sizeof(psi))
	          ru.ru_maxrss = psi.pr_rssize * 1024;
              else
                  goto failed;
#   else  
	      res = ioctl(fd, PIOCPSINFO, &psi);
	      if (res != -1)
		  ru.ru_maxrss = psi.pr_byrssize;
              else
                  goto failed;
#   endif
              close(fd);
          } else
	    goto failed;
	  fd = open(pstb, O_RDONLY);
	  if (fd >= 0) {
#   ifdef SOLARIS_STRUCTURED_PROC
	      res = read(fd, &pst, sizeof(pst));
              res = res == sizeof(pst) ? 1 : 0;
#   else  
	      res = ioctl(fd, PIOCUSAGE, &pst);
	      res = res == -1 ? 0 : 1;
#   endif
	      if (res) {
#   ifdef SOLARIS_STRUCTURED_PROC
/* Structured proc seems to have okay values in struct psinfo but
 * zero values from the earlier getrusage() so get the better ones. */
	          if (who == RUSAGE_SELF) {
		      ru.ru_utime.tv_sec   = pst.pr_utime.tv_sec;
		      ru.ru_utime.tv_usec  = pst.pr_utime.tv_nsec  / 1000;
		      ru.ru_stime.tv_sec   = pst.pr_stime.tv_sec;
		      ru.ru_stime.tv_usec  = pst.pr_stime.tv_nsec  / 1000;
	          } else if (who == RUSAGE_CHILDREN) {
		      ru.ru_utime.tv_sec   = pst.pr_cutime.tv_sec;
		      ru.ru_utime.tv_usec  = pst.pr_cutime.tv_nsec  / 1000;
		      ru.ru_stime.tv_sec   = pst.pr_cstime.tv_sec;
		      ru.ru_stime.tv_usec  = pst.pr_cstime.tv_nsec  / 1000;
                  }
#   endif
                  /* Current values, not really integrals. */
	          ru.ru_idrss = pst.pr_brksize;
	          ru.ru_isrss = pst.pr_stksize;
	      } else
	          goto failed;
              close(fd);
          } else
              goto failed;
	  fd = open(prub, O_RDONLY);
	  if (fd >= 0) {
#   ifdef SOLARIS_STRUCTURED_PROC
	      res = read(fd, &pru, sizeof(pru));
              res = res == sizeof(pru) ? 1 : 0;
#   else  
	      res = ioctl(fd, PIOCUSAGE, &pru);
	      res = res == -1 ? 0 : 1;
#   endif
	      if (res) {
		  ru.ru_minflt   = pru.pr_minf;
		  ru.ru_majflt   = pru.pr_majf;
		  ru.ru_nswap    = pru.pr_nswap;
		  ru.ru_inblock  = pru.pr_inblk;
		  ru.ru_oublock  = pru.pr_oublk;
		  ru.ru_msgsnd   = pru.pr_msnd;
		  ru.ru_msgrcv   = pru.pr_mrcv;
		  ru.ru_nsignals = pru.pr_sigs;
		  ru.ru_nvcsw    = pru.pr_vctx;
		  ru.ru_nivcsw   = pru.pr_ictx;
	      } else
	          goto failed;
              close(fd);
	  } else
	      goto failed;
#else
	  if (getrusage(who, &ru))
              goto failed;
#endif
          EXTEND(sp, 16);
          PUSHs(sv_2mortal(newSVnv(TV2DS(ru.ru_utime))));
	  PUSHs(sv_2mortal(newSVnv(TV2DS(ru.ru_stime))));
	  PUSHs(sv_2mortal(newSViv(ru.ru_maxrss)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_ixrss)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_idrss)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_isrss)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_minflt)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_majflt)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_nswap)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_inblock)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_oublock)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_msgsnd)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_msgrcv)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_nsignals)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_nvcsw)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_nivcsw)));
	failed:
          ;
	}

void
_setpriority(which = PRIO_PROCESS,who = 0,priority = PRIO_MAX/2)
	int		which
	int		who
	int		priority
    CODE:
	{
	  if (items == 2) {
	    /* if two arguments they are (which, priority),
	     * not (which, who). who defaults to 0. */
	      priority = who;
	      who = 0;
	  }
	  ST(0) = sv_newmortal();
	  ST(0) = (setpriority(which, who, priority) == 0) ?
	    &sv_yes : &sv_undef;
	}

void
_setrlimit(resource,soft,hard)
	int	resource
	double 	soft
	double	hard
    CODE:
	{
	    struct rlimit rl;

            rl.rlim_cur = soft == -1.0 ? RLIM_INFINITY : (Rlim_t) soft;
            rl.rlim_max = hard == -1.0 ? RLIM_INFINITY : (Rlim_t) hard;

	    ST(0) = sv_newmortal();
            ST(0) = (setrlimit(resource, &rl) == 0) ? &sv_yes: &sv_undef;
	}

HV *
_get_rlimits()
    CODE:
	RETVAL = newHV();
#ifdef RLIMIT_AS
	hv_store(RETVAL, "RLIMIT_AS"       ,  9, newSViv(RLIMIT_AS),       0);
#endif
#ifdef RLIMIT_CORE
	hv_store(RETVAL, "RLIMIT_CORE"     , 11, newSViv(RLIMIT_CORE),     0);
#endif
#ifdef RLIMIT_CPU
	hv_store(RETVAL, "RLIMIT_CPU"      , 10, newSViv(RLIMIT_CPU),      0);
#endif
#ifdef RLIMIT_DATA
	hv_store(RETVAL, "RLIMIT_DATA"     , 11, newSViv(RLIMIT_DATA),     0);
#endif
#ifdef RLIMIT_FSIZE
	hv_store(RETVAL, "RLIMIT_FSIZE"    , 12, newSViv(RLIMIT_FSIZE),    0);
#endif
#ifdef RLIMIT_NOFILE
	hv_store(RETVAL, "RLIMIT_NOFILE"   , 13, newSViv(RLIMIT_NOFILE),   0);
#endif
#ifdef RLIMIT_OPEN_MAX
	hv_store(RETVAL, "RLIMIT_OPEN_MAX" , 15, newSViv(RLIMIT_OPEN_MAX), 0);
#endif
#ifdef RLIMIT_RSS
	hv_store(RETVAL, "RLIMIT_RSS"      , 10, newSViv(RLIMIT_RSS),      0);
#endif
#ifdef RLIMIT_MEMLOCK
	hv_store(RETVAL, "RLIMIT_MEMLOCK"  , 14, newSViv(RLIMIT_MEMLOCK),  0);
#endif
#ifdef RLIMIT_NPROC
	hv_store(RETVAL, "RLIMIT_NPROC"    , 12, newSViv(RLIMIT_NPROC),    0);
#endif
#ifdef RLIMIT_STACK
	hv_store(RETVAL, "RLIMIT_STACK"    , 12, newSViv(RLIMIT_STACK),    0);
#endif
#ifdef RLIMIT_VMEM
	hv_store(RETVAL, "RLIMIT_VMEM"     , 11, newSViv(RLIMIT_VMEM),     0);
#endif
    OUTPUT:
	RETVAL
