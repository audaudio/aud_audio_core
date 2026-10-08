// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// Conversions between the time domains over a transport snapshot
// (decision time-001): beat, sample and host time of a frame inside the
// block, and the resolution of a timestamp of any domain to a frame
// offset. Header only; nothing here allocates, so the audio thread may
// call every function.

#ifndef AUD_TRANSPORT_H
#define AUD_TRANSPORT_H

#include <math.h>
#include <stdint.h>

#include "aud_abi.h"

#ifdef __cplusplus
extern "C" {
#endif

// Beats as a double from ticks.
static inline double aud_beats_from_ticks(int64_t ticks) {
  return (double)ticks / (double)AUD_BEAT_FACTOR;
}

// Ticks from beats, rounded to the nearest tick.
static inline int64_t aud_ticks_from_beats(double beats) {
  return (int64_t)llround(beats * (double)AUD_BEAT_FACTOR);
}

// The segment that covers a frame offset: the last one starting at or
// before it; NULL without segments.
static inline const AudTransportSegment* aud_transport_segment_at(
    const AudTransportSnapshot* snapshot, uint32_t sample_offset) {
  const AudTransportSegment* found = 0;
  uint32_t i;
  for (i = 0; i < snapshot->num_segments; ++i) {
    const AudTransportSegment* segment = &snapshot->segments[i];
    if (segment->sample_offset <= sample_offset) found = segment;
  }
  return found;
}

// The beats a segment advances in its first `frames` frames.
static inline double aud_transport_beats_after(
    const AudTransportSegment* segment, double sample_rate, double frames) {
  if (!(segment->flags & AUD_SEGMENT_PLAYING)) return 0;
  return (segment->tempo * frames +
          segment->tempo_increment * frames * frames / 2) /
         (60.0 * sample_rate);
}

// The musical position at a frame offset of the block, in ticks.
static inline int32_t aud_transport_beat_at_offset(
    const AudTransportSnapshot* snapshot, uint32_t sample_offset,
    int64_t* beat) {
  const AudTransportSegment* segment =
      aud_transport_segment_at(snapshot, sample_offset);
  if (!segment) return AUD_ERROR_UNSUPPORTED;
  const double frames = (double)(sample_offset - segment->sample_offset);
  const double beats =
      aud_transport_beats_after(segment, snapshot->time.sample_rate, frames);
  *beat = segment->beat + aud_ticks_from_beats(beats);
  return AUD_OK;
}

// The frames a playing segment needs to advance `beats`, or a negative
// number when the tempo slope never reaches them.
static inline double aud_transport_frames_for_beats(
    const AudTransportSegment* segment, double sample_rate, double beats) {
  const double distance = beats * 60.0 * sample_rate;
  if (segment->tempo_increment == 0) {
    return segment->tempo > 0 ? distance / segment->tempo : -1;
  }
  const double discriminant =
      segment->tempo * segment->tempo + 2 * segment->tempo_increment * distance;
  if (discriminant < 0) return -1;
  return (-segment->tempo + sqrt(discriminant)) / segment->tempo_increment;
}

// The first frame offset of the block whose musical position reaches
// `beat`: AUD_OK with the offset, AUD_ERROR_LATE when the beat lies before
// the block, AUD_PENDING when it lies after it, AUD_ERROR_UNSUPPORTED
// without a playing segment.
static inline int32_t aud_transport_offset_at_beat(
    const AudTransportSnapshot* snapshot, int64_t beat, int64_t* offset) {
  int playing = 0;
  uint32_t i;
  for (i = 0; i < snapshot->num_segments; ++i) {
    const AudTransportSegment* segment = &snapshot->segments[i];
    if (!(segment->flags & AUD_SEGMENT_PLAYING)) continue;
    const double beats = aud_beats_from_ticks(beat - segment->beat);
    if (beats < 0) return playing ? AUD_PENDING : AUD_ERROR_LATE;
    playing = 1;
    const double frames = aud_transport_frames_for_beats(
        segment, snapshot->time.sample_rate, beats);
    if (frames < 0) continue;
    const double rounded = ceil(frames - 1e-9);
    if (rounded < (double)segment->frames) {
      *offset = (int64_t)segment->sample_offset + (int64_t)rounded;
      return AUD_OK;
    }
  }
  return playing ? AUD_PENDING : AUD_ERROR_UNSUPPORTED;
}

// The host time at which a frame offset of the block reaches the output;
// AUD_ERROR_UNSUPPORTED without a host time.
static inline int32_t aud_transport_host_time_at_offset(
    const AudTransportSnapshot* snapshot, uint32_t sample_offset,
    int64_t* host_time_ns) {
  const AudStreamTime* time = &snapshot->time;
  if (time->host_time_source == AUD_TIME_SOURCE_NONE) {
    return AUD_ERROR_UNSUPPORTED;
  }
  *host_time_ns = time->host_time_ns +
                  (int64_t)llround((double)sample_offset * 1e9 / time->sample_rate);
  return AUD_OK;
}

// The frame offset of the block that reaches the output at a host time:
// AUD_OK with the offset, AUD_ERROR_LATE before the block, AUD_PENDING
// after it, AUD_ERROR_UNSUPPORTED without a host time.
static inline int32_t aud_transport_offset_at_host_time(
    const AudTransportSnapshot* snapshot, int64_t host_time_ns,
    int64_t* offset) {
  const AudStreamTime* time = &snapshot->time;
  if (time->host_time_source == AUD_TIME_SOURCE_NONE) {
    return AUD_ERROR_UNSUPPORTED;
  }
  const double frames =
      (double)(host_time_ns - time->host_time_ns) * time->sample_rate / 1e9;
  const double rounded = ceil(frames - 1e-9);
  if (rounded < 0) return AUD_ERROR_LATE;
  if (rounded >= (double)time->frames) return AUD_PENDING;
  *offset = (int64_t)rounded;
  return AUD_OK;
}

// Resolves a timestamp of any domain to a frame offset of the block.
// Immediate resolves to 0. Returns AUD_OK, AUD_ERROR_LATE (before the
// block; the engine plays it at offset 0 with a diagnostic or drops it),
// AUD_PENDING (after the block), AUD_ERROR_UNSUPPORTED (a domain the
// snapshot cannot convert) or AUD_ERROR_INVALID_ARGUMENT.
static inline int32_t aud_transport_resolve(const AudTransportSnapshot* snapshot,
                                            const AudTimestamp* timestamp,
                                            int64_t* offset) {
  switch (timestamp->domain) {
    case AUD_TIME_IMMEDIATE:
      *offset = 0;
      return AUD_OK;
    case AUD_TIME_SAMPLE: {
      const int64_t relative =
          timestamp->value - snapshot->time.sample_position;
      if (relative < 0) return AUD_ERROR_LATE;
      if (relative >= (int64_t)snapshot->time.frames) return AUD_PENDING;
      *offset = relative;
      return AUD_OK;
    }
    case AUD_TIME_HOST:
      return aud_transport_offset_at_host_time(snapshot, timestamp->value,
                                               offset);
    case AUD_TIME_BEAT:
      return aud_transport_offset_at_beat(snapshot, timestamp->value, offset);
    default:
      return AUD_ERROR_INVALID_ARGUMENT;
  }
}

#ifdef __cplusplus
}
#endif

#endif  // AUD_TRANSPORT_H
