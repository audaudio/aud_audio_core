// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_audio_core/aud_audio_core.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const AudCoreExampleApp());
}

/// Shows the ABI version of the native core and the struct size check.
class AudCoreExampleApp extends StatelessWidget {
  /// Creates the example app.
  const AudCoreExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final sizesAgree =
        AudAbi.dartStructSizes.toString() ==
        AudAbi.nativeStructSizes.toString();
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('aud_audio_core')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ABI version (Dart): ${AudAbi.major}.${AudAbi.minor}'),
              Text(
                'ABI version (native): '
                '${AudAbi.nativeMajor}.${AudAbi.nativeMinor}',
              ),
              Text('Struct sizes agree: $sizesAgree'),
            ],
          ),
        ),
      ),
    );
  }
}
