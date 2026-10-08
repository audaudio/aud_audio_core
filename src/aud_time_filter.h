// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// The sample-to-host-time filter of decision time-001: a least-squares fit
// over a window of callback timestamps turns the jittering host times the
// stream reports into a stable mapping between sample positions and host
// time. Our own implementation, not Link's HostTimeFilter. Header only;
// the callback thread adds one point per block and converts without
// allocation.
//
// Reset rules: the caller resets on device and route changes,
// interruptions, sample-rate changes and stream restarts; the filter
// resets itself when the sample position is discontinuous (a callback does
// not start where the previous one ended) or when a host time deviates
// from the prediction by more than the deviation limit. After a reset the
// nominal rate maps through the first point until the fit converges.

#ifndef AUD_TIME_FILTER_H
#define AUD_TIME_FILTER_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// The largest window of points a filter keeps.
#define AUD_TIME_FILTER_MAX_POINTS 512

// The default window: about ten seconds of 20 ms blocks.
#define AUD_TIME_FILTER_DEFAULT_WINDOW 512

// The default deviation limit in nanoseconds: a quarter of a second.
#define AUD_TIME_FILTER_DEFAULT_DEVIATION_NS 250000000LL

typedef struct AudTimeFilter {
  uint32_t struct_size;
  uint32_t window;  // points used for the fit, 2 .. AUD_TIME_FILTER_MAX_POINTS
  uint32_t count;   // points stored
  uint32_t next;    // ring index of the next point
  int64_t samples[AUD_TIME_FILTER_MAX_POINTS];
  int64_t host_ns[AUD_TIME_FILTER_MAX_POINTS];
  int64_t expected_sample;  // where the next callback has to start
  int64_t deviation_limit_ns;
  double nominal_ns_per_sample;
  double ns_per_sample;  // slope of the fit
  int64_t sample_origin;  // the fit runs through (sample_origin, host_origin)
  int64_t host_origin;
  uint32_t resets;  // resets since init, for diagnostics
  uint32_t reserved;
} AudTimeFilter;

// Forgets every point; the window, the rate and the limits stay.
static inline void aud_time_filter_reset(AudTimeFilter* filter) {
  filter->count = 0;
  filter->next = 0;
  filter->expected_sample = 0;
  filter->ns_per_sample = filter->nominal_ns_per_sample;
  filter->sample_origin = 0;
  filter->host_origin = 0;
}

// Initializes a filter for a sample rate with a window of points.
static inline void aud_time_filter_init(AudTimeFilter* filter,
                                        double sample_rate, uint32_t window) {
  filter->struct_size = (uint32_t)sizeof(AudTimeFilter);
  if (window < 2) window = 2;
  if (window > AUD_TIME_FILTER_MAX_POINTS) window = AUD_TIME_FILTER_MAX_POINTS;
  filter->window = window;
  filter->deviation_limit_ns = AUD_TIME_FILTER_DEFAULT_DEVIATION_NS;
  filter->nominal_ns_per_sample = 1e9 / sample_rate;
  filter->resets = 0;
  filter->reserved = 0;
  aud_time_filter_reset(filter);
}

// Whether the filter maps: it holds at least one point.
static inline int aud_time_filter_is_valid(const AudTimeFilter* filter) {
  return filter->count > 0;
}

// The fitted host nanoseconds per sample; the nominal rate until two
// points exist.
static inline double aud_time_filter_ns_per_sample(
    const AudTimeFilter* filter) {
  return filter->ns_per_sample;
}

// The host time at which a sample position reaches the output.
static inline int64_t aud_time_filter_host_time_at(const AudTimeFilter* filter,
                                                   int64_t sample_position) {
  const double delta = (double)(sample_position - filter->sample_origin);
  return filter->host_origin + (int64_t)(delta * filter->ns_per_sample + 0.5);
}

// The sample position that reaches the output at a host time.
static inline int64_t aud_time_filter_sample_at(const AudTimeFilter* filter,
                                                int64_t host_time_ns) {
  const double delta = (double)(host_time_ns - filter->host_origin);
  return filter->sample_origin +
         (int64_t)(delta / filter->ns_per_sample + 0.5);
}

// Fits a line through the stored points, in coordinates relative to the
// oldest point so that the sums stay small.
static inline void aud_time_filter_fit(AudTimeFilter* filter) {
  const uint32_t n = filter->count;
  const uint32_t oldest = (filter->next + filter->window - n) % filter->window;
  const int64_t x0 = filter->samples[oldest];
  const int64_t y0 = filter->host_ns[oldest];
  double sx = 0, sy = 0, sxx = 0, sxy = 0;
  uint32_t i;
  for (i = 0; i < n; ++i) {
    const uint32_t index = (oldest + i) % filter->window;
    const double x = (double)(filter->samples[index] - x0);
    const double y = (double)(filter->host_ns[index] - y0);
    sx += x;
    sy += y;
    sxx += x * x;
    sxy += x * y;
  }
  const double denominator = (double)n * sxx - sx * sx;
  double slope = filter->nominal_ns_per_sample;
  if (n >= 2 && denominator > 0) slope = ((double)n * sxy - sx * sy) / denominator;
  // The line runs through the mean point.
  const double mean_x = sx / (double)n;
  const double mean_y = sy / (double)n;
  filter->ns_per_sample = slope;
  filter->sample_origin = x0;
  filter->host_origin = y0 + (int64_t)(mean_y - slope * mean_x + 0.5);
}

// Adds the timestamps of a callback: the block's sample position, its
// frames and the host time at which its first frame reaches the output.
// Resets first on a discontinuity of the sample position or a host time
// beyond the deviation limit; returns 1 when it reset.
static inline int aud_time_filter_add(AudTimeFilter* filter,
                                      int64_t sample_position, uint32_t frames,
                                      int64_t host_time_ns) {
  int reset = 0;
  if (filter->count > 0) {
    const int64_t predicted =
        aud_time_filter_host_time_at(filter, sample_position);
    const int64_t deviation = host_time_ns > predicted ? host_time_ns - predicted
                                                        : predicted - host_time_ns;
    if (sample_position != filter->expected_sample ||
        deviation > filter->deviation_limit_ns) {
      aud_time_filter_reset(filter);
      filter->resets += 1;
      reset = 1;
    }
  }
  filter->samples[filter->next] = sample_position;
  filter->host_ns[filter->next] = host_time_ns;
  filter->next = (filter->next + 1) % filter->window;
  if (filter->count < filter->window) filter->count += 1;
  filter->expected_sample = sample_position + (int64_t)frames;
  aud_time_filter_fit(filter);
  return reset;
}

#ifdef __cplusplus
}
#endif

#endif  // AUD_TIME_FILTER_H
