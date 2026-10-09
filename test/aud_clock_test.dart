// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_audio_core/aud_audio_core.dart';
import 'package:test/test.dart';

void main() {
  group('AudClock', () {
    test('nowNs() is monotonic', () {
      final a = AudClock.nowNs();
      final b = AudClock.nowNs();
      expect(b, greaterThanOrEqualTo(a));
      expect(a, greaterThan(0));
    });
  });
}
