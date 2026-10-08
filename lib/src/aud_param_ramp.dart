// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:ffi';

import 'aud_audio_core_bindings_generated.dart' as bindings;

// #############################################################################
/// The linear parameter ramp of `aud_param_ramp.hpp`: a parameter moves
/// from its value to a target over a number of frames. The native class
/// behind it is what `AudNodeBase` runs per parameter.
class AudParamRamp {
  /// Creates a ramp resting at [value].
  AudParamRamp([double value = 0])
    : _ramp = bindings.aud_core_param_ramp_create(value) {
    if (_ramp == nullptr) throw StateError('Could not create the ramp');
  }

  // ...........................................................................
  /// Jumps to [value] at once.
  void set(double value) {
    _checkNotDisposed();
    bindings.aud_core_param_ramp_set(_ramp, value);
  }

  /// Moves to [target] over [frames] frames; zero frames jump at once.
  void setTarget(double target, {required int frames}) {
    _checkNotDisposed();
    bindings.aud_core_param_ramp_set_target(_ramp, target, frames);
  }

  /// Advances the ramp by [frames] frames.
  void advance(int frames) {
    _checkNotDisposed();
    bindings.aud_core_param_ramp_advance(_ramp, frames);
  }

  /// The value at the current frame.
  double get value {
    _checkNotDisposed();
    return bindings.aud_core_param_ramp_value(_ramp);
  }

  /// The value the ramp moves to.
  double get target {
    _checkNotDisposed();
    return bindings.aud_core_param_ramp_target(_ramp);
  }

  /// Whether the ramp is moving.
  bool get isRamping {
    _checkNotDisposed();
    return bindings.aud_core_param_ramp_is_ramping(_ramp) != 0;
  }

  /// The frames left until the target is reached.
  int get remaining {
    _checkNotDisposed();
    return bindings.aud_core_param_ramp_remaining(_ramp);
  }

  // ...........................................................................
  /// Frees the native ramp.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    bindings.aud_core_param_ramp_destroy(_ramp);
  }

  final Pointer<bindings.AudCoreParamRamp> _ramp;
  bool _disposed = false;

  void _checkNotDisposed() {
    if (_disposed) throw StateError('The ramp is disposed');
  }
}
