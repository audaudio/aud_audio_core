// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// The monotonic host clock in nanoseconds (decision time-001): the clock the
// engine measures against on every platform. Header only, so every package
// reads the same clock without linking the core.

#ifndef AUD_CLOCK_H
#define AUD_CLOCK_H

#include <stdint.h>

#if _WIN32
#include <windows.h>
#else
#include <time.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Returns the monotonic host time in nanoseconds. On Apple platforms this is
// the clock of mach_absolute_time, the one Ableton Link measures against;
// CLOCK_MONOTONIC there only has microsecond resolution.
static inline int64_t aud_clock_now_ns(void) {
#if _WIN32
  LARGE_INTEGER frequency;
  LARGE_INTEGER counter;
  QueryPerformanceFrequency(&frequency);
  QueryPerformanceCounter(&counter);
  return (int64_t)((double)counter.QuadPart * 1e9 / (double)frequency.QuadPart);
#elif __APPLE__
  return (int64_t)clock_gettime_nsec_np(CLOCK_UPTIME_RAW);
#else
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (int64_t)ts.tv_sec * 1000000000LL + (int64_t)ts.tv_nsec;
#endif
}

#ifdef __cplusplus
}
#endif

#endif  // AUD_CLOCK_H
