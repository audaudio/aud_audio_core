// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// A web entry point of the platform-neutral API: `dart compile js` fails
// when dart:ffi reaches it (web-001).

// ignore_for_file: avoid_print

import 'package:aud_audio_core/aud_audio_core.dart';

void main() {
  print(AudAbi.resultName(AUD_OK));
  print(const AudTransportRequest.start().toJson());
  print(AudEvent.fromWords(type: AUD_EVENT_PARAM, words: const [0, 0, 0, 0]));
}
