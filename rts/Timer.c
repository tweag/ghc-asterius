/* -----------------------------------------------------------------------------
 *
 * (c) The GHC Team, 1995-2005
 *
 * Interval timer service for profiling and pre-emptive scheduling.
 *
 * ---------------------------------------------------------------------------*/

/*
 * The interval timer is used for profiling and for context switching in the
 * threaded build.
 *
 * This file defines the platform-independent view of interval timing, relying
 * on platform-specific services to install and run the timers.
 *
 */

#include "PosixSource.h"
#include "Rts.h"

#include "Timer.h"
#include "Proftimer.h"
#include "Schedule.h"
#include "Ticker.h"
#include "Capability.h"
#include "RtsSignals.h"

// This global counter is used to allow multiple threads to stop the
// timer temporarily with a stopTimer()/startTimer() pair.  If
//      timer_enabled  == 0          timer is enabled
//      timer_disabled == N, N > 0   timer is disabled by N threads
// When timer_enabled makes a transition to 0, we enable the timer,
// and when it makes a transition to non-0 we disable it.

static StgWord timer_disabled;

/* ticks left before next pre-emptive context switch */
static int ticks_to_ctxt_switch = 0;

/* idle ticks left before GC allowed */
static int idle_ticks_to_gc = 0;

/* inter-idle GC ticks left before GC allowed  */
static int inter_gc_ticks_to_gc = 0;

/*
 * Function: handle_tick()
 *
 * At each occurrence of a tick, the OS timer will invoke
 * handle_tick().
 */
static
void
handle_tick(int unused STG_UNUSED)
{
  handleProfTick();
  if (RtsFlags.ConcFlags.ctxtSwitchTicks > 0
      && SEQ_CST_LOAD(&timer_disabled) == 0)
  {
      ticks_to_ctxt_switch--;
      if (ticks_to_ctxt_switch <= 0) {
          ticks_to_ctxt_switch = RtsFlags.ConcFlags.ctxtSwitchTicks;
          contextSwitchAllCapabilities(); /* schedule a context switch */
      }
  }

  /*
   * If we've been inactive for idleGCDelayTime (set by +RTS
   * -I), tell the scheduler to wake up and do a GC, to check
   * for threads that are deadlocked.  However, ensure we wait
   * at least interIdleGCWait (+RTS -Iw) between idle GCs.
   */
  switch (SEQ_CST_LOAD(&recent_activity)) {
  case ACTIVITY_YES:
      SEQ_CST_STORE(&recent_activity, ACTIVITY_MAYBE_NO);
      idle_ticks_to_gc = RtsFlags.GcFlags.idleGCDelayTime /
                         RtsFlags.MiscFlags.tickInterval;
      break;
  case ACTIVITY_MAYBE_NO:
      if (idle_ticks_to_gc == 0 && inter_gc_ticks_to_gc == 0) {
          if (RtsFlags.GcFlags.doIdleGC) {
              SEQ_CST_STORE(&recent_activity, ACTIVITY_INACTIVE);
              inter_gc_ticks_to_gc = RtsFlags.GcFlags.interIdleGCWait /
                                       RtsFlags.MiscFlags.tickInterval;
#if defined(THREADED_RTS)
              wakeUpRts();
              // The scheduler will call stopTimer() when it has done
              // the GC.
#endif
          } else {
              SEQ_CST_STORE(&recent_activity, ACTIVITY_DONE_GC);
              // disable timer signals (see #1623, #5991, #9105)
              // but only if we're not profiling (e.g. passed -h or -p RTS
              // flags). If we are profiling we need to keep the timer active
              // so that samples continue to be collected.
#if defined(PROFILING)
              if (!(RtsFlags.ProfFlags.doHeapProfile
                    || RtsFlags.CcFlags.doCostCentres)) {
                  stopTimer();
              }
#else
              stopTimer();
#endif
          }
      } else {
              if (idle_ticks_to_gc) idle_ticks_to_gc--;
              if (inter_gc_ticks_to_gc) inter_gc_ticks_to_gc--;
      }
      break;
  default:
      break;
  }
}

void
initTimer(void)
{
}

void
startTimer(void)
{
}

void
stopTimer(void)
{
}

void
exitTimer (bool wait)
{
}
