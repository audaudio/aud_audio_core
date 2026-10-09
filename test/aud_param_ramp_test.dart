// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_audio_core/aud_audio_core_ffi.dart';
import 'package:test/test.dart';

void main() {
  group('AudParamRamp', () {
    late AudParamRamp ramp;
    setUp(() => ramp = AudParamRamp(1));
    tearDown(() => ramp.dispose());

    test('rests at its value', () {
      expect(ramp.value, 1);
      expect(ramp.target, 1);
      expect(ramp.isRamping, isFalse);
      expect(ramp.remaining, 0);
      expect(AudParamRamp().value, 0);
    });

    test('set(value) jumps', () {
      ramp.set(0.5);
      expect(ramp.value, 0.5);
      expect(ramp.isRamping, isFalse);
    });

    test('setTarget(target, frames) ramps linearly and ends exactly', () {
      ramp.setTarget(0, frames: 10);
      expect(ramp.isRamping, isTrue);
      expect(ramp.remaining, 10);
      ramp.advance(4);
      expect(ramp.value, closeTo(0.6, 1e-6));
      expect(ramp.remaining, 6);
      ramp.advance(100);
      expect(ramp.value, 0);
      expect(ramp.isRamping, isFalse);
      ramp.advance(5);
      expect(ramp.value, 0);
    });

    test('setTarget with zero frames jumps', () {
      ramp.setTarget(2, frames: 0);
      expect(ramp.value, 2);
      expect(ramp.isRamping, isFalse);
    });

    test('dispose() closes the ramp', () {
      ramp.dispose();
      ramp.dispose();
      expect(() => ramp.value, throwsStateError);
    });
  });
}
