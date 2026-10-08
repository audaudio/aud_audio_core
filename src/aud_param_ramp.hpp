// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// A linear parameter ramp (decision graph-001): a parameter moves from its
// value to a target over a number of frames. Header only; nothing here
// allocates.

#ifndef AUD_PARAM_RAMP_HPP
#define AUD_PARAM_RAMP_HPP

#include <cstdint>

class AudParamRamp {
 public:
  // Creates a ramp resting at `value`.
  explicit AudParamRamp(float value = 0) : value_(value), target_(value) {}

  // Jumps to `value` at once.
  void set(float value) {
    value_ = value;
    target_ = value;
    remaining_ = 0;
    step_ = 0;
  }

  // Moves to `target` over `frames` frames; zero frames jump at once.
  void setTarget(float target, uint32_t frames) {
    if (frames == 0) {
      set(target);
      return;
    }
    target_ = target;
    remaining_ = frames;
    step_ = (target - value_) / static_cast<float>(frames);
  }

  // Advances the ramp by `frames` frames.
  void advance(uint32_t frames) {
    if (remaining_ == 0) return;
    if (frames >= remaining_) {
      set(target_);
      return;
    }
    remaining_ -= frames;
    value_ += step_ * static_cast<float>(frames);
  }

  // The value at the current frame.
  float value() const { return value_; }

  // The value the ramp moves to.
  float target() const { return target_; }

  // The change per frame while ramping, else 0.
  float step() const { return step_; }

  // Whether the ramp is moving.
  bool isRamping() const { return remaining_ > 0; }

  // The frames left until the target is reached.
  uint32_t remaining() const { return remaining_; }

 private:
  float value_;
  float target_;
  float step_ = 0;
  uint32_t remaining_ = 0;
};

#endif  // AUD_PARAM_RAMP_HPP
