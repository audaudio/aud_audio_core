// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:math';

import 'aud_abi_constants.dart' as bindings;
import 'aud_time.dart';

// #############################################################################
/// What a transport provider can do.
class AudTransportCapabilities {
  /// Creates the capabilities.
  const AudTransportCapabilities({
    this.tempo = false,
    this.seek = false,
    this.startStop = false,
    this.timeSignature = false,
    this.hostTime = false,
    this.loop = false,
  });

  /// The capabilities from the `AUD_TRANSPORT_CAP_*` [flags].
  factory AudTransportCapabilities.fromFlags(int flags) =>
      AudTransportCapabilities(
        tempo: flags & bindings.AUD_TRANSPORT_CAP_TEMPO != 0,
        seek: flags & bindings.AUD_TRANSPORT_CAP_SEEK != 0,
        startStop: flags & bindings.AUD_TRANSPORT_CAP_START_STOP != 0,
        timeSignature: flags & bindings.AUD_TRANSPORT_CAP_TIME_SIGNATURE != 0,
        hostTime: flags & bindings.AUD_TRANSPORT_CAP_HOST_TIME != 0,
        loop: flags & bindings.AUD_TRANSPORT_CAP_LOOP != 0,
      );

  /// The capabilities from [toJson].
  factory AudTransportCapabilities.fromJson(Map<String, Object?> json) =>
      AudTransportCapabilities(
        tempo: json['tempo'] == true,
        seek: json['seek'] == true,
        startStop: json['startStop'] == true,
        timeSignature: json['timeSignature'] == true,
        hostTime: json['hostTime'] == true,
        loop: json['loop'] == true,
      );

  // ...........................................................................
  /// The provider changes the tempo.
  final bool tempo;

  /// The provider seeks.
  final bool seek;

  /// The provider starts and stops.
  final bool startStop;

  /// The provider carries a time signature.
  final bool timeSignature;

  /// The provider delivers host time.
  final bool hostTime;

  /// The provider loops.
  final bool loop;

  /// The `AUD_TRANSPORT_CAP_*` flags.
  int get flags =>
      (tempo ? bindings.AUD_TRANSPORT_CAP_TEMPO : 0) |
      (seek ? bindings.AUD_TRANSPORT_CAP_SEEK : 0) |
      (startStop ? bindings.AUD_TRANSPORT_CAP_START_STOP : 0) |
      (timeSignature ? bindings.AUD_TRANSPORT_CAP_TIME_SIGNATURE : 0) |
      (hostTime ? bindings.AUD_TRANSPORT_CAP_HOST_TIME : 0) |
      (loop ? bindings.AUD_TRANSPORT_CAP_LOOP : 0);

  /// The capabilities as JSON.
  Map<String, Object?> toJson() => {
    'tempo': tempo,
    'seek': seek,
    'startStop': startStop,
    'timeSignature': timeSignature,
    'hostTime': hostTime,
    'loop': loop,
  };

  @override
  bool operator ==(Object other) =>
      other is AudTransportCapabilities && other.flags == flags;

  @override
  int get hashCode => flags;

  @override
  String toString() => 'AudTransportCapabilities(${toJson()})';
}

// #############################################################################
/// What a stream delivers with every callback: `AudStreamTime` of the ABI.
class AudStreamTime {
  /// Creates the time of a block.
  const AudStreamTime({
    required this.frames,
    required this.sampleRate,
    required this.samplePosition,
    this.hostTimeNs = 0,
    this.hostTimeSource = AudTimeSource.none,
    this.hostTimeAccuracyNs = 0,
    this.outputLatencyFrames = 0,
    this.inputLatencyFrames = 0,
  });

  /// The time from [toJson].
  factory AudStreamTime.fromJson(Map<String, Object?> json) => AudStreamTime(
    frames: (json['frames']! as num).toInt(),
    sampleRate: (json['sampleRate']! as num).toDouble(),
    samplePosition: (json['samplePosition']! as num).toInt(),
    hostTimeNs: (json['hostTimeNs'] as num?)?.toInt() ?? 0,
    hostTimeSource: json.containsKey('hostTimeSource')
        ? AudTimeSource.values.byName(json['hostTimeSource']! as String)
        : AudTimeSource.none,
    hostTimeAccuracyNs: (json['hostTimeAccuracyNs'] as num?)?.toInt() ?? 0,
    outputLatencyFrames: (json['outputLatencyFrames'] as num?)?.toInt() ?? 0,
    inputLatencyFrames: (json['inputLatencyFrames'] as num?)?.toInt() ?? 0,
  );

  // ...........................................................................
  /// The frames of the block.
  final int frames;

  /// The sample rate.
  final double sampleRate;

  /// The sample position of the first frame.
  final int samplePosition;

  /// The host time at which the first frame reaches the output.
  final int hostTimeNs;

  /// Where the host time comes from.
  final AudTimeSource hostTimeSource;

  /// The accuracy of the host time; 0 when unknown.
  final int hostTimeAccuracyNs;

  /// The output latency in frames.
  final int outputLatencyFrames;

  /// The input latency in frames.
  final int inputLatencyFrames;

  /// Whether the block carries a host time.
  bool get hasHostTime => hostTimeSource != AudTimeSource.none;

  // ...........................................................................

  /// The time as JSON.
  Map<String, Object?> toJson() => {
    'frames': frames,
    'sampleRate': sampleRate,
    'samplePosition': samplePosition,
    'hostTimeNs': hostTimeNs,
    'hostTimeSource': hostTimeSource.name,
    'hostTimeAccuracyNs': hostTimeAccuracyNs,
    'outputLatencyFrames': outputLatencyFrames,
    'inputLatencyFrames': inputLatencyFrames,
  };

  @override
  bool operator ==(Object other) =>
      other is AudStreamTime &&
      other.frames == frames &&
      other.sampleRate == sampleRate &&
      other.samplePosition == samplePosition &&
      other.hostTimeNs == hostTimeNs &&
      other.hostTimeSource == hostTimeSource &&
      other.hostTimeAccuracyNs == hostTimeAccuracyNs &&
      other.outputLatencyFrames == outputLatencyFrames &&
      other.inputLatencyFrames == inputLatencyFrames;

  @override
  int get hashCode => Object.hash(
    frames,
    sampleRate,
    samplePosition,
    hostTimeNs,
    hostTimeSource,
    hostTimeAccuracyNs,
    outputLatencyFrames,
    inputLatencyFrames,
  );

  @override
  String toString() => 'AudStreamTime(${toJson()})';
}

// #############################################################################
/// A segment of the transport timeline inside one block:
/// `AudTransportSegment` of the ABI.
class AudTransportSegment {
  /// Creates a segment.
  const AudTransportSegment({
    required this.sampleOffset,
    required this.frames,
    this.beatTicks = 0,
    this.tempo = 120,
    this.tempoIncrement = 0,
    this.playing = false,
    this.looping = false,
    this.seek = false,
    this.discontinuity = false,
    this.barStartTicks = 0,
    this.timeSignatureNumerator = 4,
    this.timeSignatureDenominator = 4,
    this.loopStartTicks = 0,
    this.loopEndTicks = 0,
  });

  /// The segment from [toJson].
  factory AudTransportSegment.fromJson(
    Map<String, Object?> json,
  ) => AudTransportSegment(
    sampleOffset: (json['sampleOffset']! as num).toInt(),
    frames: (json['frames']! as num).toInt(),
    beatTicks: AudBeats.ticks((json['beat'] as num?)?.toDouble() ?? 0),
    tempo: (json['tempo'] as num?)?.toDouble() ?? 120,
    tempoIncrement: (json['tempoIncrement'] as num?)?.toDouble() ?? 0,
    playing: json['playing'] == true,
    looping: json['looping'] == true,
    seek: json['seek'] == true,
    discontinuity: json['discontinuity'] == true,
    barStartTicks: AudBeats.ticks((json['barStart'] as num?)?.toDouble() ?? 0),
    timeSignatureNumerator:
        (json['timeSignatureNumerator'] as num?)?.toInt() ?? 4,
    timeSignatureDenominator:
        (json['timeSignatureDenominator'] as num?)?.toInt() ?? 4,
    loopStartTicks: AudBeats.ticks(
      (json['loopStart'] as num?)?.toDouble() ?? 0,
    ),
    loopEndTicks: AudBeats.ticks((json['loopEnd'] as num?)?.toDouble() ?? 0),
  );

  // ...........................................................................
  /// The first frame of the segment inside the block.
  final int sampleOffset;

  /// The frames of the segment.
  final int frames;

  /// The musical position at the first frame, in ticks.
  final int beatTicks;

  /// The tempo at the first frame in beats per minute.
  final double tempo;

  /// The tempo change per frame in beats per minute.
  final double tempoIncrement;

  /// Whether the transport plays.
  final bool playing;

  /// Whether the transport loops.
  final bool looping;

  /// Whether the segment starts with a seek.
  final bool seek;

  /// Whether the position is discontinuous to the previous segment.
  final bool discontinuity;

  /// The beat of the current bar's start, in ticks.
  final int barStartTicks;

  /// The numerator of the time signature.
  final int timeSignatureNumerator;

  /// The denominator of the time signature.
  final int timeSignatureDenominator;

  /// The loop start in ticks; with [looping].
  final int loopStartTicks;

  /// The loop end in ticks; with [looping].
  final int loopEndTicks;

  /// The musical position at the first frame, in beats.
  double get beat => AudBeats.beats(beatTicks);

  /// The `AUD_SEGMENT_*` flags.
  int get flags =>
      (playing ? bindings.AUD_SEGMENT_PLAYING : 0) |
      (looping ? bindings.AUD_SEGMENT_LOOPING : 0) |
      (seek ? bindings.AUD_SEGMENT_SEEK : 0) |
      (discontinuity ? bindings.AUD_SEGMENT_DISCONTINUITY : 0);

  // ...........................................................................
  /// The beats the segment advances in its first [frames] frames at
  /// [sampleRate]; 0 while stopped.
  double beatsAfter(double frames, double sampleRate) {
    if (!playing) return 0;
    return (tempo * frames + tempoIncrement * frames * frames / 2) /
        (60.0 * sampleRate);
  }

  /// The frames the playing segment needs to advance [beats] at
  /// [sampleRate], or a negative number when the tempo slope never reaches
  /// them.
  double framesForBeats(double beats, double sampleRate) {
    final distance = beats * 60.0 * sampleRate;
    if (tempoIncrement == 0) return tempo > 0 ? distance / tempo : -1;
    final discriminant = tempo * tempo + 2 * tempoIncrement * distance;
    if (discriminant < 0) return -1;
    return (-tempo + sqrt(discriminant)) / tempoIncrement;
  }

  /// The segment as JSON, with beats as numbers.
  Map<String, Object?> toJson() => {
    'sampleOffset': sampleOffset,
    'frames': frames,
    'beat': beat,
    'tempo': tempo,
    'tempoIncrement': tempoIncrement,
    'playing': playing,
    'looping': looping,
    'seek': seek,
    'discontinuity': discontinuity,
    'barStart': AudBeats.beats(barStartTicks),
    'timeSignatureNumerator': timeSignatureNumerator,
    'timeSignatureDenominator': timeSignatureDenominator,
    'loopStart': AudBeats.beats(loopStartTicks),
    'loopEnd': AudBeats.beats(loopEndTicks),
  };

  @override
  bool operator ==(Object other) =>
      other is AudTransportSegment &&
      other.sampleOffset == sampleOffset &&
      other.frames == frames &&
      other.beatTicks == beatTicks &&
      other.tempo == tempo &&
      other.tempoIncrement == tempoIncrement &&
      other.flags == flags &&
      other.barStartTicks == barStartTicks &&
      other.timeSignatureNumerator == timeSignatureNumerator &&
      other.timeSignatureDenominator == timeSignatureDenominator &&
      other.loopStartTicks == loopStartTicks &&
      other.loopEndTicks == loopEndTicks;

  @override
  int get hashCode => Object.hash(
    sampleOffset,
    frames,
    beatTicks,
    tempo,
    tempoIncrement,
    flags,
    barStartTicks,
    timeSignatureNumerator,
    timeSignatureDenominator,
    loopStartTicks,
    loopEndTicks,
  );

  @override
  String toString() => 'AudTransportSegment(${toJson()})';
}

// #############################################################################
/// The per-block snapshot of the transport: `AudTransportSnapshot` of the
/// ABI, with the conversions of `aud_transport.h` in Dart.
class AudTransportSnapshot {
  /// Creates a snapshot of [time] covered by [segments].
  const AudTransportSnapshot({
    required this.time,
    this.segments = const [],
    this.capabilities = const AudTransportCapabilities(),
  });

  /// The snapshot from [toJson].
  factory AudTransportSnapshot.fromJson(Map<String, Object?> json) =>
      AudTransportSnapshot(
        time: AudStreamTime.fromJson(json['time']! as Map<String, Object?>),
        capabilities: json.containsKey('capabilities')
            ? AudTransportCapabilities.fromJson(
                json['capabilities']! as Map<String, Object?>,
              )
            : const AudTransportCapabilities(),
        segments: [
          for (final segment in (json['segments'] as List?) ?? const [])
            AudTransportSegment.fromJson(segment as Map<String, Object?>),
        ],
      );

  // ...........................................................................
  /// The time of the block.
  final AudStreamTime time;

  /// The segments covering the block, in order.
  final List<AudTransportSegment> segments;

  /// The capabilities of the provider.
  final AudTransportCapabilities capabilities;

  // ...........................................................................
  /// The segment covering [sampleOffset]: the last one starting at or
  /// before it; null without segments.
  AudTransportSegment? segmentAt(int sampleOffset) {
    AudTransportSegment? found;
    for (final segment in segments) {
      if (segment.sampleOffset <= sampleOffset) found = segment;
    }
    return found;
  }

  /// The musical position at [sampleOffset] of the block in ticks; null
  /// without segments.
  int? beatAtOffset(int sampleOffset) {
    final segment = segmentAt(sampleOffset);
    if (segment == null) return null;
    final frames = (sampleOffset - segment.sampleOffset).toDouble();
    return segment.beatTicks +
        AudBeats.ticks(segment.beatsAfter(frames, time.sampleRate));
  }

  /// The first frame offset whose musical position reaches [beatTicks].
  AudResolution offsetAtBeat(int beatTicks) {
    var playing = false;
    for (final segment in segments) {
      if (!segment.playing) continue;
      final beats = AudBeats.beats(beatTicks - segment.beatTicks);
      if (beats < 0) {
        return playing
            ? const AudResolution.pending()
            : const AudResolution.late();
      }
      playing = true;
      final frames = segment.framesForBeats(beats, time.sampleRate);
      if (frames < 0) continue;
      final rounded = (frames - 1e-9).ceilToDouble();
      if (rounded < segment.frames) {
        return AudResolution.ok(segment.sampleOffset + rounded.toInt());
      }
    }
    return playing
        ? const AudResolution.pending()
        : const AudResolution.unsupported();
  }

  /// The host time at which [sampleOffset] reaches the output; null
  /// without a host time.
  int? hostTimeAtOffset(int sampleOffset) {
    if (!time.hasHostTime) return null;
    return time.hostTimeNs + (sampleOffset * 1e9 / time.sampleRate).round();
  }

  /// The frame offset that reaches the output at [hostTimeNs].
  AudResolution offsetAtHostTime(int hostTimeNs) {
    if (!time.hasHostTime) return const AudResolution.unsupported();
    final frames = (hostTimeNs - time.hostTimeNs) * time.sampleRate / 1e9;
    final rounded = (frames - 1e-9).ceilToDouble();
    if (rounded < 0) return const AudResolution.late();
    if (rounded >= time.frames) return const AudResolution.pending();
    return AudResolution.ok(rounded.toInt());
  }

  /// Resolves [timestamp] to a frame offset of the block.
  AudResolution resolve(AudTimestamp timestamp) => switch (timestamp.domain) {
    AudTimeDomain.immediate => const AudResolution.ok(0),
    AudTimeDomain.sample => _resolveSample(timestamp.value),
    AudTimeDomain.host => offsetAtHostTime(timestamp.value),
    AudTimeDomain.beat => offsetAtBeat(timestamp.value),
  };

  AudResolution _resolveSample(int position) {
    final relative = position - time.samplePosition;
    if (relative < 0) return const AudResolution.late();
    if (relative >= time.frames) return const AudResolution.pending();
    return AudResolution.ok(relative);
  }

  // ...........................................................................
  /// The snapshot as JSON.
  Map<String, Object?> toJson() => {
    'time': time.toJson(),
    'capabilities': capabilities.toJson(),
    'segments': [for (final segment in segments) segment.toJson()],
  };

  @override
  String toString() => 'AudTransportSnapshot(${toJson()})';
}

// #############################################################################
/// The requests to a transport.
enum AudTransportRequestType {
  /// Start playing.
  start(bindings.AUD_TRANSPORT_REQUEST_START),

  /// Stop playing.
  stop(bindings.AUD_TRANSPORT_REQUEST_STOP),

  /// Seek to a beat.
  seek(bindings.AUD_TRANSPORT_REQUEST_SEEK),

  /// Set the tempo.
  setTempo(bindings.AUD_TRANSPORT_REQUEST_SET_TEMPO),

  /// Set the time signature.
  setTimeSignature(bindings.AUD_TRANSPORT_REQUEST_SET_TIME_SIGNATURE),

  /// Set the loop.
  setLoop(bindings.AUD_TRANSPORT_REQUEST_SET_LOOP),

  /// Set the quantum of launches.
  setQuantum(bindings.AUD_TRANSPORT_REQUEST_SET_QUANTUM);

  const AudTransportRequestType(this.code);

  /// The `AUD_TRANSPORT_REQUEST_*` code of the ABI.
  final int code;

  // ...........................................................................
  /// The type with [code].
  static AudTransportRequestType fromCode(int code) => values.firstWhere(
    (type) => type.code == code,
    orElse: () => throw ArgumentError.value(code, 'code', 'Unknown request'),
  );
}

// #############################################################################
/// A request to a transport: `AudTransportRequest` of the ABI.
class AudTransportRequest {
  /// Creates a request.
  const AudTransportRequest({
    required this.type,
    this.at = const AudTimestamp.immediate(),
    this.beatTicks = 0,
    this.beatEndTicks = 0,
    this.value = 0,
    this.numerator = 4,
    this.denominator = 4,
  });

  /// Starts at [at].
  const AudTransportRequest.start({
    AudTimestamp at = const AudTimestamp.immediate(),
  }) : this(type: AudTransportRequestType.start, at: at);

  /// Stops at [at].
  const AudTransportRequest.stop({
    AudTimestamp at = const AudTimestamp.immediate(),
  }) : this(type: AudTransportRequestType.stop, at: at);

  /// Seeks to [beat].
  AudTransportRequest.seek(
    double beat, {
    AudTimestamp at = const AudTimestamp.immediate(),
  }) : this(
         type: AudTransportRequestType.seek,
         at: at,
         beatTicks: AudBeats.ticks(beat),
       );

  /// Sets the tempo to [beatsPerMinute].
  const AudTransportRequest.setTempo(
    double beatsPerMinute, {
    AudTimestamp at = const AudTimestamp.immediate(),
  }) : this(
         type: AudTransportRequestType.setTempo,
         at: at,
         value: beatsPerMinute,
       );

  /// Sets the time signature.
  const AudTransportRequest.setTimeSignature({
    required int numerator,
    required int denominator,
    AudTimestamp at = const AudTimestamp.immediate(),
  }) : this(
         type: AudTransportRequestType.setTimeSignature,
         at: at,
         numerator: numerator,
         denominator: denominator,
       );

  /// Loops from [start] to [end] beats.
  AudTransportRequest.setLoop({
    required double start,
    required double end,
    AudTimestamp at = const AudTimestamp.immediate(),
  }) : this(
         type: AudTransportRequestType.setLoop,
         at: at,
         beatTicks: AudBeats.ticks(start),
         beatEndTicks: AudBeats.ticks(end),
       );

  /// Sets the quantum to [beats].
  const AudTransportRequest.setQuantum(double beats)
    : this(type: AudTransportRequestType.setQuantum, value: beats);

  /// The request from [toJson].
  factory AudTransportRequest.fromJson(Map<String, Object?> json) =>
      AudTransportRequest(
        type: AudTransportRequestType.values.byName(json['type']! as String),
        at: json.containsKey('at')
            ? AudTimestamp.fromJson(json['at']! as Map<String, Object?>)
            : const AudTimestamp.immediate(),
        beatTicks: AudBeats.ticks((json['beat'] as num?)?.toDouble() ?? 0),
        beatEndTicks: AudBeats.ticks(
          (json['beatEnd'] as num?)?.toDouble() ?? 0,
        ),
        value: (json['value'] as num?)?.toDouble() ?? 0,
        numerator: (json['numerator'] as num?)?.toInt() ?? 4,
        denominator: (json['denominator'] as num?)?.toInt() ?? 4,
      );

  // ...........................................................................
  /// What is requested.
  final AudTransportRequestType type;

  /// When the request takes effect.
  final AudTimestamp at;

  /// The seek target or the loop start, in ticks.
  final int beatTicks;

  /// The loop end, in ticks.
  final int beatEndTicks;

  /// The tempo in beats per minute or the quantum in beats.
  final double value;

  /// The numerator of a time signature.
  final int numerator;

  /// The denominator of a time signature.
  final int denominator;

  /// The seek target or the loop start, in beats.
  double get beat => AudBeats.beats(beatTicks);

  /// The loop end, in beats.
  double get beatEnd => AudBeats.beats(beatEndTicks);

  // ...........................................................................

  /// The request as JSON.
  Map<String, Object?> toJson() => {
    'type': type.name,
    'at': at.toJson(),
    'beat': beat,
    'beatEnd': beatEnd,
    'value': value,
    'numerator': numerator,
    'denominator': denominator,
  };

  @override
  bool operator ==(Object other) =>
      other is AudTransportRequest &&
      other.type == type &&
      other.at == at &&
      other.beatTicks == beatTicks &&
      other.beatEndTicks == beatEndTicks &&
      other.value == value &&
      other.numerator == numerator &&
      other.denominator == denominator;

  @override
  int get hashCode => Object.hash(
    type,
    at,
    beatTicks,
    beatEndTicks,
    value,
    numerator,
    denominator,
  );

  @override
  String toString() => 'AudTransportRequest(${toJson()})';
}
