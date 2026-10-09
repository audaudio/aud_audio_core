// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:ffi';

import 'package:aud_audio_core/aud_audio_core_ffi.dart';
import 'package:test/test.dart';

void main() {
  const time = AudStreamTime(
    frames: 512,
    sampleRate: 48000,
    samplePosition: 96000,
    hostTimeNs: 1000000000,
    hostTimeSource: AudTimeSource.hardware,
    hostTimeAccuracyNs: 1000,
    outputLatencyFrames: 256,
    inputLatencyFrames: 128,
  );
  const playing = AudTransportSegment(
    sampleOffset: 0,
    frames: 256,
    beatTicks: 2 * AudBeats.factor,
    tempo: 120,
    playing: true,
    barStartTicks: 0,
  );
  final accelerating = AudTransportSegment(
    sampleOffset: 256,
    frames: 256,
    beatTicks: AudBeats.ticks(2 + playing.beatsAfter(256, 48000)),
    tempo: 120,
    tempoIncrement: 0.01,
    playing: true,
    discontinuity: false,
  );
  final snapshot = AudTransportSnapshot(
    time: time,
    segments: [playing, accelerating],
    capabilities: const AudTransportCapabilities(tempo: true, hostTime: true),
  );

  group('AudNativeTransportSnapshot', () {
    late AudNativeTransportSnapshot nativeSnapshot;
    setUp(() => nativeSnapshot = AudNativeTransportSnapshot(snapshot));
    tearDown(() => nativeSnapshot.dispose());

    test('agrees with the Dart conversions', () {
      for (final offset in [0, 100, 255, 256, 400, 511]) {
        expect(
          nativeSnapshot.beatAtOffset(offset),
          snapshot.beatAtOffset(offset),
        );
        expect(
          nativeSnapshot.hostTimeAtOffset(offset),
          snapshot.hostTimeAtOffset(offset),
        );
      }
      for (final beat in [1.0, 2.0, 2.005, 2.015, 50.0]) {
        expect(
          nativeSnapshot.offsetAtBeat(AudBeats.ticks(beat)),
          snapshot.offsetAtBeat(AudBeats.ticks(beat)),
          reason: 'beat $beat',
        );
      }
      for (final host in [1, 1000000000, 1001000000, 2000000000]) {
        expect(
          nativeSnapshot.offsetAtHostTime(host),
          snapshot.offsetAtHostTime(host),
        );
      }
      for (final stamp in [
        const AudTimestamp.immediate(),
        const AudTimestamp.sample(96010),
        const AudTimestamp.sample(1),
        const AudTimestamp.host(1000000000),
        AudTimestamp.beat(2.005),
        AudTimestamp.beat(1),
      ]) {
        expect(
          nativeSnapshot.resolve(stamp),
          snapshot.resolve(stamp),
          reason: '$stamp',
        );
      }
      expect(nativeSnapshot.pointer.ref.toDart().segments, snapshot.segments);
    });

    test('reports no segment, no host time and an empty snapshot', () {
      final empty = AudNativeTransportSnapshot(
        const AudTransportSnapshot(
          time: AudStreamTime(frames: 8, sampleRate: 48000, samplePosition: 0),
        ),
      );
      expect(empty.beatAtOffset(0), isNull);
      expect(empty.hostTimeAtOffset(0), isNull);
      expect(empty.offsetAtBeat(0), const AudResolution.unsupported());
      empty.dispose();
      empty.dispose();
      expect(() => empty.beatAtOffset(0), throwsStateError);
      expect(
        () => empty.resolve(const AudTimestamp.immediate()),
        throwsStateError,
      );
    });
  });
}
