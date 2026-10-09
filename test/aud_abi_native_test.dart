// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_audio_core/aud_audio_core_ffi.dart';
import 'package:test/test.dart';

void main() {
  group('AudAbiNative', () {
    test('major and minor match the native core', () {
      expect(AudAbiNative.nativeMajor, AudAbi.major);
      expect(AudAbiNative.nativeMinor, AudAbi.minor);
      expect(AudAbi.major, 0);
      expect(AudAbi.minor, 3);
    });

    test('struct sizes agree between Dart and C', () {
      expect(AudAbiNative.dartStructSizes, AudAbiNative.nativeStructSizes);
      expect(AudAbiNative.dartStructSizes.keys, AudAbi.structNames);
      expect(AudAbi.structNames, hasLength(18));
    });

    test('nativeSizeOf(name) is -1 for an unknown struct', () {
      expect(AudAbiNative.nativeSizeOf('AudNothing'), -1);
      expect(AudAbiNative.nativeSizeOf('AudEvent'), 36);
    });

    test('nativeIsCompatible(...) follows the rule of AudAbi', () {
      for (final (pm, pn, em, en) in [
        (0, 3, 0, 3),
        (0, 2, 0, 3),
        (1, 0, 2, 0),
      ]) {
        expect(
          AudAbiNative.nativeIsCompatible(
            packageMajor: pm,
            packageMinor: pn,
            engineMajor: em,
            engineMinor: en,
          ),
          AudAbi.isCompatible(
            packageMajor: pm,
            packageMinor: pn,
            engineMajor: em,
            engineMinor: en,
          ),
        );
      }
    });
  });
}
