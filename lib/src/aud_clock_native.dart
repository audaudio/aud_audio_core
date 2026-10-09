// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'aud_audio_core_bindings_generated.dart' as bindings;

/// The host time now, in nanoseconds, from the native core.
int nowNs() => bindings.aud_core_clock_now_ns();
