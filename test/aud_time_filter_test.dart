// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_audio_core/aud_audio_core.dart';
import 'package:test/test.dart';

void main() {
  group('AudTimeFilter', () {
    late AudTimeFilter filter;
    setUp(() => filter = AudTimeFilter(sampleRate: 48000, window: 64));
    tearDown(() => filter.dispose());

    test('maps with the nominal rate after one point', () {
      expect(filter.isValid, isFalse);
      expect(filter.count, 0);
      expect(
        filter.add(samplePosition: 0, frames: 256, hostTimeNs: 1000),
        isFalse,
      );
      expect(filter.isValid, isTrue);
      expect(filter.nsPerSample, closeTo(1e9 / 48000, 1e-9));
      expect(filter.hostTimeAt(48000), 1000 + 1000000000);
      expect(filter.sampleAt(1000 + 500000000), 24000);
    });

    test('fits a slower clock through jittering points', () {
      // 48 kHz nominal, the device runs 1 % slow with +-20 us of jitter.
      const nsPerSample = 1e9 / 48000 * 1.01;
      for (var i = 0; i < 100; i++) {
        final jitter = (i % 3 - 1) * 20000;
        filter.add(
          samplePosition: i * 256,
          frames: 256,
          hostTimeNs: (i * 256 * nsPerSample).round() + jitter,
        );
      }
      expect(filter.count, 64);
      expect(filter.resets, 0);
      expect(filter.nsPerSample, closeTo(nsPerSample, 0.1));
      expect(
        filter.hostTimeAt(100 * 256),
        closeTo(100 * 256 * nsPerSample, 30000),
      );
      expect(filter.sampleAt(filter.hostTimeAt(5000)), closeTo(5000, 2));
    });

    test('resets on a discontinuity of the sample position', () {
      filter.add(samplePosition: 0, frames: 256, hostTimeNs: 0);
      filter.add(samplePosition: 256, frames: 256, hostTimeNs: 5333333);
      expect(
        filter.add(samplePosition: 1000, frames: 256, hostTimeNs: 20833333),
        isTrue,
      );
      expect(filter.resets, 1);
      expect(filter.count, 1);
    });

    test('resets when the host time jumps beyond the limit', () {
      filter.deviationLimitNs = 1000000;
      filter.add(samplePosition: 0, frames: 256, hostTimeNs: 0);
      expect(
        filter.add(samplePosition: 256, frames: 256, hostTimeNs: 5333333),
        isFalse,
      );
      expect(
        filter.add(samplePosition: 512, frames: 256, hostTimeNs: 500000000),
        isTrue,
      );
      expect(filter.resets, 1);
    });

    test('keeps the nominal rate when the host clock runs backwards', () {
      filter.deviationLimitNs = 1 << 40;
      filter.add(samplePosition: 0, frames: 256, hostTimeNs: 1000000);
      filter.add(samplePosition: 256, frames: 256, hostTimeNs: 0);
      expect(filter.nsPerSample, closeTo(1e9 / 48000, 1e-9));
    });

    test('reset() forgets the points and dispose() closes it', () {
      filter.add(samplePosition: 0, frames: 256, hostTimeNs: 0);
      filter.reset();
      expect(filter.isValid, isFalse);
      expect(filter.resets, 0);
      filter.dispose();
      filter.dispose();
      expect(() => filter.isValid, throwsStateError);
      expect(filter.window, 64);
      expect(AudTimeFilter.maxPoints, 512);
      expect(AudTimeFilter.defaultDeviationLimitNs, 250000000);
    });

    test('clamps the window to the limits', () {
      final small = AudTimeFilter(sampleRate: 48000, window: 1);
      for (var i = 0; i < 5; i++) {
        small.add(samplePosition: i * 8, frames: 8, hostTimeNs: i * 166667);
      }
      expect(small.count, 2);
      small.dispose();
      final large = AudTimeFilter(sampleRate: 48000, window: 10000);
      expect(large.window, 10000);
      large.dispose();
    });
  });
}
