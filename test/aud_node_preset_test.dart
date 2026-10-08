// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aud_audio_core/aud_audio_core.dart';
import 'package:test/test.dart';

void main() {
  const gain = AudNodeDescriptor(
    typeId: 'aud.core.gain',
    version: 1,
    capabilities: AudNodeCapabilities(state: true),
    stateVersion: 1,
    params: [AudParamDescriptor(id: 'gain', max: 2, defaultValue: 1)],
    stringKeys: [AudStringKeyDescriptor(key: 1, id: 'file')],
  );
  final preset = AudNodePreset(
    typeId: 'aud.core.gain',
    name: 'Loud',
    nodeVersion: 1,
    params: const {'gain': 1.5},
    strings: const {'file': 'a.sfz'},
    state: Uint8List.fromList([0, 0, 192, 63]),
    stateVersion: 1,
  );

  group('AudNodePreset', () {
    test('json round trip, parse and equality', () {
      final json = preset.toJson();
      expect(json['schema'], 1);
      expect(json['state'], base64Encode(preset.state!));
      expect(AudNodePreset.fromJson(json), preset);
      expect(AudNodePreset.parse(preset.toJsonText()), preset);
      expect(
        preset.hashCode,
        AudNodePreset.parse(preset.toJsonText()).hashCode,
      );
      expect(preset.toString(), contains('Loud'));
      final bare = AudNodePreset.fromJson({'schema': 1, 'type': 'a.b'});
      expect(bare.params, isEmpty);
      expect(bare.state, isNull);
      expect(bare.toJson().containsKey('name'), isFalse);
    });

    test('fromJson(json) rejects what the schema rejects', () {
      final bad = <Map<String, Object?>>[
        {'type': 'a.b'},
        {'schema': 2, 'type': 'a.b'},
        {'schema': 1, 'type': 'ab'},
        {'schema': 1, 'type': 'a.b', 'x': 1},
        {'schema': 1, 'type': 'a.b', 'name': 1},
        {'schema': 1, 'type': 'a.b', 'nodeVersion': 'x'},
        {
          'schema': 1,
          'type': 'a.b',
          'params': {'g': 'x'},
        },
        {
          'schema': 1,
          'type': 'a.b',
          'strings': {'g': 1},
        },
        {'schema': 1, 'type': 'a.b', 'state': 'AA=='},
        {'schema': 1, 'type': 'a.b', 'state': 1, 'stateVersion': 1},
      ];
      for (final json in bad) {
        expect(
          () => AudNodePreset.fromJson(json),
          throwsFormatException,
          reason: '$json',
        );
      }
    });

    test('defaults(descriptor) takes the default values', () {
      final defaults = AudNodePreset.defaults(gain);
      expect(defaults.params, {'gain': 1});
      expect(defaults.nodeVersion, 1);
      expect(defaults.validate(gain), isEmpty);
    });

    test('validate(descriptor) names every problem', () {
      expect(preset.validate(gain), isEmpty);
      final wrong = preset.copyWith(
        typeId: 'aud.core.other',
        params: {'gain': 5, 'x': 1},
        strings: {'y': ''},
        stateVersion: 2,
      );
      expect(wrong.validate(gain), [
        'type aud.core.other is not aud.core.gain',
        'param gain = 5.0 is outside 0.0..2.0',
        'unknown param x',
        'unknown string key y',
        'state version 2 is not 1',
      ]);
      const stateless = AudNodeDescriptor(
        typeId: 'aud.core.gain',
        params: [AudParamDescriptor(id: 'gain', max: 2, defaultValue: 1)],
        stringKeys: [AudStringKeyDescriptor(key: 1, id: 'file')],
      );
      expect(preset.validate(stateless), ['aud.core.gain has no state']);
      expect(preset.copyWith(name: 'x').name, 'x');
    });

    test('the schema file matches the Dart constant', () {
      final file = File('doc/schemas/aud_node_preset.schema.json');
      expect(file.existsSync(), isTrue, reason: 'schema file missing');
      expect(jsonDecode(file.readAsStringSync()), AudNodePreset.jsonSchema);
      expect(AudNodePreset.jsonSchema[r'$id'], AudNodePreset.schemaId);
    });
  });
}
