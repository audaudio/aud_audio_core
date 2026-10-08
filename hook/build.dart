// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

// Builds the native core as C++17: the ABI version and layout functions,
// the handle APIs of the time filter, the transport conversions, the UMP
// helpers, the ramp and the fixed-block adapter, and the reference node.
// The ABI and the utilities are header only (src/*.h, src/*.hpp); packages
// compile against them and never link the core.
void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    final packageName = input.packageName;
    final targetOS = input.config.code.targetOS;
    final cbuilder = CBuilder.library(
      name: packageName,
      assetName: 'src/${packageName}_bindings_generated.dart',
      sources: ['src/$packageName.cpp'],
      includes: ['src'],
      language: Language.cpp,
      std: 'c++17',
      cppLinkStdLib: targetOS == OS.android ? 'c++_static' : null,
      libraries: [if (targetOS == OS.android) 'm'],
    );
    await cbuilder.run(
      input: input,
      output: output,
      logger: Logger('')
        ..level = Level.ALL
        ..onRecord.listen((record) => stdout.writeln(record.message)),
    );
  });
}
