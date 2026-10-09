// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_audio_core/aud_audio_core.dart';
import 'package:test/test.dart';

void main() {
  group('AudTimeDomain', () {
    test('fromCode(code) maps the ABI codes', () {
      for (final domain in AudTimeDomain.values) {
        expect(AudTimeDomain.fromCode(domain.code), domain);
      }
      expect(AudTimeDomain.sample.code, AUD_TIME_SAMPLE);
      expect(() => AudTimeDomain.fromCode(9), throwsArgumentError);
    });
  });

  group('AudTimeSource', () {
    test('fromCode(code) maps the ABI codes', () {
      for (final source in AudTimeSource.values) {
        expect(AudTimeSource.fromCode(source.code), source);
      }
      expect(AudTimeSource.hardware.code, AUD_TIME_SOURCE_HARDWARE);
      expect(() => AudTimeSource.fromCode(9), throwsArgumentError);
    });
  });

  group('AudBeats', () {
    test('converts beats and ticks with the CLAP factor', () {
      expect(AudBeats.factor, 1 << 31);
      expect(AudBeats.ticks(1.5), 3 * (1 << 30));
      expect(AudBeats.beats(AudBeats.ticks(2.25)), 2.25);
    });
  });

  group('AudTimestamp', () {
    test('fromCodes(...) reads the fields of the native struct', () {
      expect(
        AudTimestamp.fromCodes(
          domain: AUD_TIME_HOST,
          value: 9,
          source: AUD_TIME_SOURCE_ESTIMATED,
        ),
        const AudTimestamp.host(9, source: AudTimeSource.estimated),
      );
      expect(
        AudTimestamp.fromCodes(domain: AUD_TIME_SAMPLE, value: 7),
        const AudTimestamp.sample(7),
      );
    });

    test('constructors set the domain and the value', () {
      expect(const AudTimestamp.immediate().isImmediate, isTrue);
      expect(const AudTimestamp.sample(48000).value, 48000);
      final host = const AudTimestamp.host(5, source: AudTimeSource.estimated);
      expect(host.domain, AudTimeDomain.host);
      expect(host.source, AudTimeSource.estimated);
      expect(AudTimestamp.beat(2).beats, 2);
      expect(const AudTimestamp.beatTicks(1 << 31).beats, 1);
      expect(() => host.beats, throwsStateError);
    });

    test('toJson() and fromJson(json) round trip', () {
      for (final stamp in [
        const AudTimestamp.immediate(),
        const AudTimestamp.sample(7),
        const AudTimestamp.host(9, source: AudTimeSource.synthesized),
        AudTimestamp.beat(1.25),
      ]) {
        expect(AudTimestamp.fromJson(stamp.toJson()), stamp);
      }
      expect(AudTimestamp.fromJson({'domain': 'immediate'}).isImmediate, true);
    });

    test('equality, hashCode and toString', () {
      expect(const AudTimestamp.sample(1), const AudTimestamp.sample(1));
      expect(
        const AudTimestamp.sample(1).hashCode,
        const AudTimestamp.sample(1).hashCode,
      );
      expect(const AudTimestamp.sample(1), isNot(const AudTimestamp.host(1)));
      expect(
        const AudTimestamp.immediate().toString(),
        'AudTimestamp.immediate',
      );
      expect(const AudTimestamp.sample(1).toString(), 'AudTimestamp.sample(1)');
      expect(
        const AudTimestamp.host(1).toString(),
        'AudTimestamp.host(1 ns, hardware)',
      );
      expect(AudTimestamp.beat(2).toString(), 'AudTimestamp.beat(2.0)');
    });
  });

  group('AudResolution', () {
    test('names its outcomes', () {
      expect(const AudResolution.ok(3).isOk, isTrue);
      expect(const AudResolution.ok(3).offset, 3);
      expect(const AudResolution.late().isLate, isTrue);
      expect(const AudResolution.pending().isPending, isTrue);
      expect(const AudResolution.unsupported().isUnsupported, isTrue);
      expect(const AudResolution.invalid().code, AUD_ERROR_INVALID_ARGUMENT);
      expect(
        const AudResolution.fromCode(AUD_OK, 4),
        const AudResolution.ok(4),
      );
      expect(
        const AudResolution.ok(4).hashCode,
        const AudResolution.ok(4).hashCode,
      );
      expect(
        const AudResolution.ok(4).toString(),
        'AudResolution(code: 0, offset: 4)',
      );
    });
  });
}
