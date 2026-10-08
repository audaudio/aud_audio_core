// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

#include "aud_audio_core.h"

#include <algorithm>
#include <cstring>
#include <new>

#include "aud_clock.h"
#include "aud_fixed_block_adapter.hpp"
#include "aud_node_base.hpp"
#include "aud_param_ramp.hpp"
#include "aud_time_filter.h"
#include "aud_transport.h"
#include "aud_ump.h"

// ............................................................................
// ABI version and layout

AUD_EXPORT int32_t aud_abi_version_major(void) { return AUD_ABI_VERSION_MAJOR; }

AUD_EXPORT int32_t aud_abi_version_minor(void) { return AUD_ABI_VERSION_MINOR; }

AUD_EXPORT int32_t aud_abi_sizeof(const char* struct_name) {
  struct Entry {
    const char* name;
    size_t size;
  };
  static const Entry entries[] = {
      {"AudTimestamp", sizeof(AudTimestamp)},
      {"AudStreamTime", sizeof(AudStreamTime)},
      {"AudTransportSegment", sizeof(AudTransportSegment)},
      {"AudTransportSnapshot", sizeof(AudTransportSnapshot)},
      {"AudTransportRequest", sizeof(AudTransportRequest)},
      {"AudTransportProviderVTable", sizeof(AudTransportProviderVTable)},
      {"AudEvent", sizeof(AudEvent)},
      {"AudBusDescriptor", sizeof(AudBusDescriptor)},
      {"AudEventPortDescriptor", sizeof(AudEventPortDescriptor)},
      {"AudParamDescriptor", sizeof(AudParamDescriptor)},
      {"AudStringKeyDescriptor", sizeof(AudStringKeyDescriptor)},
      {"AudAudioBus", sizeof(AudAudioBus)},
      {"AudPrepareInfo", sizeof(AudPrepareInfo)},
      {"AudProcessContext", sizeof(AudProcessContext)},
      {"AudNodeVTable", sizeof(AudNodeVTable)},
      {"AudNodeDescriptor", sizeof(AudNodeDescriptor)},
      {"AudHostApi", sizeof(AudHostApi)},
      {"AudRenderRequest", sizeof(AudRenderRequest)},
  };
  if (!struct_name) return -1;
  for (const Entry& entry : entries) {
    if (std::strcmp(entry.name, struct_name) == 0) {
      return static_cast<int32_t>(entry.size);
    }
  }
  return -1;
}

AUD_EXPORT int32_t aud_abi_compatible(uint32_t package_major,
                                      uint32_t package_minor,
                                      uint32_t engine_major,
                                      uint32_t engine_minor) {
  return aud_abi_is_compatible(package_major, package_minor, engine_major,
                               engine_minor);
}

// ............................................................................
// The clock

AUD_EXPORT int64_t aud_core_clock_now_ns(void) { return aud_clock_now_ns(); }

// ............................................................................
// The time filter

static AudTimeFilter* filterOf(AudCoreTimeFilter* filter) {
  return reinterpret_cast<AudTimeFilter*>(filter);
}

static const AudTimeFilter* filterOf(const AudCoreTimeFilter* filter) {
  return reinterpret_cast<const AudTimeFilter*>(filter);
}

AUD_EXPORT AudCoreTimeFilter* aud_core_time_filter_create(double sample_rate,
                                                          uint32_t window) {
  AudTimeFilter* filter = new (std::nothrow) AudTimeFilter;
  if (!filter) return nullptr;
  aud_time_filter_init(filter, sample_rate, window);
  return reinterpret_cast<AudCoreTimeFilter*>(filter);
}

AUD_EXPORT void aud_core_time_filter_destroy(AudCoreTimeFilter* filter) {
  delete filterOf(filter);
}

AUD_EXPORT void aud_core_time_filter_reset(AudCoreTimeFilter* filter) {
  aud_time_filter_reset(filterOf(filter));
}

AUD_EXPORT void aud_core_time_filter_set_deviation_limit(
    AudCoreTimeFilter* filter, int64_t limit_ns) {
  filterOf(filter)->deviation_limit_ns = limit_ns;
}

AUD_EXPORT int32_t aud_core_time_filter_add(AudCoreTimeFilter* filter,
                                            int64_t sample_position,
                                            uint32_t frames,
                                            int64_t host_time_ns) {
  return aud_time_filter_add(filterOf(filter), sample_position, frames,
                             host_time_ns);
}

AUD_EXPORT int32_t aud_core_time_filter_is_valid(
    const AudCoreTimeFilter* filter) {
  return aud_time_filter_is_valid(filterOf(filter));
}

AUD_EXPORT double aud_core_time_filter_ns_per_sample(
    const AudCoreTimeFilter* filter) {
  return aud_time_filter_ns_per_sample(filterOf(filter));
}

AUD_EXPORT int64_t aud_core_time_filter_host_time_at(
    const AudCoreTimeFilter* filter, int64_t sample_position) {
  return aud_time_filter_host_time_at(filterOf(filter), sample_position);
}

AUD_EXPORT int64_t aud_core_time_filter_sample_at(
    const AudCoreTimeFilter* filter, int64_t host_time_ns) {
  return aud_time_filter_sample_at(filterOf(filter), host_time_ns);
}

AUD_EXPORT uint32_t aud_core_time_filter_count(
    const AudCoreTimeFilter* filter) {
  return filterOf(filter)->count;
}

AUD_EXPORT uint32_t aud_core_time_filter_resets(
    const AudCoreTimeFilter* filter) {
  return filterOf(filter)->resets;
}

// ............................................................................
// Transport conversions

AUD_EXPORT int32_t aud_core_transport_beat_at_offset(
    const AudTransportSnapshot* snapshot, uint32_t sample_offset,
    int64_t* beat) {
  return aud_transport_beat_at_offset(snapshot, sample_offset, beat);
}

AUD_EXPORT int32_t aud_core_transport_offset_at_beat(
    const AudTransportSnapshot* snapshot, int64_t beat, int64_t* offset) {
  return aud_transport_offset_at_beat(snapshot, beat, offset);
}

AUD_EXPORT int32_t aud_core_transport_host_time_at_offset(
    const AudTransportSnapshot* snapshot, uint32_t sample_offset,
    int64_t* host_time_ns) {
  return aud_transport_host_time_at_offset(snapshot, sample_offset,
                                           host_time_ns);
}

AUD_EXPORT int32_t aud_core_transport_offset_at_host_time(
    const AudTransportSnapshot* snapshot, int64_t host_time_ns,
    int64_t* offset) {
  return aud_transport_offset_at_host_time(snapshot, host_time_ns, offset);
}

AUD_EXPORT int32_t aud_core_transport_resolve(
    const AudTransportSnapshot* snapshot, const AudTimestamp* timestamp,
    int64_t* offset) {
  return aud_transport_resolve(snapshot, timestamp, offset);
}

// ............................................................................
// UMP helpers

AUD_EXPORT uint32_t aud_core_ump_word_count(uint32_t word0) {
  return aud_ump_word_count(word0);
}

AUD_EXPORT uint32_t aud_core_ump_message_type(uint32_t word0) {
  return aud_ump_message_type(word0);
}

AUD_EXPORT uint32_t aud_core_ump_group(uint32_t word0) {
  return aud_ump_group(word0);
}

AUD_EXPORT uint32_t aud_core_ump_status(uint32_t word0) {
  return aud_ump_status(word0);
}

AUD_EXPORT uint32_t aud_core_ump_channel(uint32_t word0) {
  return aud_ump_channel(word0);
}

AUD_EXPORT uint32_t aud_core_ump_note(uint32_t word0) {
  return aud_ump_note(word0);
}

AUD_EXPORT int32_t aud_core_ump_is_note_on(uint32_t word0, uint32_t word1) {
  return aud_ump_is_note_on(word0, word1);
}

AUD_EXPORT int32_t aud_core_ump_is_note_off(uint32_t word0, uint32_t word1) {
  return aud_ump_is_note_off(word0, word1);
}

AUD_EXPORT float aud_core_ump_note_velocity(uint32_t word0, uint32_t word1) {
  return aud_ump_note_velocity(word0, word1);
}

AUD_EXPORT int32_t aud_core_ump_is_per_note_controller(uint32_t word0) {
  return aud_ump_is_per_note_controller(word0);
}

AUD_EXPORT uint32_t aud_core_ump_per_note_controller_index(uint32_t word0) {
  return aud_ump_per_note_controller_index(word0);
}

AUD_EXPORT float aud_core_ump_unit_value(uint32_t word1) {
  return aud_ump_unit_value(word1);
}

AUD_EXPORT uint32_t aud_core_ump_midi1_word(uint32_t group,
                                            uint32_t status_byte,
                                            uint32_t data1, uint32_t data2) {
  return aud_ump_midi1_word(group, status_byte, data1, data2);
}

AUD_EXPORT void aud_core_ump_midi2_note(uint32_t group, uint32_t channel,
                                        int32_t note_on, uint32_t note,
                                        uint32_t velocity16,
                                        uint32_t attribute_type,
                                        uint32_t attribute16,
                                        uint32_t* words) {
  aud_ump_midi2_note(group, channel, note_on, note, velocity16, attribute_type,
                     attribute16, words);
}

AUD_EXPORT void aud_core_ump_midi2_per_note_controller(
    uint32_t group, uint32_t channel, uint32_t note, uint32_t index,
    uint32_t value32, uint32_t* words) {
  aud_ump_midi2_per_note_controller(group, channel, note, index, value32,
                                    words);
}

// ............................................................................
// The parameter ramp

static AudParamRamp* rampOf(AudCoreParamRamp* ramp) {
  return reinterpret_cast<AudParamRamp*>(ramp);
}

static const AudParamRamp* rampOf(const AudCoreParamRamp* ramp) {
  return reinterpret_cast<const AudParamRamp*>(ramp);
}

AUD_EXPORT AudCoreParamRamp* aud_core_param_ramp_create(float value) {
  return reinterpret_cast<AudCoreParamRamp*>(new (std::nothrow)
                                                 AudParamRamp(value));
}

AUD_EXPORT void aud_core_param_ramp_destroy(AudCoreParamRamp* ramp) {
  delete rampOf(ramp);
}

AUD_EXPORT void aud_core_param_ramp_set(AudCoreParamRamp* ramp, float value) {
  rampOf(ramp)->set(value);
}

AUD_EXPORT void aud_core_param_ramp_set_target(AudCoreParamRamp* ramp,
                                               float target, uint32_t frames) {
  rampOf(ramp)->setTarget(target, frames);
}

AUD_EXPORT void aud_core_param_ramp_advance(AudCoreParamRamp* ramp,
                                            uint32_t frames) {
  rampOf(ramp)->advance(frames);
}

AUD_EXPORT float aud_core_param_ramp_value(const AudCoreParamRamp* ramp) {
  return rampOf(ramp)->value();
}

AUD_EXPORT float aud_core_param_ramp_target(const AudCoreParamRamp* ramp) {
  return rampOf(ramp)->target();
}

AUD_EXPORT int32_t aud_core_param_ramp_is_ramping(const AudCoreParamRamp* ramp) {
  return rampOf(ramp)->isRamping();
}

AUD_EXPORT uint32_t aud_core_param_ramp_remaining(const AudCoreParamRamp* ramp) {
  return rampOf(ramp)->remaining();
}

// ............................................................................
// The fixed-block adapter

static AudFixedBlockAdapter* adapterOf(AudCoreFixedBlockAdapter* adapter) {
  return reinterpret_cast<AudFixedBlockAdapter*>(adapter);
}

AUD_EXPORT AudCoreFixedBlockAdapter* aud_core_fixed_block_adapter_create(
    uint32_t block_size, uint32_t channels) {
  if (block_size == 0 || channels == 0) return nullptr;
  return reinterpret_cast<AudCoreFixedBlockAdapter*>(
      new (std::nothrow) AudFixedBlockAdapter(block_size, channels));
}

AUD_EXPORT void aud_core_fixed_block_adapter_destroy(
    AudCoreFixedBlockAdapter* adapter) {
  delete adapterOf(adapter);
}

AUD_EXPORT uint32_t aud_core_fixed_block_adapter_latency(
    const AudCoreFixedBlockAdapter* adapter) {
  return reinterpret_cast<const AudFixedBlockAdapter*>(adapter)->latency();
}

AUD_EXPORT void aud_core_fixed_block_adapter_reset(
    AudCoreFixedBlockAdapter* adapter) {
  adapterOf(adapter)->reset();
}

AUD_EXPORT void aud_core_fixed_block_adapter_process(
    AudCoreFixedBlockAdapter* adapter, const float* const* in,
    float* const* out, uint32_t frames, AudCoreRenderBlockFunction render,
    void* user) {
  adapterOf(adapter)->process(
      in, out, frames,
      [render, user](const float* const* blockIn, float* const* blockOut,
                     uint32_t blockSize) {
        render(user, blockIn, blockOut, blockSize);
      });
}

// ............................................................................
// The reference node aud.core.gain

namespace {

class AudCoreGain : public AudNodeBase {
 public:
  AudCoreGain(const AudNodeDescriptor*, const AudHostApi*) : AudNodeBase(1) {
    setParam(AUD_CORE_GAIN_PARAM_GAIN, 1.0f);
  }

  int32_t saveState(void* buffer, size_t capacity, size_t* size) override {
    *size = sizeof(float);
    if (capacity < sizeof(float)) return AUD_ERROR_BUFFER_TOO_SMALL;
    const float gain = ramp(AUD_CORE_GAIN_PARAM_GAIN).target();
    std::memcpy(buffer, &gain, sizeof(float));
    return AUD_OK;
  }

  int32_t loadState(const void* data, size_t size, uint32_t version) override {
    if (version != AUD_CORE_GAIN_STATE_VERSION) return AUD_ERROR_STATE_VERSION;
    if (size != sizeof(float)) return AUD_ERROR_INVALID_ARGUMENT;
    float gain = 1.0f;
    std::memcpy(&gain, data, sizeof(float));
    setParam(AUD_CORE_GAIN_PARAM_GAIN, gain);
    return AUD_OK;
  }

 protected:
  void renderRange(const AudProcessContext& context, uint32_t offset,
                   uint32_t frames) override {
    if (context.num_input_buses < 1 || context.num_output_buses < 1) return;
    const AudAudioBus& in = context.inputs[0];
    const AudAudioBus& out = context.outputs[0];
    const uint32_t channels = std::min(in.num_channels, out.num_channels);
    const AudParamRamp& gain = ramp(AUD_CORE_GAIN_PARAM_GAIN);
    const float value = gain.value();
    const float step = gain.step();
    const uint32_t remaining = gain.remaining();
    for (uint32_t c = 0; c < channels; ++c) {
      const float* source = in.channels[c] + offset;
      float* target = out.channels[c] + offset;
      for (uint32_t i = 0; i < frames; ++i) {
        const float g = i < remaining ? value + step * static_cast<float>(i)
                                      : gain.target();
        target[i] = source[i] * g;
      }
    }
  }
};

const AudBusDescriptor kGainInputBuses[] = {
    {sizeof(AudBusDescriptor), "in", "Input", AUD_BUS_MAIN, 1, 16, 2},
};

const AudBusDescriptor kGainOutputBuses[] = {
    {sizeof(AudBusDescriptor), "out", "Output", AUD_BUS_MAIN, 1, 16, 2},
};

const AudEventPortDescriptor kGainEventInputs[] = {
    {sizeof(AudEventPortDescriptor), "events", "Events",
     AUD_EVENT_PORT_CONTROL, 0},
};

const AudParamDescriptor kGainParams[] = {
    {sizeof(AudParamDescriptor), "gain", "Gain", "", 0.0f, 2.0f, 1.0f,
     AUD_PARAM_AUTOMATABLE | AUD_PARAM_RAMPED, 0, 0},
};

const AudNodeVTable kGainVTable = AudNodeVTableFor<AudCoreGain>::vtable();

const AudNodeDescriptor kGainDescriptor = {
    sizeof(AudNodeDescriptor),
    AUD_ABI_VERSION_MAJOR,
    AUD_ABI_VERSION_MINOR,
    1,  // version
    AUD_CORE_GAIN_TYPE_ID,
    "Gain",
    "Audanika",
    AUD_NODE_CAP_IN_PLACE | AUD_NODE_CAP_VARIABLE_BLOCK | AUD_NODE_CAP_EVENTS |
        AUD_NODE_CAP_STATE | AUD_NODE_CAP_LATENCY | AUD_NODE_CAP_TAIL,
    AUD_CORE_GAIN_STATE_VERSION,
    1,
    1,
    kGainInputBuses,
    kGainOutputBuses,
    1,
    0,
    kGainEventInputs,
    nullptr,
    1,
    0,
    kGainParams,
    nullptr,
    &kGainVTable,
};

}  // namespace

AUD_EXPORT int32_t aud_audio_core_register(const AudHostApi* host) {
  if (!host || host->struct_size < sizeof(AudHostApi) ||
      !host->register_node_type) {
    return AUD_ERROR_INVALID_ARGUMENT;
  }
  if (host->abi_major != AUD_ABI_VERSION_MAJOR) return AUD_ERROR_ABI_MAJOR;
  if (!aud_abi_is_compatible(AUD_ABI_VERSION_MAJOR, AUD_ABI_VERSION_MINOR,
                             host->abi_major, host->abi_minor)) {
    return AUD_ERROR_ABI_MINOR;
  }
  return host->register_node_type(host->host, &kGainDescriptor);
}
