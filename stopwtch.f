C     STOPWTCH.F - Stopwatch timing routine for NEC2D
C     This file contains the stopwatch subroutine that provides CPU and
C     wall clock timing functionality for performance measurement.
C
        subroutine stopwtch(cputot,walltot,cpusplt,wallsplt)
        use nec2_common
c
c       This routine operates as a stopwatch.
c       When first called, the routine initializes the clock.
c       On subsequent calls, the routine returns:
c
c       Outputs: cputot   -- elapsed CPU time since initialization
c                walltot  -- elapsed wallclock time since initialization
c                cpusplt  -- split (delta) CPU time since previous call
c                wallsplt -- split wallclock time since previous call
c
c       These outputs will all be zero (or very close to it) on the
c       first (initialization) call.
c
c       Internal times (cpuinit,wallinit,cpunow,wallnow) are stored in
c       seconds.  cpuinit  and cpunow  are stored as reals,
c                 wallinit and wallnow are stored as integers.
c       Output times are converted to real minutes.
c
c History:
c   Date       Author            Reason
c   ---------  ----------------  ------------------------------------
c    early-90  Scott L. Ray      initial version
c      mid-90  Scott L. Ray      support for additional machines
c   14-JAN-91                    ---- Version 2.2/release    ----
c   23-MAY-91  Scott L. Ray      UNICOS branch
c   29-JAN-92  Scott L. Ray      FPS and NLTSS support dropped
c   29-JAN-92  Scott L. Ray      switch to cpp conditional compilation
c   18-SEP-92      Conditional compilation disabled for use in NEC
c
c  (C) Copyright 1990, 1992.
c  The Regents of the University of California.  All rights reserved.
c ----------------------------------------------------------------------
c
c parameter list
c
        real cputot,walltot,cpusplt,wallsplt
c
c locals (non sysdep)
c
        logical initiz
        integer wallinit,walllast,wallnow
        real cpuinit,cpulast,cpunow
        save initiz,cpuinit,cpulast,wallinit,walllast
c
c locals (sysdep)
c
C#include "machines.h"
C#ifdef VAX_VMS
C        integer istatus,iwall,icpu
C        real rwall
C        dimension iwall(2)
C#endif
C#ifdef SUN4TIMER
        integer time
        real tarray
        dimension tarray(2)
C#endif
C#ifdef CONVEX
C        real time, secnds, tarray
C        dimension tarray(2)
C        external secnds
C#endif
C#ifdef IBM_RISC
c        integer icpu
c        integer mclock
C#endif
C#ifdef IRIS4D
C        external time
C#endif
C#ifdef STARDENT
C        integer stime
C        real tarray
C        dimension tarray(2)
C#endif
C#ifdef UNICOS
C        real rwall
C#endif
c
c data initialization
c
        data initiz/.false./
c
c ----------------------------------------------------------------------
c
        if (.not. initiz) then
c
c ...      set the flag showing that the clock has been initialized
c
           initiz = .true.
c
c ...      set the initial times to default value of zero.  These may
c          be changed, depending on how an individual machine handles
c          its timer.
c
           cpuinit  = 0.0
           wallinit = 0
c
c ...      initialize the timer (may not be necessary on all machines)
c
C#ifdef VAX_VMS
C           istatus = lib$init_timer()
C#endif
c
C#ifdef SUN4TIMER
c          CPU timer on SUN4 initializes automatically on job startup.
c          However, we want t=0 to be defined when this routine is first
c          called.  Hence, define initial CPU time here.
c          Wall clock timer counts in seconds from 1-Jan-70  Thus,
c          initial wall clock time is non-zero.  It is obtained here.
c
           cpuinit  = etime(tarray)
           wallinit = time()
C#endif
c
C#ifdef CONVEX
C           cpuinit = etime(tarray)
C           time = secnds(0.0)
C           wallinit = ifix(time)
C#endif
c
C#ifdef IBM_RISC
c          no known wall clock timer
c
c           icpu = mclock( )
c           cpuinit  = float(icpu)/100.0
c           wallinit = 0
C#endif
c
C#ifdef STARDENT
c          CPU timer on STARDENT initializes automatically on job
c          startup.
c          However, we want t=0 to be defined when this routine is first
c          called.  Hence, define initial CPU time here.
c          Wall clock timer counts in seconds from 1-Jan-70  Thus,
c          initial wall clock time is non-zero.  It is obtained here.
c
C           cpuinit  = etime(tarray)
C           wallinit = stime()
C#endif
c
C#ifdef UNICOS
c          I hope that the "second" routine is true UNICOS and not a
c          local (LLNL) feature that was added on to keep things
c          consistent with NLTSS.
c          The "timef" routine returns real milliseconds; first
c          call initializes the timer and should return zero (not
c          that we care -- this routine works by taking differences).
c
C           call second(cpuinit)
C           call timef(rwall)
C           wallinit = ifix(rwall*1.0e-03)
C#endif
c
c ...      since this is the first call to this routine,
c          initialize the previous call times to the initial time.
c
           cpulast  =  cpuinit
           walllast = wallinit
c
        end if
c
c ...   Find the current cpu and wall times
c
C#ifdef HASTIMER
C#ifdef VAX_VMS
c
c       function "lib$stat_timer" is called as:
c       error_status = lib$stat_timer(input_code,output_result,junk)
c       where,
c        input_code = 1 returns elapsed wall clock time in VAX_VMS
c           binary internal format.  This format takes 64 bits to store,
c           hence output_result should be a 32 bit integer array of
c           length 2.
c           This internal format is converted to a floating point number
c           by calling "lib$cvtf_from_internal_time".  This function
c           is poorly documented in the VAX_VMS manuals.  Here are some
c           details:  First argument = 28 ==> result in real hours
c                                    = 29 ==> result in real minutes
c                                    = 30 ==> result in real seconds
c           The input to "lib$cvtf_from_internal_time" goes in the 3rd
c           argument, the result is returned in the 2nd argument.
c           input_code = 2 returns elapsed cpu time as an integer in
c           units of 10msec.  This is converted to seconds here.
c
C        istatus = lib$stat_timer(1,iwall,)
C        istatus = lib$cvtf_from_internal_time(30,rwall,iwall)
C        wallnow = rwall
C        istatus = lib$stat_timer(2,icpu,)
C        cpunow = icpu*(10.0e-3)
C#endif
c
C#ifdef SUN4TIMER
c       there is some ambiguity in the manual as to how to use
c       etime.  Function returns:
c          "elapsed execution time" = tarray(1) + tarray(2)
c                                   = user time + system time
c       I am uncertain whether to let cpunow = return value or
c       else tarray(1).
c
        cpunow  = etime(tarray)
        wallnow = time()
C#endif
c
C#ifdef CONVEX
C           cpunow = etime(tarray)
C           time = secnds(0.0)
C           wallnow = ifix(time)
C#endif
c
C#ifdef IBM_RISC
c       no known wall clock timer
c
c        icpu = mclock( )
c        cpunow  = float(icpu)/100.0
c        wallnow = 0
C#endif
c
C#ifdef STARDENT
c       there is some ambiguity in the manual as to how to use
c       etime.  Function returns:
c          "elapsed execution time" = tarray(1) + tarray(2)
c                                   = user time + system time
c       I am uncertain whether to let cpunow = return value or
c       else tarray(1).
c
C        cpunow  = etime(tarray)
C        wallnow = stime()
C#endif
c
C#ifdef UNICOS
c       I hope that the "second" routine is true UNICOS and not a
c       local (LLNL) feature that was added on to keep things
c       consistent with NLTSS.
c       The "timef" routine returns real milliseconds.
c
C        call second(cpunow)
C        call timef(rwall)
C        wallnow = ifix(rwall*1.0e-03)
C#endif
C#else
c       for machines without timers or with unknown timers,
c       set things to zero now to ensure that something is returned
C        cpunow  = 0.0
C        wallnow = 0
C#endif
c
c ...   calculate elapsed and split cpu and wall clock times,
c       convert to minutes on output.
c
        cputot   = (cpunow  - cpuinit )/60.0
        walltot  = float(wallnow - wallinit)/60.0
        cpusplt  = (cpunow  - cpulast )/60.0
        wallsplt = float(wallnow - walllast)/60.0
c
c ...   save "now" times in "last" times
c
        cpulast  = cpunow
        walllast = wallnow
c
        return
c **********************************************************************
        end
