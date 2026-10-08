// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// The native entry points of aud_audio_core for the Dart side: the ABI
// version and struct sizes (so Dart can check that it agrees with C), the
// handle APIs of the time filter, the transport conversions, the UMP
// helpers, the parameter ramp and the fixed-block adapter, and the
// registration of the reference node `aud.core.gain`. DSP packages never
// link this library; they include the headers.

#ifndef AUD_AUDIO_CORE_H
#define AUD_AUDIO_CORE_H

#include <stddef.h>
#include <stdint.h>

#include "aud_abi.h"

#ifdef __cplusplus
extern "C" {
#endif

// The type id of the reference gain node the core registers.
#define AUD_CORE_GAIN_TYPE_ID "aud.core.gain"

// The parameter index of the gain of `aud.core.gain`.
#define AUD_CORE_GAIN_PARAM_GAIN 0

// The state version `aud.core.gain` writes.
#define AUD_CORE_GAIN_STATE_VERSION 1

// ............................................................................
// ABI version and layout

// The major ABI version compiled into the native core.
AUD_EXPORT int32_t aud_abi_version_major(void);

// The minor ABI version compiled into the native core.
AUD_EXPORT int32_t aud_abi_version_minor(void);

// sizeof an ABI struct by its name, e.g. "AudEvent", as the C compiler
// lays it out; -1 for an unknown name.
AUD_EXPORT int32_t aud_abi_sizeof(const char* struct_name);

// aud_abi_is_compatible of aud_abi.h as an exported function.
AUD_EXPORT int32_t aud_abi_compatible(uint32_t package_major,
                                      uint32_t package_minor,
                                      uint32_t engine_major,
                                      uint32_t engine_minor);

// ............................................................................
// The clock (aud_clock.h)

// The monotonic host time in nanoseconds, aud_clock_now_ns of aud_clock.h.
AUD_EXPORT int64_t aud_core_clock_now_ns(void);

// ............................................................................
// The time filter (aud_time_filter.h)

typedef struct AudCoreTimeFilter AudCoreTimeFilter;

AUD_EXPORT AudCoreTimeFilter* aud_core_time_filter_create(double sample_rate,
                                                          uint32_t window);
AUD_EXPORT void aud_core_time_filter_destroy(AudCoreTimeFilter* filter);
AUD_EXPORT void aud_core_time_filter_reset(AudCoreTimeFilter* filter);
AUD_EXPORT void aud_core_time_filter_set_deviation_limit(
    AudCoreTimeFilter* filter, int64_t limit_ns);
AUD_EXPORT int32_t aud_core_time_filter_add(AudCoreTimeFilter* filter,
                                            int64_t sample_position,
                                            uint32_t frames,
                                            int64_t host_time_ns);
AUD_EXPORT int32_t aud_core_time_filter_is_valid(const AudCoreTimeFilter* filter);
AUD_EXPORT double aud_core_time_filter_ns_per_sample(
    const AudCoreTimeFilter* filter);
AUD_EXPORT int64_t aud_core_time_filter_host_time_at(
    const AudCoreTimeFilter* filter, int64_t sample_position);
AUD_EXPORT int64_t aud_core_time_filter_sample_at(const AudCoreTimeFilter* filter,
                                                  int64_t host_time_ns);
AUD_EXPORT uint32_t aud_core_time_filter_count(const AudCoreTimeFilter* filter);
AUD_EXPORT uint32_t aud_core_time_filter_resets(const AudCoreTimeFilter* filter);

// ............................................................................
// Transport conversions (aud_transport.h)

AUD_EXPORT int32_t aud_core_transport_beat_at_offset(
    const AudTransportSnapshot* snapshot, uint32_t sample_offset,
    int64_t* beat);
AUD_EXPORT int32_t aud_core_transport_offset_at_beat(
    const AudTransportSnapshot* snapshot, int64_t beat, int64_t* offset);
AUD_EXPORT int32_t aud_core_transport_host_time_at_offset(
    const AudTransportSnapshot* snapshot, uint32_t sample_offset,
    int64_t* host_time_ns);
AUD_EXPORT int32_t aud_core_transport_offset_at_host_time(
    const AudTransportSnapshot* snapshot, int64_t host_time_ns,
    int64_t* offset);
AUD_EXPORT int32_t aud_core_transport_resolve(
    const AudTransportSnapshot* snapshot, const AudTimestamp* timestamp,
    int64_t* offset);

// ............................................................................
// UMP helpers (aud_ump.h)

AUD_EXPORT uint32_t aud_core_ump_word_count(uint32_t word0);
AUD_EXPORT uint32_t aud_core_ump_message_type(uint32_t word0);
AUD_EXPORT uint32_t aud_core_ump_group(uint32_t word0);
AUD_EXPORT uint32_t aud_core_ump_status(uint32_t word0);
AUD_EXPORT uint32_t aud_core_ump_channel(uint32_t word0);
AUD_EXPORT uint32_t aud_core_ump_note(uint32_t word0);
AUD_EXPORT int32_t aud_core_ump_is_note_on(uint32_t word0, uint32_t word1);
AUD_EXPORT int32_t aud_core_ump_is_note_off(uint32_t word0, uint32_t word1);
AUD_EXPORT float aud_core_ump_note_velocity(uint32_t word0, uint32_t word1);
AUD_EXPORT int32_t aud_core_ump_is_per_note_controller(uint32_t word0);
AUD_EXPORT uint32_t aud_core_ump_per_note_controller_index(uint32_t word0);
AUD_EXPORT float aud_core_ump_unit_value(uint32_t word1);
AUD_EXPORT uint32_t aud_core_ump_midi1_word(uint32_t group, uint32_t status_byte,
                                            uint32_t data1, uint32_t data2);
AUD_EXPORT void aud_core_ump_midi2_note(uint32_t group, uint32_t channel,
                                        int32_t note_on, uint32_t note,
                                        uint32_t velocity16,
                                        uint32_t attribute_type,
                                        uint32_t attribute16, uint32_t* words);
AUD_EXPORT void aud_core_ump_midi2_per_note_controller(
    uint32_t group, uint32_t channel, uint32_t note, uint32_t index,
    uint32_t value32, uint32_t* words);

// ............................................................................
// The parameter ramp (aud_param_ramp.hpp)

typedef struct AudCoreParamRamp AudCoreParamRamp;

AUD_EXPORT AudCoreParamRamp* aud_core_param_ramp_create(float value);
AUD_EXPORT void aud_core_param_ramp_destroy(AudCoreParamRamp* ramp);
AUD_EXPORT void aud_core_param_ramp_set(AudCoreParamRamp* ramp, float value);
AUD_EXPORT void aud_core_param_ramp_set_target(AudCoreParamRamp* ramp,
                                               float target, uint32_t frames);
AUD_EXPORT void aud_core_param_ramp_advance(AudCoreParamRamp* ramp,
                                            uint32_t frames);
AUD_EXPORT float aud_core_param_ramp_value(const AudCoreParamRamp* ramp);
AUD_EXPORT float aud_core_param_ramp_target(const AudCoreParamRamp* ramp);
AUD_EXPORT int32_t aud_core_param_ramp_is_ramping(const AudCoreParamRamp* ramp);
AUD_EXPORT uint32_t aud_core_param_ramp_remaining(const AudCoreParamRamp* ramp);

// ............................................................................
// The fixed-block adapter (aud_fixed_block_adapter.hpp)

typedef struct AudCoreFixedBlockAdapter AudCoreFixedBlockAdapter;

// Renders one fixed block of `block_size` frames from `in` to `out`.
typedef void (*AudCoreRenderBlockFunction)(void* user, const float* const* in,
                                           float* const* out,
                                           uint32_t block_size);

AUD_EXPORT AudCoreFixedBlockAdapter* aud_core_fixed_block_adapter_create(
    uint32_t block_size, uint32_t channels);
AUD_EXPORT void aud_core_fixed_block_adapter_destroy(
    AudCoreFixedBlockAdapter* adapter);
AUD_EXPORT uint32_t aud_core_fixed_block_adapter_latency(
    const AudCoreFixedBlockAdapter* adapter);
AUD_EXPORT void aud_core_fixed_block_adapter_reset(
    AudCoreFixedBlockAdapter* adapter);
AUD_EXPORT void aud_core_fixed_block_adapter_process(
    AudCoreFixedBlockAdapter* adapter, const float* const* in,
    float* const* out, uint32_t frames, AudCoreRenderBlockFunction render,
    void* user);

// ............................................................................
// The reference node

// Registers `aud.core.gain` with the host: a gain with a ramped parameter
// built on AudNodeBase, the proof of the base class and the pattern every
// DSP package follows. AUD_OK or an error code.
AUD_EXPORT int32_t aud_audio_core_register(const AudHostApi* host);

#ifdef __cplusplus
}
#endif

#endif  // AUD_AUDIO_CORE_H
