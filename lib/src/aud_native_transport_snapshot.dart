// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:ffi';
import 'dart:math';

import 'package:ffi/ffi.dart';

import 'aud_audio_core_bindings_generated.dart' as bindings;
import 'aud_native_conversions.dart';
import 'aud_time.dart';
import 'aud_transport.dart';

// #############################################################################
/// A transport snapshot in native memory, for the engine and for the
/// cross-check of the Dart conversions against `aud_transport.h`.
class AudNativeTransportSnapshot {
  /// Copies [snapshot] into native memory.
  AudNativeTransportSnapshot(AudTransportSnapshot snapshot)
    : pointer = calloc<bindings.AudTransportSnapshot>(),
      _segments = calloc<bindings.AudTransportSegment>(
        max(snapshot.segments.length, 1),
      ) {
    for (var i = 0; i < snapshot.segments.length; i++) {
      snapshot.segments[i].writeToRef(_segments[i]);
    }
    pointer.ref
      ..struct_size = sizeOf<bindings.AudTransportSnapshot>()
      ..capabilities = snapshot.capabilities.flags
      ..num_segments = snapshot.segments.length
      ..reserved = 0
      ..segments = _segments;
    snapshot.time.writeToRef(pointer.ref.time);
  }

  /// The native struct.
  final Pointer<bindings.AudTransportSnapshot> pointer;
  final Pointer<bindings.AudTransportSegment> _segments;
  bool _disposed = false;

  // ...........................................................................
  /// The musical position at [sampleOffset] as the native core computes it;
  /// null when the core reports no segment.
  int? beatAtOffset(int sampleOffset) {
    _checkNotDisposed();
    final out = calloc<Int64>();
    try {
      final code = bindings.aud_core_transport_beat_at_offset(
        pointer,
        sampleOffset,
        out,
      );
      return code == bindings.AUD_OK ? out.value : null;
    } finally {
      calloc.free(out);
    }
  }

  /// The host time at [sampleOffset] as the native core computes it.
  int? hostTimeAtOffset(int sampleOffset) {
    _checkNotDisposed();
    final out = calloc<Int64>();
    try {
      final code = bindings.aud_core_transport_host_time_at_offset(
        pointer,
        sampleOffset,
        out,
      );
      return code == bindings.AUD_OK ? out.value : null;
    } finally {
      calloc.free(out);
    }
  }

  /// [AudTransportSnapshot.offsetAtBeat] as the native core computes it.
  AudResolution offsetAtBeat(int beatTicks) => _resolution(
    (out) =>
        bindings.aud_core_transport_offset_at_beat(pointer, beatTicks, out),
  );

  /// [AudTransportSnapshot.offsetAtHostTime] as the native core computes
  /// it.
  AudResolution offsetAtHostTime(int hostTimeNs) => _resolution(
    (out) => bindings.aud_core_transport_offset_at_host_time(
      pointer,
      hostTimeNs,
      out,
    ),
  );

  /// [AudTransportSnapshot.resolve] as the native core computes it.
  AudResolution resolve(AudTimestamp timestamp) {
    final native = calloc<bindings.AudTimestamp>();
    try {
      timestamp.writeTo(native);
      return _resolution(
        (out) => bindings.aud_core_transport_resolve(pointer, native, out),
      );
    } finally {
      calloc.free(native);
    }
  }

  AudResolution _resolution(int Function(Pointer<Int64> out) call) {
    _checkNotDisposed();
    final out = calloc<Int64>();
    try {
      final code = call(out);
      return AudResolution.fromCode(
        code,
        code == bindings.AUD_OK ? out.value : 0,
      );
    } finally {
      calloc.free(out);
    }
  }

  // ...........................................................................
  /// Frees the native memory.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    calloc.free(_segments);
    calloc.free(pointer);
  }

  void _checkNotDisposed() {
    if (_disposed) throw StateError('The snapshot is disposed');
  }
}
