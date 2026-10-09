// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_audio_core/aud_audio_core.dart';
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

  group('AudTransportCapabilities', () {
    test('flags, json and equality round trip', () {
      const caps = AudTransportCapabilities(
        tempo: true,
        seek: true,
        startStop: true,
        timeSignature: true,
        hostTime: true,
        loop: true,
      );
      expect(AudTransportCapabilities.fromFlags(caps.flags), caps);
      expect(AudTransportCapabilities.fromJson(caps.toJson()), caps);
      expect(caps.flags, 63);
      expect(caps.hashCode, 63);
      expect(caps.toString(), contains('tempo: true'));
      expect(const AudTransportCapabilities().flags, 0);
    });
  });

  group('AudStreamTime', () {
    test('json round trip', () {
      expect(AudStreamTime.fromJson(time.toJson()), time);
      expect(time.hashCode, AudStreamTime.fromJson(time.toJson()).hashCode);
      expect(time.hasHostTime, isTrue);
      expect(time.toString(), contains('frames: 512'));
      final minimal = AudStreamTime.fromJson({
        'frames': 1,
        'sampleRate': 1,
        'samplePosition': 0,
      });
      expect(minimal.hasHostTime, isFalse);
      expect(minimal, isNot(time));
    });
  });

  group('AudTransportSegment', () {
    test('json round trip', () {
      for (final segment in [playing, accelerating]) {
        expect(AudTransportSegment.fromJson(segment.toJson()), segment);
        expect(
          segment.hashCode,
          AudTransportSegment.fromJson(segment.toJson()).hashCode,
        );
      }
      expect(playing.beat, 2);
      expect(playing.flags, AUD_SEGMENT_PLAYING);
      expect(playing.toString(), contains('tempo: 120'));
      final minimal = AudTransportSegment.fromJson({
        'sampleOffset': 0,
        'frames': 8,
      });
      expect(minimal.playing, isFalse);
      expect(minimal.beatsAfter(100, 48000), 0);
    });

    test('beatsAfter(frames) and framesForBeats(beats) invert each other', () {
      for (final segment in [playing, accelerating]) {
        final beats = segment.beatsAfter(200, 48000);
        expect(segment.framesForBeats(beats, 48000), closeTo(200, 1e-6));
      }
      expect(playing.beatsAfter(24000, 48000), 1);
      const stopped = AudTransportSegment(
        sampleOffset: 0,
        frames: 8,
        tempo: 0,
        playing: true,
      );
      expect(stopped.framesForBeats(1, 48000), -1);
      const decelerating = AudTransportSegment(
        sampleOffset: 0,
        frames: 8,
        tempo: 1,
        tempoIncrement: -1,
        playing: true,
      );
      expect(decelerating.framesForBeats(100, 48000), -1);
    });
  });

  group('AudTransportSnapshot', () {
    test('segmentAt(offset) finds the covering segment', () {
      expect(snapshot.segmentAt(0), playing);
      expect(snapshot.segmentAt(255), playing);
      expect(snapshot.segmentAt(256), accelerating);
      expect(const AudTransportSnapshot(time: time).segmentAt(0), isNull);
    });

    test('beatAtOffset(offset) integrates the tempo', () {
      expect(snapshot.beatAtOffset(0), 2 * AudBeats.factor);
      expect(AudBeats.beats(snapshot.beatAtOffset(240)!), closeTo(2.01, 1e-9));
      expect(const AudTransportSnapshot(time: time).beatAtOffset(0), isNull);
    });

    test('offsetAtBeat(beat) finds the frame reaching the beat', () {
      expect(
        snapshot.offsetAtBeat(AudBeats.ticks(2)),
        const AudResolution.ok(0),
      );
      expect(
        snapshot.offsetAtBeat(AudBeats.ticks(2.005)),
        const AudResolution.ok(120),
      );
      expect(
        snapshot.offsetAtBeat(AudBeats.ticks(1)),
        const AudResolution.late(),
      );
      expect(
        snapshot.offsetAtBeat(AudBeats.ticks(50)),
        const AudResolution.pending(),
      );
      final second = snapshot.offsetAtBeat(AudBeats.ticks(2.015));
      expect(second.isOk, isTrue);
      expect(second.offset, inInclusiveRange(256, 511));
      final stopped = AudTransportSnapshot(
        time: time,
        segments: const [AudTransportSegment(sampleOffset: 0, frames: 512)],
      );
      expect(stopped.offsetAtBeat(0), const AudResolution.unsupported());
      final noTempo = AudTransportSnapshot(
        time: time,
        segments: const [
          AudTransportSegment(
            sampleOffset: 0,
            frames: 512,
            tempo: 0,
            playing: true,
          ),
        ],
      );
      expect(
        noTempo.offsetAtBeat(AudBeats.ticks(1)),
        const AudResolution.pending(),
      );
    });

    test('host time conversions', () {
      expect(snapshot.hostTimeAtOffset(48), 1000000000 + 1000000);
      expect(
        snapshot.offsetAtHostTime(1000000000 + 1000000),
        const AudResolution.ok(48),
      );
      expect(snapshot.offsetAtHostTime(1), const AudResolution.late());
      expect(
        snapshot.offsetAtHostTime(2000000000),
        const AudResolution.pending(),
      );
      final noHost = AudTransportSnapshot(
        time: const AudStreamTime(
          frames: 8,
          sampleRate: 48000,
          samplePosition: 0,
        ),
      );
      expect(noHost.hostTimeAtOffset(0), isNull);
      expect(noHost.offsetAtHostTime(0), const AudResolution.unsupported());
    });

    test('resolve(timestamp) covers every domain', () {
      expect(
        snapshot.resolve(const AudTimestamp.immediate()),
        const AudResolution.ok(0),
      );
      expect(
        snapshot.resolve(const AudTimestamp.sample(96010)),
        const AudResolution.ok(10),
      );
      expect(
        snapshot.resolve(const AudTimestamp.sample(1)),
        const AudResolution.late(),
      );
      expect(
        snapshot.resolve(const AudTimestamp.sample(96512)),
        const AudResolution.pending(),
      );
      expect(
        snapshot.resolve(const AudTimestamp.host(1000000000)),
        const AudResolution.ok(0),
      );
      expect(snapshot.resolve(AudTimestamp.beat(2)), const AudResolution.ok(0));
    });

    test('json round trip and toString', () {
      final copy = AudTransportSnapshot.fromJson(snapshot.toJson());
      expect(copy.segments, snapshot.segments);
      expect(copy.capabilities, snapshot.capabilities);
      expect(copy.time, time);
      expect(snapshot.toString(), contains('segments'));
      final bare = AudTransportSnapshot.fromJson({'time': time.toJson()});
      expect(bare.segments, isEmpty);
      expect(bare.capabilities, const AudTransportCapabilities());
    });
  });

  group('AudTransportRequest', () {
    test('constructors, json round trip', () {
      final requests = [
        const AudTransportRequest.start(),
        const AudTransportRequest.stop(at: AudTimestamp.sample(5)),
        AudTransportRequest.seek(4),
        const AudTransportRequest.setTempo(128),
        const AudTransportRequest.setTimeSignature(
          numerator: 3,
          denominator: 4,
        ),
        AudTransportRequest.setLoop(start: 1, end: 5),
        const AudTransportRequest.setQuantum(4),
      ];
      for (final request in requests) {
        expect(AudTransportRequest.fromJson(request.toJson()), request);
        expect(
          request.hashCode,
          AudTransportRequest.fromJson(request.toJson()).hashCode,
        );
      }
      expect(AudTransportRequest.seek(4).beat, 4);
      expect(AudTransportRequest.setLoop(start: 1, end: 5).beatEnd, 5);
      expect(requests[0].toString(), contains('start'));
      expect(
        AudTransportRequest.fromJson({'type': 'start'}).at.isImmediate,
        true,
      );
      expect(
        AudTransportRequestType.fromCode(AUD_TRANSPORT_REQUEST_SEEK),
        AudTransportRequestType.seek,
      );
      expect(() => AudTransportRequestType.fromCode(99), throwsArgumentError);
    });
  });
}
