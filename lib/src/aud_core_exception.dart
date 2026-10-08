// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'aud_abi.dart';

// #############################################################################
/// An error of the native core or of a contract, carrying the result code
/// of the ABI.
class AudCoreException implements Exception {
  /// Creates an exception for [code] with a [message].
  const AudCoreException(this.code, this.message);

  /// The result code, e.g. `AUD_ERROR_ABI_MAJOR`.
  final int code;

  /// What went wrong.
  final String message;

  @override
  String toString() => 'AudCoreException(${AudAbi.resultName(code)}): $message';
}
