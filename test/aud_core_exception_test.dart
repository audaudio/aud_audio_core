// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_audio_core/aud_audio_core.dart';
import 'package:test/test.dart';

void main() {
  group('AudCoreException', () {
    test('names the code', () {
      const e = AudCoreException(AUD_ERROR_ABI_MAJOR, 'wrong major');
      expect(
        e.toString(),
        'AudCoreException(AUD_ERROR_ABI_MAJOR): wrong major',
      );
    });
  });
}
