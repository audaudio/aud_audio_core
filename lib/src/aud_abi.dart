// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'aud_abi_constants.dart' as bindings;

// #############################################################################
/// The version of the C ABI in `src/aud_abi.h`, its compatibility rule and
/// the names of its result codes and thread tags; [AudAbiNative] checks that
/// the Dart contracts agree with the native core.
abstract final class AudAbi {
  /// The major ABI version the Dart side was written against.
  static const int major = bindings.AUD_ABI_VERSION_MAJOR;

  /// The minor ABI version the Dart side was written against.
  static const int minor = bindings.AUD_ABI_VERSION_MINOR;

  /// The names of the structs of the ABI, in the order of `aud_abi.h`.
  static const List<String> structNames = [
    'AudTimestamp',
    'AudStreamTime',
    'AudTransportSegment',
    'AudTransportSnapshot',
    'AudTransportRequest',
    'AudTransportProviderVTable',
    'AudEvent',
    'AudBusDescriptor',
    'AudEventPortDescriptor',
    'AudParamDescriptor',
    'AudStringKeyDescriptor',
    'AudAudioBus',
    'AudPrepareInfo',
    'AudProcessContext',
    'AudNodeVTable',
    'AudNodeDescriptor',
    'AudHostApi',
    'AudRenderRequest',
  ];

  // ...........................................................................
  /// The name of a result code of the ABI, e.g. `AUD_ERROR_QUEUE_FULL`.
  static String resultName(int code) => switch (code) {
    bindings.AUD_OK => 'AUD_OK',
    bindings.AUD_PENDING => 'AUD_PENDING',
    bindings.AUD_ERROR_INVALID_ARGUMENT => 'AUD_ERROR_INVALID_ARGUMENT',
    bindings.AUD_ERROR_ABI_MAJOR => 'AUD_ERROR_ABI_MAJOR',
    bindings.AUD_ERROR_ABI_MINOR => 'AUD_ERROR_ABI_MINOR',
    bindings.AUD_ERROR_DUPLICATE_TYPE => 'AUD_ERROR_DUPLICATE_TYPE',
    bindings.AUD_ERROR_UNKNOWN_TYPE => 'AUD_ERROR_UNKNOWN_TYPE',
    bindings.AUD_ERROR_QUEUE_FULL => 'AUD_ERROR_QUEUE_FULL',
    bindings.AUD_ERROR_OUT_OF_MEMORY => 'AUD_ERROR_OUT_OF_MEMORY',
    bindings.AUD_ERROR_STATE => 'AUD_ERROR_STATE',
    bindings.AUD_ERROR_FAILED => 'AUD_ERROR_FAILED',
    bindings.AUD_ERROR_UNSUPPORTED => 'AUD_ERROR_UNSUPPORTED',
    bindings.AUD_ERROR_BUFFER_TOO_SMALL => 'AUD_ERROR_BUFFER_TOO_SMALL',
    bindings.AUD_ERROR_STATE_VERSION => 'AUD_ERROR_STATE_VERSION',
    bindings.AUD_ERROR_LATE => 'AUD_ERROR_LATE',
    bindings.AUD_ERROR_NOT_FOUND => 'AUD_ERROR_NOT_FOUND',
    bindings.AUD_ERROR_CYCLE => 'AUD_ERROR_CYCLE',
    bindings.AUD_ERROR_FORMAT => 'AUD_ERROR_FORMAT',
    bindings.AUD_ERROR_LOOKAHEAD => 'AUD_ERROR_LOOKAHEAD',
    bindings.AUD_ERROR_CAPACITY => 'AUD_ERROR_CAPACITY',
    bindings.AUD_ERROR_RETIRED => 'AUD_ERROR_RETIRED',
    bindings.AUD_ERROR_OVERLOAD => 'AUD_ERROR_OVERLOAD',
    _ => 'AUD_RESULT_$code',
  };

  /// The name of a thread affinity tag, e.g. `realtime`.
  static String threadName(int tag) => switch (tag) {
    bindings.AUD_THREAD_CONTROL => 'control',
    bindings.AUD_THREAD_REALTIME => 'realtime',
    bindings.AUD_THREAD_OFFLINE => 'offline',
    _ => 'thread_$tag',
  };

  // ...........................................................................
  /// Whether a package built against [packageMajor].[packageMinor] runs on an
  /// engine of [engineMajor].[engineMinor]: the majors are equal and, in
  /// major 0, the minors too; from major 1 on the engine's minor is at least
  /// the package's.
  static bool isCompatible({
    required int packageMajor,
    required int packageMinor,
    required int engineMajor,
    required int engineMinor,
  }) {
    if (packageMajor != engineMajor) return false;
    if (packageMajor == 0) return packageMinor == engineMinor;
    return packageMinor <= engineMinor;
  }
}
