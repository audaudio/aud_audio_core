// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:ffi';

import 'aud_audio_core_bindings_generated.dart' as bindings;

// #############################################################################
/// The time domains of decision time-001. Sample time is always available
/// and authoritative for scheduling, host time is the monotonic clock and
/// valid only with a source, beat time runs through the transport.
enum AudTimeDomain {
  /// Now: the start of the next block.
  immediate(bindings.AUD_TIME_IMMEDIATE),

  /// A sample position of the stream.
  sample(bindings.AUD_TIME_SAMPLE),

  /// A host time in nanoseconds of the monotonic clock.
  host(bindings.AUD_TIME_HOST),

  /// A musical position in beats.
  beat(bindings.AUD_TIME_BEAT);

  const AudTimeDomain(this.code);

  /// The `AUD_TIME_*` code of the ABI.
  final int code;

  // ...........................................................................
  /// The domain with [code].
  static AudTimeDomain fromCode(int code) => values.firstWhere(
    (domain) => domain.code == code,
    orElse: () => throw ArgumentError.value(code, 'code', 'Unknown domain'),
  );
}

// #############################################################################
/// Where a host time comes from.
enum AudTimeSource {
  /// No host time.
  none(bindings.AUD_TIME_SOURCE_NONE),

  /// A hardware timestamp of the audio device.
  hardware(bindings.AUD_TIME_SOURCE_HARDWARE),

  /// An estimate of the backend.
  estimated(bindings.AUD_TIME_SOURCE_ESTIMATED),

  /// Synthesized by the engine from the sample clock.
  synthesized(bindings.AUD_TIME_SOURCE_SYNTHESIZED);

  const AudTimeSource(this.code);

  /// The `AUD_TIME_SOURCE_*` code of the ABI.
  final int code;

  // ...........................................................................
  /// The source with [code].
  static AudTimeSource fromCode(int code) => values.firstWhere(
    (source) => source.code == code,
    orElse: () => throw ArgumentError.value(code, 'code', 'Unknown source'),
  );
}

// #############################################################################
/// The monotonic host clock of decision time-001, `aud_clock.h` of the
/// native core: the clock the engine measures against on every platform.
abstract final class AudClock {
  /// The host time now, in nanoseconds.
  static int nowNs() => bindings.aud_core_clock_now_ns();
}

// #############################################################################
/// Beats as fixed point: one beat is [factor] ticks, as CLAP does.
abstract final class AudBeats {
  /// The ticks per beat.
  static const int factor = bindings.AUD_BEAT_FACTOR;

  /// Ticks from [beats], rounded to the nearest tick.
  static int ticks(double beats) => (beats * factor).round();

  /// Beats from [ticks].
  static double beats(int ticks) => ticks / factor;
}

// #############################################################################
/// A point in time in one of the domains: `AudTimestamp` of the ABI.
class AudTimestamp {
  const AudTimestamp._(this.domain, this.value, this.source);

  /// Now: the start of the next block.
  const AudTimestamp.immediate()
    : this._(AudTimeDomain.immediate, 0, AudTimeSource.none);

  /// A sample [position] of the stream.
  const AudTimestamp.sample(int position)
    : this._(AudTimeDomain.sample, position, AudTimeSource.none);

  /// A host time of [nanoseconds] from [source].
  const AudTimestamp.host(
    int nanoseconds, {
    AudTimeSource source = AudTimeSource.hardware,
  }) : this._(AudTimeDomain.host, nanoseconds, source);

  /// A musical position of [ticks].
  const AudTimestamp.beatTicks(int ticks)
    : this._(AudTimeDomain.beat, ticks, AudTimeSource.none);

  /// A musical position of [beats].
  AudTimestamp.beat(double beats) : this.beatTicks(AudBeats.ticks(beats));

  /// A timestamp from its native struct.
  factory AudTimestamp.fromNative(bindings.AudTimestamp native) =>
      AudTimestamp._(
        AudTimeDomain.fromCode(native.domain),
        native.value,
        AudTimeSource.fromCode(native.source),
      );

  /// A timestamp from [toJson].
  factory AudTimestamp.fromJson(Map<String, Object?> json) {
    final domain = AudTimeDomain.values.byName(json['domain']! as String);
    final value = (json['value'] as num?)?.toInt() ?? 0;
    final source = json.containsKey('source')
        ? AudTimeSource.values.byName(json['source']! as String)
        : AudTimeSource.none;
    return AudTimestamp._(domain, value, source);
  }

  // ...........................................................................
  /// The domain of the timestamp.
  final AudTimeDomain domain;

  /// The sample position, the host time in nanoseconds or the beat ticks;
  /// 0 for immediate.
  final int value;

  /// The source of a host time; none for the other domains.
  final AudTimeSource source;

  /// Whether the timestamp means now.
  bool get isImmediate => domain == AudTimeDomain.immediate;

  /// The musical position in beats; only in the beat domain.
  double get beats {
    if (domain != AudTimeDomain.beat) {
      throw StateError('Not a beat timestamp: $this');
    }
    return AudBeats.beats(value);
  }

  // ...........................................................................
  /// Writes the timestamp into its native struct.
  void writeTo(Pointer<bindings.AudTimestamp> pointer) {
    pointer.ref
      ..struct_size = sizeOf<bindings.AudTimestamp>()
      ..domain = domain.code
      ..source = source.code
      ..flags = 0
      ..value = value;
  }

  /// The timestamp as JSON.
  Map<String, Object?> toJson() => {
    'domain': domain.name,
    'value': value,
    if (source != AudTimeSource.none) 'source': source.name,
  };

  @override
  bool operator ==(Object other) =>
      other is AudTimestamp &&
      other.domain == domain &&
      other.value == value &&
      other.source == source;

  @override
  int get hashCode => Object.hash(domain, value, source);

  @override
  String toString() => switch (domain) {
    AudTimeDomain.immediate => 'AudTimestamp.immediate',
    AudTimeDomain.sample => 'AudTimestamp.sample($value)',
    AudTimeDomain.host => 'AudTimestamp.host($value ns, ${source.name})',
    AudTimeDomain.beat => 'AudTimestamp.beat(${AudBeats.beats(value)})',
  };
}

// #############################################################################
/// The outcome of resolving a timestamp to a frame offset of a block.
class AudResolution {
  const AudResolution._(this.code, this.offset);

  /// The timestamp falls into the block at [offset].
  const AudResolution.ok(int offset) : this._(bindings.AUD_OK, offset);

  /// The timestamp lies before the block.
  const AudResolution.late() : this._(bindings.AUD_ERROR_LATE, 0);

  /// The timestamp lies after the block; try again next block.
  const AudResolution.pending() : this._(bindings.AUD_PENDING, 0);

  /// The snapshot cannot convert the domain.
  const AudResolution.unsupported() : this._(bindings.AUD_ERROR_UNSUPPORTED, 0);

  /// The timestamp is malformed.
  const AudResolution.invalid()
    : this._(bindings.AUD_ERROR_INVALID_ARGUMENT, 0);

  /// A resolution from a result [code] of the ABI and an [offset].
  const AudResolution.fromCode(int code, int offset) : this._(code, offset);

  // ...........................................................................
  /// The result code of the ABI.
  final int code;

  /// The frame offset inside the block; 0 unless [isOk].
  final int offset;

  /// Whether the timestamp falls into the block.
  bool get isOk => code == bindings.AUD_OK;

  /// Whether the timestamp lies before the block.
  bool get isLate => code == bindings.AUD_ERROR_LATE;

  /// Whether the timestamp lies after the block.
  bool get isPending => code == bindings.AUD_PENDING;

  /// Whether the snapshot cannot convert the domain.
  bool get isUnsupported => code == bindings.AUD_ERROR_UNSUPPORTED;

  @override
  bool operator ==(Object other) =>
      other is AudResolution && other.code == code && other.offset == offset;

  @override
  int get hashCode => Object.hash(code, offset);

  @override
  String toString() => 'AudResolution(code: $code, offset: $offset)';
}
