// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:ffi';

import 'aud_audio_core_bindings_generated.dart' as bindings;

// #############################################################################
/// The sample-to-host-time filter of decision time-001, `aud_time_filter.h`
/// of the native core: a least-squares fit over a window of callback
/// timestamps turns the jittering host times of a stream into a stable
/// mapping between sample positions and host time.
///
/// The filter resets itself when the sample position is discontinuous or a
/// host time deviates from the prediction by more than [deviationLimitNs];
/// call [reset] on device and route changes, interruptions, sample-rate
/// changes and stream restarts.
class AudTimeFilter {
  /// Creates a filter for [sampleRate] with a [window] of points.
  AudTimeFilter({required this.sampleRate, this.window = defaultWindow})
    : _filter = bindings.aud_core_time_filter_create(sampleRate, window) {
    if (_filter == nullptr) throw StateError('Could not create the filter');
  }

  /// The largest window of points.
  static const int maxPoints = 512;

  /// The default window: about ten seconds of 20 ms blocks.
  static const int defaultWindow = 512;

  /// The default deviation limit: a quarter of a second.
  static const int defaultDeviationLimitNs = 250000000;

  // ...........................................................................
  /// The sample rate of the stream.
  final double sampleRate;

  /// The points of the fit.
  final int window;

  /// Sets the host time deviation that resets the filter.
  set deviationLimitNs(int limitNs) {
    _checkNotDisposed();
    bindings.aud_core_time_filter_set_deviation_limit(_filter, limitNs);
  }

  // ...........................................................................
  /// Adds the timestamps of a callback: the block's [samplePosition], its
  /// [frames] and the [hostTimeNs] at which its first frame reaches the
  /// output. Returns true when the filter reset first.
  bool add({
    required int samplePosition,
    required int frames,
    required int hostTimeNs,
  }) {
    _checkNotDisposed();
    return bindings.aud_core_time_filter_add(
          _filter,
          samplePosition,
          frames,
          hostTimeNs,
        ) !=
        0;
  }

  /// Forgets every point.
  void reset() {
    _checkNotDisposed();
    bindings.aud_core_time_filter_reset(_filter);
  }

  /// Whether the filter maps: it holds at least one point.
  bool get isValid {
    _checkNotDisposed();
    return bindings.aud_core_time_filter_is_valid(_filter) != 0;
  }

  /// The fitted host nanoseconds per sample.
  double get nsPerSample {
    _checkNotDisposed();
    return bindings.aud_core_time_filter_ns_per_sample(_filter);
  }

  /// The host time at which [samplePosition] reaches the output.
  int hostTimeAt(int samplePosition) {
    _checkNotDisposed();
    return bindings.aud_core_time_filter_host_time_at(_filter, samplePosition);
  }

  /// The sample position that reaches the output at [hostTimeNs].
  int sampleAt(int hostTimeNs) {
    _checkNotDisposed();
    return bindings.aud_core_time_filter_sample_at(_filter, hostTimeNs);
  }

  /// The points stored.
  int get count {
    _checkNotDisposed();
    return bindings.aud_core_time_filter_count(_filter);
  }

  /// The resets since creation, for diagnostics.
  int get resets {
    _checkNotDisposed();
    return bindings.aud_core_time_filter_resets(_filter);
  }

  // ...........................................................................
  /// Frees the native filter.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    bindings.aud_core_time_filter_destroy(_filter);
  }

  final Pointer<bindings.AudCoreTimeFilter> _filter;
  bool _disposed = false;

  void _checkNotDisposed() {
    if (_disposed) throw StateError('The filter is disposed');
  }
}
