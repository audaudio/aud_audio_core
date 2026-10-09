// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// ignore: implementation_imports
import 'package:aud_audio_core/src/aud_clock_native.dart';
import 'package:test/test.dart';

void main() {
  group('nowNs()', () {
    test('reads the clock of the native core', () {
      expect(nowNs(), greaterThan(0));
    });
  });
}
