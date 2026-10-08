// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// The base of a node written in C++ (decisions graph-002 and abi-001): it
// keeps a ramp per parameter, splits every block at the event offsets into
// sub-ranges of at least AUD_NODE_MIN_SUB_RANGE frames, delivers each event
// at the start of the sub-range that follows its offset and renders each
// sub-range through renderRange(). Parameter events ramp the parameters,
// all other events reach handleEvent(). AudNodeVTableFor<T> turns a derived
// class into the vtable of the ABI. Header only; nothing allocates after
// the constructor, so process() is realtime safe.

#ifndef AUD_NODE_BASE_HPP
#define AUD_NODE_BASE_HPP

#include <cstddef>
#include <cstdint>
#include <new>
#include <vector>

#include "aud_abi.h"
#include "aud_param_ramp.hpp"

// The smallest sub-range a block is split into: an event inside a
// sub-range is delivered at its end, at most this many frames late.
#define AUD_NODE_MIN_SUB_RANGE 16

class AudNodeBase {
 public:
  // Creates a node with `numParams` parameters and a minimum sub-range.
  explicit AudNodeBase(uint32_t numParams,
                       uint32_t minSubRange = AUD_NODE_MIN_SUB_RANGE)
      : ramps_(numParams), minSubRange_(minSubRange < 1 ? 1 : minSubRange) {}

  virtual ~AudNodeBase() {}

  // [control] Prepares the node; stores the sample rate and the largest
  // block and resets every ramp to its value. Override to allocate.
  virtual int32_t prepare(const AudPrepareInfo& info) {
    sampleRate_ = info.sample_rate;
    maxFrames_ = info.max_frames;
    for (auto& ramp : ramps_) ramp.set(ramp.target());
    return AUD_OK;
  }

  // [realtime] Resets the state for a reason; the base keeps the ramps.
  virtual void reset(uint32_t reason) { (void)reason; }

  // [realtime] Sets a parameter at once.
  void setParam(uint32_t index, float value) {
    if (index < ramps_.size()) ramps_[index].set(value);
  }

  // [realtime] Ramps a parameter to `target` over `frames` frames.
  void setParamRamped(uint32_t index, float target, uint32_t frames) {
    if (index < ramps_.size()) ramps_[index].setTarget(target, frames);
  }

  // The current value of a parameter.
  float param(uint32_t index) const {
    return index < ramps_.size() ? ramps_[index].value() : 0;
  }

  // The ramp of a parameter.
  const AudParamRamp& ramp(uint32_t index) const { return ramps_[index]; }

  // The number of parameters.
  uint32_t numParams() const { return static_cast<uint32_t>(ramps_.size()); }

  // The prepared sample rate.
  double sampleRate() const { return sampleRate_; }

  // The prepared largest block.
  uint32_t maxFrames() const { return maxFrames_; }

  // [realtime] Renders a block: delivers the events and renders the
  // sub-ranges between them.
  void process(const AudProcessContext& context) {
    const uint32_t frames = context.frames;
    uint32_t position = 0;
    uint32_t next = 0;
    while (position < frames) {
      next = deliverDue(context, next, position);
      uint32_t end = next < context.num_events
                         ? context.events[next].sample_offset
                         : frames;
      if (end > frames) end = frames;
      if (end - position < minSubRange_) end = position + minSubRange_;
      if (end > frames) end = frames;
      renderRange(context, position, end - position);
      for (auto& ramp : ramps_) ramp.advance(end - position);
      position = end;
    }
    // Events at or beyond the block end are delivered after the last range.
    deliverDue(context, next, UINT32_MAX);
  }

  // [offline] The latency in frames; 0 by default.
  virtual uint32_t latency() const { return 0; }

  // [offline] The tail in frames; 0 by default.
  virtual uint32_t tail() const { return 0; }

  // [control] Applies a string setting; unsupported by default.
  virtual int32_t setString(uint32_t key, const char* value) {
    (void)key;
    (void)value;
    return AUD_ERROR_UNSUPPORTED;
  }

  // [offline] Saves the state; unsupported by default.
  virtual int32_t saveState(void* buffer, size_t capacity, size_t* size) {
    (void)buffer;
    (void)capacity;
    (void)size;
    return AUD_ERROR_UNSUPPORTED;
  }

  // [offline] Loads a state; unsupported by default.
  virtual int32_t loadState(const void* data, size_t size, uint32_t version) {
    (void)data;
    (void)size;
    (void)version;
    return AUD_ERROR_UNSUPPORTED;
  }

 protected:
  // [realtime] Renders the frames [offset, offset + frames) of the block.
  virtual void renderRange(const AudProcessContext& context, uint32_t offset,
                           uint32_t frames) = 0;

  // [realtime] Handles an event that is not a parameter event.
  virtual void handleEvent(const AudEvent& event) { (void)event; }

 private:
  // Delivers the events from index `next` whose offset is at or before
  // `position`; returns the index of the first undelivered event.
  uint32_t deliverDue(const AudProcessContext& context, uint32_t next,
                      uint32_t position) {
    while (next < context.num_events &&
           context.events[next].sample_offset <= position) {
      const AudEvent& event = context.events[next];
      if (event.type == AUD_EVENT_PARAM) {
        setParamRamped(event.words[0], aud_event_param_value(&event),
                       event.words[2]);
      } else {
        handleEvent(event);
      }
      ++next;
    }
    return next;
  }

  std::vector<AudParamRamp> ramps_;
  uint32_t minSubRange_;
  double sampleRate_ = 0;
  uint32_t maxFrames_ = 0;
};

// The vtable of the ABI for a class T derived from AudNodeBase with a
// constructor `T(const AudNodeDescriptor*, const AudHostApi*)`.
template <class T>
struct AudNodeVTableFor {
  static void* create(const AudNodeDescriptor* descriptor,
                      const AudHostApi* host) {
    return new (std::nothrow) T(descriptor, host);
  }
  static void destroy(void* instance) { delete static_cast<T*>(instance); }
  static int32_t prepare(void* instance, const AudPrepareInfo* info) {
    return static_cast<T*>(instance)->prepare(*info);
  }
  static void reset(void* instance, uint32_t reason) {
    static_cast<T*>(instance)->reset(reason);
  }
  static void setParam(void* instance, uint32_t index, float value) {
    static_cast<T*>(instance)->setParam(index, value);
  }
  static void process(void* instance, const AudProcessContext* context) {
    static_cast<T*>(instance)->process(*context);
  }
  static int32_t setString(void* instance, uint32_t key, const char* value) {
    return static_cast<T*>(instance)->setString(key, value);
  }
  static uint32_t latency(void* instance) {
    return static_cast<T*>(instance)->latency();
  }
  static uint32_t tail(void* instance) {
    return static_cast<T*>(instance)->tail();
  }
  static int32_t saveState(void* instance, void* buffer, size_t capacity,
                           size_t* size) {
    return static_cast<T*>(instance)->saveState(buffer, capacity, size);
  }
  static int32_t loadState(void* instance, const void* data, size_t size,
                           uint32_t version) {
    return static_cast<T*>(instance)->loadState(data, size, version);
  }

  // The filled vtable.
  static AudNodeVTable vtable() {
    AudNodeVTable table = {};
    table.struct_size = sizeof(AudNodeVTable);
    table.create = create;
    table.destroy = destroy;
    table.prepare = prepare;
    table.reset = reset;
    table.set_param = setParam;
    table.process = process;
    table.set_string = setString;
    table.get_latency = latency;
    table.get_tail = tail;
    table.save_state = saveState;
    table.load_state = loadState;
    return table;
  }
};

#endif  // AUD_NODE_BASE_HPP
