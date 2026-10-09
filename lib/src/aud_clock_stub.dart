// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

/// The host clock where the native core is not available.
int nowNs() =>
    throw UnsupportedError('The host clock needs the native core (web: S5)');
