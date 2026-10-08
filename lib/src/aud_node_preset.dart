// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:typed_data';

import 'aud_node_descriptor.dart';

// #############################################################################
/// A preset of one node: its parameter values, string settings and state
/// blob, as JSON of the schema [jsonSchema] (`doc/schemas/
/// aud_node_preset.schema.json`). Presets travel in graph documents, in
/// plugin state and in files.
class AudNodePreset {
  /// Creates a preset for the node type [typeId].
  const AudNodePreset({
    required this.typeId,
    this.name = '',
    this.nodeVersion,
    this.params = const {},
    this.strings = const {},
    this.state,
    this.stateVersion,
  }) : assert(
         state == null || stateVersion != null,
         'A state needs a state version',
       );

  /// A preset from its JSON; throws a [FormatException] when the JSON does
  /// not follow the schema.
  factory AudNodePreset.fromJson(Map<String, Object?> json) {
    if (json['schema'] != schemaVersion) {
      throw FormatException('schema must be $schemaVersion', json);
    }
    final typeId = json['type'];
    if (typeId is! String || !typeIdPattern.hasMatch(typeId)) {
      throw FormatException('type must be a type id like aud.core.gain', json);
    }
    for (final key in json.keys) {
      if (!_keys.contains(key)) throw FormatException('Unknown key $key', json);
    }
    final name = json['name'] ?? '';
    if (name is! String) throw FormatException('name must be a string', json);
    final nodeVersion = json['nodeVersion'];
    if (nodeVersion is! int?) {
      throw FormatException('nodeVersion must be an integer', json);
    }
    final params = json['params'] ?? const <String, Object?>{};
    if (params is! Map || params.values.any((value) => value is! num)) {
      throw FormatException('params must map ids to numbers', json);
    }
    final strings = json['strings'] ?? const <String, Object?>{};
    if (strings is! Map || strings.values.any((value) => value is! String)) {
      throw FormatException('strings must map ids to strings', json);
    }
    final state = json['state'];
    final stateVersion = json['stateVersion'];
    if (state != null && (state is! String || stateVersion is! int)) {
      throw FormatException(
        'state must be base64 with an integer stateVersion',
        json,
      );
    }
    return AudNodePreset(
      typeId: typeId,
      name: name,
      nodeVersion: nodeVersion,
      params: {
        for (final entry in params.entries)
          entry.key as String: (entry.value as num).toDouble(),
      },
      strings: {
        for (final entry in strings.entries)
          entry.key as String: entry.value as String,
      },
      state: state == null ? null : base64Decode(state as String),
      stateVersion: state == null ? null : stateVersion as int,
    );
  }

  /// A preset from a JSON [text].
  factory AudNodePreset.parse(String text) =>
      AudNodePreset.fromJson(jsonDecode(text) as Map<String, Object?>);

  /// A preset with the default values of [descriptor].
  factory AudNodePreset.defaults(AudNodeDescriptor descriptor) => AudNodePreset(
    typeId: descriptor.typeId,
    nodeVersion: descriptor.version,
    params: {
      for (final param in descriptor.params) param.id: param.defaultValue,
    },
  );

  // ...........................................................................
  /// The version of the preset schema.
  static const int schemaVersion = 1;

  /// The id of the JSON schema.
  static const String schemaId =
      'https://audaudio.github.io/schemas/aud_node_preset.schema.json';

  /// The form of a type id: lower-case words joined by dots, at least two.
  static final RegExp typeIdPattern = RegExp(
    r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$',
  );

  /// The JSON schema of a preset (draft 2020-12).
  static const Map<String, Object?> jsonSchema = {
    r'$schema': 'https://json-schema.org/draft/2020-12/schema',
    r'$id': schemaId,
    'title': 'Audanika Audio Engine node preset',
    'description':
        'The parameter values, string settings and state blob of one node '
        'of the Audanika Audio Engine.',
    'type': 'object',
    'required': ['schema', 'type'],
    'additionalProperties': false,
    'properties': {
      'schema': {
        'description': 'The version of this schema.',
        'const': schemaVersion,
      },
      'type': {
        'description': 'The type id of the node, e.g. aud.core.gain.',
        'type': 'string',
        'pattern': r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$',
      },
      'name': {'description': 'The name of the preset.', 'type': 'string'},
      'nodeVersion': {
        'description':
            'The version of the node type the preset was saved '
            'from.',
        'type': 'integer',
        'minimum': 0,
      },
      'params': {
        'description': 'Parameter values by parameter id.',
        'type': 'object',
        'additionalProperties': {'type': 'number'},
      },
      'strings': {
        'description': 'String settings by string key id.',
        'type': 'object',
        'additionalProperties': {'type': 'string'},
      },
      'state': {
        'description': 'The state blob of the node, base64.',
        'type': 'string',
        'contentEncoding': 'base64',
      },
      'stateVersion': {
        'description': 'The version of the state blob.',
        'type': 'integer',
        'minimum': 0,
      },
    },
    'dependentRequired': {
      'state': ['stateVersion'],
    },
  };

  static const Set<String> _keys = {
    'schema',
    'type',
    'name',
    'nodeVersion',
    'params',
    'strings',
    'state',
    'stateVersion',
  };

  // ...........................................................................
  /// The type id of the node.
  final String typeId;

  /// The name of the preset.
  final String name;

  /// The version of the node type the preset was saved from.
  final int? nodeVersion;

  /// The parameter values by id.
  final Map<String, double> params;

  /// The string settings by id.
  final Map<String, String> strings;

  /// The state blob of the node.
  final Uint8List? state;

  /// The version of the state blob.
  final int? stateVersion;

  // ...........................................................................
  /// The problems the preset has with [descriptor]; empty when it fits.
  List<String> validate(AudNodeDescriptor descriptor) {
    final problems = <String>[];
    if (typeId != descriptor.typeId) {
      problems.add('type $typeId is not ${descriptor.typeId}');
    }
    for (final entry in params.entries) {
      final param = descriptor.param(entry.key);
      if (param == null) {
        problems.add('unknown param ${entry.key}');
      } else if (!param.contains(entry.value)) {
        problems.add(
          'param ${entry.key} = ${entry.value} is outside '
          '${param.min}..${param.max}',
        );
      }
    }
    for (final key in strings.keys) {
      if (descriptor.stringKey(key) == null) {
        problems.add('unknown string key $key');
      }
    }
    if (state != null) {
      if (!descriptor.capabilities.state) {
        problems.add('${descriptor.typeId} has no state');
      } else if (stateVersion != descriptor.stateVersion) {
        problems.add(
          'state version $stateVersion is not ${descriptor.stateVersion}',
        );
      }
    }
    return problems;
  }

  /// A copy with the given fields replaced.
  AudNodePreset copyWith({
    String? typeId,
    String? name,
    int? nodeVersion,
    Map<String, double>? params,
    Map<String, String>? strings,
    Uint8List? state,
    int? stateVersion,
  }) => AudNodePreset(
    typeId: typeId ?? this.typeId,
    name: name ?? this.name,
    nodeVersion: nodeVersion ?? this.nodeVersion,
    params: params ?? this.params,
    strings: strings ?? this.strings,
    state: state ?? this.state,
    stateVersion: stateVersion ?? this.stateVersion,
  );

  /// The preset as JSON of the schema.
  Map<String, Object?> toJson() => {
    'schema': schemaVersion,
    'type': typeId,
    if (name.isNotEmpty) 'name': name,
    if (nodeVersion != null) 'nodeVersion': nodeVersion,
    'params': params,
    if (strings.isNotEmpty) 'strings': strings,
    if (state != null) 'state': base64Encode(state!),
    if (state != null) 'stateVersion': stateVersion,
  };

  /// The preset as a JSON text.
  String toJsonText() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      other is AudNodePreset && other.toJsonText() == toJsonText();

  @override
  int get hashCode => toJsonText().hashCode;

  @override
  String toString() => 'AudNodePreset(${toJsonText()})';
}
