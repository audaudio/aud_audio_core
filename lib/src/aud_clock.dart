// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'aud_clock_stub.dart'
    if (dart.library.ffi) 'aud_clock_native.dart'
    as platform;

// #############################################################################
/// The monotonic host clock of decision time-001, `aud_clock.h` of the
/// native core: the clock the engine measures against on every platform.
/// The web has no clock of the engine until S5.
abstract final class AudClock {
  /// The host time now, in nanoseconds.
  static int nowNs() => platform.nowNs();
}
