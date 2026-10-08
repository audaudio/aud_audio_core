// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'aud_audio_core_bindings_generated.dart' as bindings;

String _text(Pointer<Char> pointer) =>
    pointer == nullptr ? '' : pointer.cast<Utf8>().toDartString();

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// #############################################################################
/// An audio bus of a node type: `AudBusDescriptor` of the ABI.
class AudBusDescriptor {
  /// Creates a bus.
  const AudBusDescriptor({
    required this.id,
    this.name = '',
    this.main = true,
    this.sidechain = false,
    this.optional = false,
    this.minChannels = 1,
    this.maxChannels = 16,
    this.defaultChannels = 2,
  });

  /// The bus from its native struct.
  factory AudBusDescriptor.fromNative(bindings.AudBusDescriptor native) =>
      AudBusDescriptor(
        id: _text(native.id),
        name: _text(native.name),
        main: native.flags & bindings.AUD_BUS_MAIN != 0,
        sidechain: native.flags & bindings.AUD_BUS_SIDECHAIN != 0,
        optional: native.flags & bindings.AUD_BUS_OPTIONAL != 0,
        minChannels: native.min_channels,
        maxChannels: native.max_channels,
        defaultChannels: native.default_channels,
      );

  /// The bus from [toJson].
  factory AudBusDescriptor.fromJson(Map<String, Object?> json) =>
      AudBusDescriptor(
        id: json['id']! as String,
        name: json['name'] as String? ?? '',
        main: json['main'] != false,
        sidechain: json['sidechain'] == true,
        optional: json['optional'] == true,
        minChannels: (json['minChannels'] as num?)?.toInt() ?? 1,
        maxChannels: (json['maxChannels'] as num?)?.toInt() ?? 16,
        defaultChannels: (json['defaultChannels'] as num?)?.toInt() ?? 2,
      );

  // ...........................................................................
  /// The stable identifier, e.g. `in`.
  final String id;

  /// The display name.
  final String name;

  /// Whether the bus is the main bus.
  final bool main;

  /// Whether the bus is a sidechain.
  final bool sidechain;

  /// Whether the bus may stay unconnected.
  final bool optional;

  /// The least channels the node accepts.
  final int minChannels;

  /// The most channels the node accepts.
  final int maxChannels;

  /// The channels the node is created with.
  final int defaultChannels;

  /// The `AUD_BUS_*` flags.
  int get flags =>
      (main ? bindings.AUD_BUS_MAIN : 0) |
      (sidechain ? bindings.AUD_BUS_SIDECHAIN : 0) |
      (optional ? bindings.AUD_BUS_OPTIONAL : 0);

  /// The bus as JSON.
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'main': main,
    'sidechain': sidechain,
    'optional': optional,
    'minChannels': minChannels,
    'maxChannels': maxChannels,
    'defaultChannels': defaultChannels,
  };

  @override
  bool operator ==(Object other) =>
      other is AudBusDescriptor &&
      other.id == id &&
      other.name == name &&
      other.flags == flags &&
      other.minChannels == minChannels &&
      other.maxChannels == maxChannels &&
      other.defaultChannels == defaultChannels;

  @override
  int get hashCode =>
      Object.hash(id, name, flags, minChannels, maxChannels, defaultChannels);

  @override
  String toString() => 'AudBusDescriptor(${toJson()})';
}

// #############################################################################
/// An event port of a node type: `AudEventPortDescriptor` of the ABI.
class AudEventPortDescriptor {
  /// Creates an event port.
  const AudEventPortDescriptor({
    required this.id,
    this.name = '',
    this.midi = false,
    this.control = false,
  });

  /// The port from its native struct.
  factory AudEventPortDescriptor.fromNative(
    bindings.AudEventPortDescriptor native,
  ) => AudEventPortDescriptor(
    id: _text(native.id),
    name: _text(native.name),
    midi: native.flags & bindings.AUD_EVENT_PORT_MIDI != 0,
    control: native.flags & bindings.AUD_EVENT_PORT_CONTROL != 0,
  );

  /// The port from [toJson].
  factory AudEventPortDescriptor.fromJson(Map<String, Object?> json) =>
      AudEventPortDescriptor(
        id: json['id']! as String,
        name: json['name'] as String? ?? '',
        midi: json['midi'] == true,
        control: json['control'] == true,
      );

  // ...........................................................................
  /// The stable identifier, e.g. `midi`.
  final String id;

  /// The display name.
  final String name;

  /// Whether the port takes MIDI (UMP) events.
  final bool midi;

  /// Whether the port takes control events.
  final bool control;

  /// The `AUD_EVENT_PORT_*` flags.
  int get flags =>
      (midi ? bindings.AUD_EVENT_PORT_MIDI : 0) |
      (control ? bindings.AUD_EVENT_PORT_CONTROL : 0);

  /// The port as JSON.
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'midi': midi,
    'control': control,
  };

  @override
  bool operator ==(Object other) =>
      other is AudEventPortDescriptor &&
      other.id == id &&
      other.name == name &&
      other.flags == flags;

  @override
  int get hashCode => Object.hash(id, name, flags);

  @override
  String toString() => 'AudEventPortDescriptor(${toJson()})';
}

// #############################################################################
/// A parameter of a node type: `AudParamDescriptor` of the ABI.
class AudParamDescriptor {
  /// Creates a parameter.
  const AudParamDescriptor({
    required this.id,
    this.name = '',
    this.unit = '',
    this.min = 0,
    this.max = 1,
    this.defaultValue = 0,
    this.automatable = true,
    this.ramped = false,
    this.stepped = false,
    this.logarithmic = false,
    this.boolean = false,
    this.hidden = false,
    this.steps = 0,
  });

  /// The parameter from its native struct.
  factory AudParamDescriptor.fromNative(bindings.AudParamDescriptor native) =>
      AudParamDescriptor(
        id: _text(native.id),
        name: _text(native.name),
        unit: _text(native.unit),
        min: native.min_value,
        max: native.max_value,
        defaultValue: native.default_value,
        automatable: native.flags & bindings.AUD_PARAM_AUTOMATABLE != 0,
        ramped: native.flags & bindings.AUD_PARAM_RAMPED != 0,
        stepped: native.flags & bindings.AUD_PARAM_STEPPED != 0,
        logarithmic: native.flags & bindings.AUD_PARAM_LOGARITHMIC != 0,
        boolean: native.flags & bindings.AUD_PARAM_BOOLEAN != 0,
        hidden: native.flags & bindings.AUD_PARAM_HIDDEN != 0,
        steps: native.steps,
      );

  /// The parameter from [toJson].
  factory AudParamDescriptor.fromJson(Map<String, Object?> json) =>
      AudParamDescriptor(
        id: json['id']! as String,
        name: json['name'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
        min: (json['min'] as num?)?.toDouble() ?? 0,
        max: (json['max'] as num?)?.toDouble() ?? 1,
        defaultValue: (json['default'] as num?)?.toDouble() ?? 0,
        automatable: json['automatable'] != false,
        ramped: json['ramped'] == true,
        stepped: json['stepped'] == true,
        logarithmic: json['logarithmic'] == true,
        boolean: json['boolean'] == true,
        hidden: json['hidden'] == true,
        steps: (json['steps'] as num?)?.toInt() ?? 0,
      );

  // ...........................................................................
  /// The stable identifier, e.g. `frequency`.
  final String id;

  /// The display name.
  final String name;

  /// The unit, e.g. `Hz`.
  final String unit;

  /// The smallest value.
  final double min;

  /// The largest value.
  final double max;

  /// The value a node starts with.
  final double defaultValue;

  /// Whether automation may change the parameter.
  final bool automatable;

  /// Whether changes ramp.
  final bool ramped;

  /// Whether the value takes [steps] discrete values.
  final bool stepped;

  /// Whether the scale is logarithmic.
  final bool logarithmic;

  /// Whether the parameter is a switch.
  final bool boolean;

  /// Whether the parameter is hidden from the user.
  final bool hidden;

  /// The discrete values between [min] and [max] of a [stepped] parameter.
  final int steps;

  /// The `AUD_PARAM_*` flags.
  int get flags =>
      (automatable ? bindings.AUD_PARAM_AUTOMATABLE : 0) |
      (ramped ? bindings.AUD_PARAM_RAMPED : 0) |
      (stepped ? bindings.AUD_PARAM_STEPPED : 0) |
      (logarithmic ? bindings.AUD_PARAM_LOGARITHMIC : 0) |
      (boolean ? bindings.AUD_PARAM_BOOLEAN : 0) |
      (hidden ? bindings.AUD_PARAM_HIDDEN : 0);

  // ...........................................................................
  /// Whether [value] lies between [min] and [max].
  bool contains(double value) => value >= min && value <= max;

  /// [value] clamped to [min] and [max].
  double clamp(double value) => value.clamp(min, max).toDouble();

  /// The parameter as JSON.
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'unit': unit,
    'min': min,
    'max': max,
    'default': defaultValue,
    'automatable': automatable,
    'ramped': ramped,
    'stepped': stepped,
    'logarithmic': logarithmic,
    'boolean': boolean,
    'hidden': hidden,
    'steps': steps,
  };

  @override
  bool operator ==(Object other) =>
      other is AudParamDescriptor &&
      other.id == id &&
      other.name == name &&
      other.unit == unit &&
      other.min == min &&
      other.max == max &&
      other.defaultValue == defaultValue &&
      other.flags == flags &&
      other.steps == steps;

  @override
  int get hashCode =>
      Object.hash(id, name, unit, min, max, defaultValue, flags, steps);

  @override
  String toString() => 'AudParamDescriptor(${toJson()})';
}

// #############################################################################
/// A key of a string setting: `AudStringKeyDescriptor` of the ABI.
class AudStringKeyDescriptor {
  /// Creates a string key.
  const AudStringKeyDescriptor({
    required this.key,
    required this.id,
    this.name = '',
  });

  /// The key from its native struct.
  factory AudStringKeyDescriptor.fromNative(
    bindings.AudStringKeyDescriptor native,
  ) => AudStringKeyDescriptor(
    key: native.key,
    id: _text(native.id),
    name: _text(native.name),
  );

  /// The key from [toJson].
  factory AudStringKeyDescriptor.fromJson(Map<String, Object?> json) =>
      AudStringKeyDescriptor(
        key: (json['key']! as num).toInt(),
        id: json['id']! as String,
        name: json['name'] as String? ?? '',
      );

  // ...........................................................................
  /// The key passed to `set_string`.
  final int key;

  /// The stable identifier, e.g. `sfz_file`.
  final String id;

  /// The display name.
  final String name;

  /// The key as JSON.
  Map<String, Object?> toJson() => {'key': key, 'id': id, 'name': name};

  @override
  bool operator ==(Object other) =>
      other is AudStringKeyDescriptor &&
      other.key == key &&
      other.id == id &&
      other.name == name;

  @override
  int get hashCode => Object.hash(key, id, name);

  @override
  String toString() => 'AudStringKeyDescriptor(${toJson()})';
}

// #############################################################################
/// The capabilities a node type declares: the `AUD_NODE_CAP_*` flags.
class AudNodeCapabilities {
  /// Creates the capabilities.
  const AudNodeCapabilities({
    this.inPlace = false,
    this.variableBlock = false,
    this.events = false,
    this.strings = false,
    this.state = false,
    this.latency = false,
    this.tail = false,
    this.transport = false,
    this.eventOutput = false,
    this.resetOnStop = false,
    this.resetOnSeek = false,
  });

  /// The capabilities from the [flags].
  factory AudNodeCapabilities.fromFlags(int flags) => AudNodeCapabilities(
    inPlace: flags & bindings.AUD_NODE_CAP_IN_PLACE != 0,
    variableBlock: flags & bindings.AUD_NODE_CAP_VARIABLE_BLOCK != 0,
    events: flags & bindings.AUD_NODE_CAP_EVENTS != 0,
    strings: flags & bindings.AUD_NODE_CAP_STRINGS != 0,
    state: flags & bindings.AUD_NODE_CAP_STATE != 0,
    latency: flags & bindings.AUD_NODE_CAP_LATENCY != 0,
    tail: flags & bindings.AUD_NODE_CAP_TAIL != 0,
    transport: flags & bindings.AUD_NODE_CAP_TRANSPORT != 0,
    eventOutput: flags & bindings.AUD_NODE_CAP_EVENT_OUTPUT != 0,
    resetOnStop: flags & bindings.AUD_NODE_CAP_RESET_ON_STOP != 0,
    resetOnSeek: flags & bindings.AUD_NODE_CAP_RESET_ON_SEEK != 0,
  );

  /// The capabilities from [toJson], a list of names.
  factory AudNodeCapabilities.fromJson(List<Object?> json) {
    final names = json.cast<String>().toSet();
    return AudNodeCapabilities(
      inPlace: names.contains('inPlace'),
      variableBlock: names.contains('variableBlock'),
      events: names.contains('events'),
      strings: names.contains('strings'),
      state: names.contains('state'),
      latency: names.contains('latency'),
      tail: names.contains('tail'),
      transport: names.contains('transport'),
      eventOutput: names.contains('eventOutput'),
      resetOnStop: names.contains('resetOnStop'),
      resetOnSeek: names.contains('resetOnSeek'),
    );
  }

  // ...........................................................................
  /// The node renders its main input bus in place.
  final bool inPlace;

  /// The node accepts any frame count up to the prepared maximum.
  final bool variableBlock;

  /// The node consumes events.
  final bool events;

  /// The node accepts string settings.
  final bool strings;

  /// The node saves and loads its state.
  final bool state;

  /// The node reports a latency.
  final bool latency;

  /// The node reports a tail.
  final bool tail;

  /// The node reads the transport snapshot.
  final bool transport;

  /// The node emits events.
  final bool eventOutput;

  /// The engine resets the node when the transport stops.
  final bool resetOnStop;

  /// The engine resets the node when the transport seeks.
  final bool resetOnSeek;

  /// The `AUD_NODE_CAP_*` flags.
  int get flags =>
      (inPlace ? bindings.AUD_NODE_CAP_IN_PLACE : 0) |
      (variableBlock ? bindings.AUD_NODE_CAP_VARIABLE_BLOCK : 0) |
      (events ? bindings.AUD_NODE_CAP_EVENTS : 0) |
      (strings ? bindings.AUD_NODE_CAP_STRINGS : 0) |
      (state ? bindings.AUD_NODE_CAP_STATE : 0) |
      (latency ? bindings.AUD_NODE_CAP_LATENCY : 0) |
      (tail ? bindings.AUD_NODE_CAP_TAIL : 0) |
      (transport ? bindings.AUD_NODE_CAP_TRANSPORT : 0) |
      (eventOutput ? bindings.AUD_NODE_CAP_EVENT_OUTPUT : 0) |
      (resetOnStop ? bindings.AUD_NODE_CAP_RESET_ON_STOP : 0) |
      (resetOnSeek ? bindings.AUD_NODE_CAP_RESET_ON_SEEK : 0);

  /// The capabilities as JSON: the names of the set ones.
  List<String> toJson() => [
    if (inPlace) 'inPlace',
    if (variableBlock) 'variableBlock',
    if (events) 'events',
    if (strings) 'strings',
    if (state) 'state',
    if (latency) 'latency',
    if (tail) 'tail',
    if (transport) 'transport',
    if (eventOutput) 'eventOutput',
    if (resetOnStop) 'resetOnStop',
    if (resetOnSeek) 'resetOnSeek',
  ];

  @override
  bool operator ==(Object other) =>
      other is AudNodeCapabilities && other.flags == flags;

  @override
  int get hashCode => flags;

  @override
  String toString() => 'AudNodeCapabilities(${toJson()})';
}

// #############################################################################
/// A node type: `AudNodeDescriptor` of the ABI, as the Dart side sees it.
class AudNodeDescriptor {
  /// Creates a descriptor.
  const AudNodeDescriptor({
    required this.typeId,
    this.name = '',
    this.vendor = '',
    this.version = 1,
    this.abiMajor = bindings.AUD_ABI_VERSION_MAJOR,
    this.abiMinor = bindings.AUD_ABI_VERSION_MINOR,
    this.capabilities = const AudNodeCapabilities(),
    this.stateVersion = 0,
    this.inputBuses = const [],
    this.outputBuses = const [],
    this.eventInputs = const [],
    this.eventOutputs = const [],
    this.params = const [],
    this.stringKeys = const [],
  });

  /// The descriptor from its native struct.
  factory AudNodeDescriptor.fromNative(bindings.AudNodeDescriptor native) =>
      AudNodeDescriptor(
        typeId: _text(native.type_id),
        name: _text(native.name),
        vendor: _text(native.vendor),
        version: native.version,
        abiMajor: native.abi_major,
        abiMinor: native.abi_minor,
        capabilities: AudNodeCapabilities.fromFlags(native.capabilities),
        stateVersion: native.state_version,
        inputBuses: [
          for (var i = 0; i < native.num_input_buses; i++)
            AudBusDescriptor.fromNative(native.input_buses[i]),
        ],
        outputBuses: [
          for (var i = 0; i < native.num_output_buses; i++)
            AudBusDescriptor.fromNative(native.output_buses[i]),
        ],
        eventInputs: [
          for (var i = 0; i < native.num_event_inputs; i++)
            AudEventPortDescriptor.fromNative(native.event_inputs[i]),
        ],
        eventOutputs: [
          for (var i = 0; i < native.num_event_outputs; i++)
            AudEventPortDescriptor.fromNative(native.event_outputs[i]),
        ],
        params: [
          for (var i = 0; i < native.num_params; i++)
            AudParamDescriptor.fromNative(native.params[i]),
        ],
        stringKeys: [
          for (var i = 0; i < native.num_string_keys; i++)
            AudStringKeyDescriptor.fromNative(native.string_keys[i]),
        ],
      );

  /// The descriptor from [toJson].
  factory AudNodeDescriptor.fromJson(Map<String, Object?> json) {
    List<T> list<T>(String key, T Function(Map<String, Object?>) from) => [
      for (final item in (json[key] as List?) ?? const [])
        from(item as Map<String, Object?>),
    ];
    return AudNodeDescriptor(
      typeId: json['typeId']! as String,
      name: json['name'] as String? ?? '',
      vendor: json['vendor'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 1,
      abiMajor:
          (json['abiMajor'] as num?)?.toInt() ?? bindings.AUD_ABI_VERSION_MAJOR,
      abiMinor:
          (json['abiMinor'] as num?)?.toInt() ?? bindings.AUD_ABI_VERSION_MINOR,
      capabilities: AudNodeCapabilities.fromJson(
        (json['capabilities'] as List?) ?? const [],
      ),
      stateVersion: (json['stateVersion'] as num?)?.toInt() ?? 0,
      inputBuses: list('inputBuses', AudBusDescriptor.fromJson),
      outputBuses: list('outputBuses', AudBusDescriptor.fromJson),
      eventInputs: list('eventInputs', AudEventPortDescriptor.fromJson),
      eventOutputs: list('eventOutputs', AudEventPortDescriptor.fromJson),
      params: list('params', AudParamDescriptor.fromJson),
      stringKeys: list('stringKeys', AudStringKeyDescriptor.fromJson),
    );
  }

  // ...........................................................................
  /// The type id, e.g. `aud.effects.tremolo`.
  final String typeId;

  /// The display name.
  final String name;

  /// The vendor, e.g. `Audanika`.
  final String vendor;

  /// The version of the node type.
  final int version;

  /// The ABI major the package was built against.
  final int abiMajor;

  /// The ABI minor the package was built against.
  final int abiMinor;

  /// What the node can do.
  final AudNodeCapabilities capabilities;

  /// The version of the state blobs the node writes.
  final int stateVersion;

  /// The audio inputs.
  final List<AudBusDescriptor> inputBuses;

  /// The audio outputs.
  final List<AudBusDescriptor> outputBuses;

  /// The event inputs.
  final List<AudEventPortDescriptor> eventInputs;

  /// The event outputs.
  final List<AudEventPortDescriptor> eventOutputs;

  /// The parameters, in the order of their indices.
  final List<AudParamDescriptor> params;

  /// The string settings.
  final List<AudStringKeyDescriptor> stringKeys;

  // ...........................................................................
  /// The index of the parameter [id], or null.
  int? paramIndex(String id) => _indexOf(params, (p) => p.id == id);

  /// The parameter [id], or null.
  AudParamDescriptor? param(String id) {
    final index = paramIndex(id);
    return index == null ? null : params[index];
  }

  /// The index of the event input [id], or null.
  int? eventInputIndex(String id) =>
      _indexOf(eventInputs, (port) => port.id == id);

  /// The index of the event output [id], or null.
  int? eventOutputIndex(String id) =>
      _indexOf(eventOutputs, (port) => port.id == id);

  /// The string key [id], or null.
  AudStringKeyDescriptor? stringKey(String id) {
    final index = _indexOf(stringKeys, (key) => key.id == id);
    return index == null ? null : stringKeys[index];
  }

  static int? _indexOf<T>(List<T> items, bool Function(T) test) {
    for (var i = 0; i < items.length; i++) {
      if (test(items[i])) return i;
    }
    return null;
  }

  // ...........................................................................
  /// The descriptor as JSON.
  Map<String, Object?> toJson() => {
    'typeId': typeId,
    'name': name,
    'vendor': vendor,
    'version': version,
    'abiMajor': abiMajor,
    'abiMinor': abiMinor,
    'capabilities': capabilities.toJson(),
    'stateVersion': stateVersion,
    'inputBuses': [for (final bus in inputBuses) bus.toJson()],
    'outputBuses': [for (final bus in outputBuses) bus.toJson()],
    'eventInputs': [for (final port in eventInputs) port.toJson()],
    'eventOutputs': [for (final port in eventOutputs) port.toJson()],
    'params': [for (final param in params) param.toJson()],
    'stringKeys': [for (final key in stringKeys) key.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is AudNodeDescriptor &&
      other.typeId == typeId &&
      other.name == name &&
      other.vendor == vendor &&
      other.version == version &&
      other.abiMajor == abiMajor &&
      other.abiMinor == abiMinor &&
      other.capabilities == capabilities &&
      other.stateVersion == stateVersion &&
      _listEquals(other.inputBuses, inputBuses) &&
      _listEquals(other.outputBuses, outputBuses) &&
      _listEquals(other.eventInputs, eventInputs) &&
      _listEquals(other.eventOutputs, eventOutputs) &&
      _listEquals(other.params, params) &&
      _listEquals(other.stringKeys, stringKeys);

  @override
  int get hashCode => Object.hash(
    typeId,
    name,
    vendor,
    version,
    abiMajor,
    abiMinor,
    capabilities,
    stateVersion,
    Object.hashAll(inputBuses),
    Object.hashAll(outputBuses),
    Object.hashAll(eventInputs),
    Object.hashAll(eventOutputs),
    Object.hashAll(params),
    Object.hashAll(stringKeys),
  );

  @override
  String toString() => 'AudNodeDescriptor($typeId)';
}
