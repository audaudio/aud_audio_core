// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:typed_data';

import 'package:aud_audio_core/aud_audio_core_ffi.dart';
import 'package:test/test.dart';

void main() {
  group('AudFixedBlockAdapter', () {
    late AudFixedBlockAdapter adapter;
    setUp(() => adapter = AudFixedBlockAdapter(blockSize: 4, channels: 2));
    tearDown(() => adapter.dispose());

    test('reports its latency as one block', () {
      expect(adapter.latency, 4);
      expect(adapter.blockSize, 4);
      expect(adapter.channels, 2);
    });

    test('renders fixed blocks and delays the output by one block', () {
      final input = [
        Float32List.fromList([1, 2, 3, 4, 5, 6, 7]),
        Float32List.fromList([10, 20, 30, 40, 50, 60, 70]),
      ];
      final output = [Float32List(7), Float32List(7)];
      final blocks = <List<double>>[];
      adapter.process(
        input: input,
        output: output,
        renderBlock: (inLists, outLists) {
          blocks.add(inLists[0].toList());
          for (var c = 0; c < 2; c++) {
            for (var i = 0; i < 4; i++) {
              outLists[c][i] = inLists[c][i] * 2;
            }
          }
        },
      );
      expect(blocks, [
        [1, 2, 3, 4],
      ]);
      expect(output[0], [0, 0, 0, 0, 2, 4, 6]);
      expect(output[1], [0, 0, 0, 0, 20, 40, 60]);

      // The next call continues where the previous one stopped.
      final more = [
        Float32List.fromList([8]),
        Float32List.fromList([80]),
      ];
      final moreOut = [Float32List(1), Float32List(1)];
      adapter.process(
        input: more,
        output: moreOut,
        renderBlock: (inLists, outLists) {
          blocks.add(inLists[0].toList());
          for (var c = 0; c < 2; c++) {
            outLists[c].setAll(0, inLists[c]);
          }
        },
      );
      expect(blocks.last, [5, 6, 7, 8]);
      expect(moreOut[0], [8]);
    });

    test('reset() clears the pending output', () {
      final input = [
        Float32List.fromList([1, 2, 3, 4]),
        Float32List(4),
      ];
      final output = [Float32List(4), Float32List(4)];
      void copy(List<Float32List> i, List<Float32List> o) {
        for (var c = 0; c < 2; c++) {
          o[c].setAll(0, i[c]);
        }
      }

      adapter.process(input: input, output: output, renderBlock: copy);
      adapter.reset();
      adapter.process(input: input, output: output, renderBlock: copy);
      expect(output[0], [0, 0, 0, 0]);
    });

    test('rejects wrong channel counts, sizes and use after dispose', () {
      expect(
        () => adapter.process(
          input: [Float32List(1)],
          output: [Float32List(1), Float32List(1)],
          renderBlock: (_, _) {},
        ),
        throwsArgumentError,
      );
      expect(
        () => adapter.process(
          input: [Float32List(2), Float32List(2)],
          output: [Float32List(1), Float32List(2)],
          renderBlock: (_, _) {},
        ),
        throwsArgumentError,
      );
      expect(
        () => AudFixedBlockAdapter(blockSize: 0, channels: 1),
        throwsArgumentError,
      );
      adapter.dispose();
      adapter.dispose();
      expect(() => adapter.latency, throwsStateError);
    });
  });
}
