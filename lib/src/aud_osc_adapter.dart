// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_midi_standard/aud_midi_standard.dart';

import 'aud_audio_core_bindings_generated.dart' as bindings;
import 'aud_command.dart';
import 'aud_event.dart';
import 'aud_node_descriptor.dart';
import 'aud_osc_address.dart';
import 'aud_osc_message.dart';
import 'aud_time.dart';
import 'aud_transport.dart';

// #############################################################################
/// What an OSC address names inside the engine.
sealed class AudOscTarget {
  const AudOscTarget(this.address);

  /// The address of the target.
  final AudOscAddress address;

  @override
  String toString() => '$runtimeType($address)';
}

/// A graph.
final class AudGraphTarget extends AudOscTarget {
  /// Creates the target.
  const AudGraphTarget(super.address, {required this.graph});

  /// The graph id.
  final int graph;
}

/// The transport of a graph.
final class AudTransportTarget extends AudOscTarget {
  /// Creates the target.
  const AudTransportTarget(super.address, {required this.graph});

  /// The graph id.
  final int graph;
}

/// A node.
final class AudNodeTarget extends AudOscTarget {
  /// Creates the target.
  const AudNodeTarget(
    super.address, {
    required this.graph,
    required this.node,
    required this.handle,
    required this.descriptor,
  });

  /// The graph id.
  final int graph;

  /// The node id.
  final int node;

  /// The engine handle.
  final int handle;

  /// The node type.
  final AudNodeDescriptor descriptor;
}

/// A parameter of a node.
final class AudParamTarget extends AudOscTarget {
  /// Creates the target.
  const AudParamTarget(
    super.address, {
    required this.handle,
    required this.index,
    required this.param,
  });

  /// The engine handle of the node.
  final int handle;

  /// The parameter index.
  final int index;

  /// The parameter.
  final AudParamDescriptor param;
}

/// An event input of a node.
final class AudInletTarget extends AudOscTarget {
  /// Creates the target.
  const AudInletTarget(
    super.address, {
    required this.handle,
    required this.port,
    required this.descriptor,
  });

  /// The engine handle of the node.
  final int handle;

  /// The port index.
  final int port;

  /// The port.
  final AudEventPortDescriptor descriptor;
}

/// An event output of a node.
final class AudOutletTarget extends AudOscTarget {
  /// Creates the target.
  const AudOutletTarget(
    super.address, {
    required this.handle,
    required this.port,
  });

  /// The engine handle of the node.
  final int handle;

  /// The port index.
  final int port;
}

/// A string setting of a node.
final class AudStringTarget extends AudOscTarget {
  /// Creates the target.
  const AudStringTarget(
    super.address, {
    required this.handle,
    required this.key,
  });

  /// The engine handle of the node.
  final int handle;

  /// The string key.
  final int key;
}

// #############################################################################
/// Resolves OSC addresses and patterns to engine targets. Runs on the
/// Dart side, never on the audio thread (decision osc-001).
class AudOscRouter {
  /// Creates an empty router.
  AudOscRouter();

  final Map<String, AudOscTarget> _targets = {};

  /// The registered addresses, in registration order.
  Iterable<AudOscAddress> get addresses =>
      _targets.values.map((target) => target.address);

  // ...........................................................................
  /// Registers a graph and its transport.
  void registerGraph(int graph) {
    final address = AudOscAddress.graph(graph);
    _targets.putIfAbsent(
      address.value,
      () => AudGraphTarget(address, graph: graph),
    );
    final transport = AudOscAddress.transport(graph);
    _targets.putIfAbsent(
      transport.value,
      () => AudTransportTarget(transport, graph: graph),
    );
  }

  /// Removes a graph with everything below it.
  void unregisterGraph(int graph) => _removeBelow(AudOscAddress.graph(graph));

  /// Registers a node with its parameters, event ports and string keys;
  /// registers its graph when needed.
  void registerNode({
    required int graph,
    required int node,
    required int handle,
    required AudNodeDescriptor descriptor,
  }) {
    registerGraph(graph);
    final address = AudOscAddress.node(graphId: graph, nodeId: node);
    _removeBelow(address);
    _targets[address.value] = AudNodeTarget(
      address,
      graph: graph,
      node: node,
      handle: handle,
      descriptor: descriptor,
    );
    for (var i = 0; i < descriptor.params.length; i++) {
      final param = descriptor.params[i];
      final a = AudOscAddress.param(
        graphId: graph,
        nodeId: node,
        param: param.id,
      );
      _targets[a.value] = AudParamTarget(
        a,
        handle: handle,
        index: i,
        param: param,
      );
    }
    for (var i = 0; i < descriptor.eventInputs.length; i++) {
      final port = descriptor.eventInputs[i];
      final a = AudOscAddress.inlet(
        graphId: graph,
        nodeId: node,
        inlet: port.id,
      );
      _targets[a.value] = AudInletTarget(
        a,
        handle: handle,
        port: i,
        descriptor: port,
      );
    }
    for (var i = 0; i < descriptor.eventOutputs.length; i++) {
      final port = descriptor.eventOutputs[i];
      final a = AudOscAddress.outlet(
        graphId: graph,
        nodeId: node,
        outlet: port.id,
      );
      _targets[a.value] = AudOutletTarget(a, handle: handle, port: i);
    }
    for (final key in descriptor.stringKeys) {
      final a = AudOscAddress.string(graphId: graph, nodeId: node, key: key.id);
      _targets[a.value] = AudStringTarget(a, handle: handle, key: key.key);
    }
  }

  /// Removes a node with everything below it.
  void unregisterNode({required int graph, required int node}) =>
      _removeBelow(AudOscAddress.node(graphId: graph, nodeId: node));

  void _removeBelow(AudOscAddress root) =>
      _targets.removeWhere((_, target) => target.address.isWithin(root));

  // ...........................................................................
  /// The target at exactly [address], or null.
  AudOscTarget? lookup(String address) => _targets[address];

  /// The targets an address or pattern names, in registration order.
  List<AudOscTarget> resolve(String addressOrPattern) {
    if (!AudOscPattern.isPattern(addressOrPattern)) {
      final target = lookup(addressOrPattern);
      return target == null ? const [] : [target];
    }
    final pattern = AudOscPattern(addressOrPattern);
    return [
      for (final target in _targets.values)
        if (pattern.matches(target.address)) target,
    ];
  }
}

// #############################################################################
/// A message the adapter cannot convert; it becomes an [AudFail].
class AudOscException implements Exception {
  /// Creates the exception for the message to [address].
  const AudOscException(this.address, this.code, this.message);

  /// The address of the message.
  final String address;

  /// The result code of the ABI.
  final int code;

  /// What went wrong.
  final String message;

  /// The failure reply.
  AudFail toFail() => AudFail(address, code, message);

  @override
  String toString() => 'AudOscException($address, $code): $message';
}

// #############################################################################
/// Converts OSC messages and bundles into typed commands (decision
/// osc-001): addresses resolve through an [AudOscRouter], timetags convert
/// into host time through the offset between the wall clock and the host
/// clock measured at creation.
///
/// The grammar:
///
/// - `<param> f value [i rampFrames]` sets a parameter, clamped to its range
/// - `<inlet> i word0 [i word1 i word2 i word3]` sends a UMP packet
/// - `<inlet>/note i note f velocity [i channel]` sends a MIDI 1.0 note on
///   (velocity 0 a note off)
/// - `<inlet>/noteoff i note [f velocity] [i channel]` sends a note off
/// - `<inlet>/control i control <argument>` sends a control event
/// - `<node>/cancel [i id]` cancels pending events
/// - `<string> s value` applies a string setting
/// - `<transport>/start`, `/stop`, `/seek f beat`, `/tempo f bpm`,
///   `/loop f start f end`, `/quantum f beats`, `/timesig i num i den`
///
/// A message with a pattern reaches every matching target. A message in a
/// bundle with a timetag is scheduled at that time and gets an id.
class AudOscAdapter {
  /// Creates an adapter over [router]; [hostTimeNs] and [now] default to
  /// the host clock and the wall clock.
  AudOscAdapter({
    required this.router,
    int Function()? hostTimeNs,
    DateTime Function()? now,
  }) : _hostTimeNs = hostTimeNs ?? AudClock.nowNs,
       _now = now ?? DateTime.now {
    calibrate();
  }

  /// The router resolving addresses.
  final AudOscRouter router;

  final int Function() _hostTimeNs;
  final DateTime Function() _now;
  int _offsetNs = 0;
  int _nextId = 1;

  /// The host time minus the Unix time, in nanoseconds.
  int get offsetNs => _offsetNs;

  // ...........................................................................
  /// Measures the offset between the wall clock and the host clock again.
  void calibrate() {
    _offsetNs = _hostTimeNs() - _now().microsecondsSinceEpoch * 1000;
  }

  /// The timestamp of [timetag]: immediate, or a host time synthesized
  /// from the wall clock.
  AudTimestamp timestampOf(AudOscTimetag timetag) => timetag.isImmediate
      ? const AudTimestamp.immediate()
      : AudTimestamp.host(
          timetag.unixNanoseconds + _offsetNs,
          source: AudTimeSource.synthesized,
        );

  // ...........................................................................
  /// Converts a bundle, its timetag applying to every element.
  List<AudCommand> convertBundle(AudOscBundle bundle) => [
    for (final element in bundle.elements)
      if (element is AudOscBundle)
        ...convertBundle(element)
      else
        ...convert(element as AudOscMessage, timetag: bundle.timetag),
  ];

  /// Converts a message at [timetag] into commands; throws an
  /// [AudOscException] when the address or the arguments do not fit.
  List<AudCommand> convert(
    AudOscMessage message, {
    AudOscTimetag timetag = AudOscTimetag.immediate,
  }) {
    final at = timestampOf(timetag);
    var targets = router.resolve(message.address);
    String? verb;
    if (targets.isEmpty) {
      final slash = message.address.lastIndexOf('/');
      if (slash > 0) {
        verb = message.address.substring(slash + 1);
        targets = router.resolve(message.address.substring(0, slash));
      }
    }
    if (targets.isEmpty) {
      throw AudOscException(
        message.address,
        bindings.AUD_ERROR_NOT_FOUND,
        'No target at ${message.address}',
      );
    }
    return [
      for (final target in targets) ..._convertFor(target, verb, message, at),
    ];
  }

  List<AudCommand> _convertFor(
    AudOscTarget target,
    String? verb,
    AudOscMessage message,
    AudTimestamp at,
  ) {
    final args = _Args(message);
    return switch ((target, verb)) {
      (AudParamTarget t, null) => [
        AudSetParamCommand(
          node: t.handle,
          paramIndex: t.index,
          value: t.param.clamp(args.number(0)),
          rampFrames: args.optionalInt(1) ?? 0,
          at: at,
        ),
      ],
      (AudInletTarget t, null) => [_eventCommand(t, _umpOfWords(args), at)],
      (AudInletTarget t, 'note') => [
        _eventCommand(t, _noteEvent(args, on: true), at),
      ],
      (AudInletTarget t, 'noteoff') => [
        _eventCommand(t, _noteEvent(args, on: false), at),
      ],
      (AudInletTarget t, 'control') => [
        _eventCommand(
          t,
          AudControlEvent(
            control: args.integer(0),
            value: args.controlValue(1),
            port: t.port,
          ),
          at,
        ),
      ],
      (AudNodeTarget t, 'cancel') => [
        AudCancelCommand(node: t.handle, id: args.optionalInt(0)),
      ],
      (AudStringTarget t, null) => [
        AudSetStringCommand(node: t.handle, key: t.key, value: args.string(0)),
      ],
      (AudTransportTarget t, final String v) => [
        AudTransportCommand(graph: t.graph, request: _request(v, args, at)),
      ],
      _ => throw AudOscException(
        message.address,
        bindings.AUD_ERROR_NOT_FOUND,
        'Nothing to do at ${message.address}',
      ),
    };
  }

  AudEventCommand _eventCommand(
    AudInletTarget target,
    AudEvent event,
    AudTimestamp at,
  ) => AudEventCommand(
    node: target.handle,
    event: event,
    at: at,
    id: at.isImmediate ? 0 : _nextId++,
  );

  static AudUmpEvent _umpOfWords(_Args args) {
    final words = [
      for (var i = 0; i < args.length; i++) args.integer(i) & 0xFFFFFFFF,
    ];
    if (words.isEmpty || words.length > 4) {
      throw args.error('one to four UMP words');
    }
    return AudUmpEvent(Ump(words), port: args.port);
  }

  static AudUmpEvent _noteEvent(_Args args, {required bool on}) {
    final note = args.integer(0);
    final velocity = on ? args.number(1) : (args.optionalNumber(1) ?? 0);
    final channel = args.optionalInt(2) ?? 0;
    if (note < 0 || note > 127 || velocity < 0 || velocity > 1) {
      throw args.error('a note 0..127 and a velocity 0..1');
    }
    final MidiMessage message = on && velocity > 0
        ? MidiNoteOn(
            channel: channel,
            note: note,
            velocity: (velocity * 127).round(),
          )
        : MidiNoteOff(
            channel: channel,
            note: note,
            velocity: (velocity * 127).round(),
          );
    return AudUmpEvent.fromMessage(message, port: args.port).single;
  }

  static AudTransportRequest _request(
    String verb,
    _Args args,
    AudTimestamp at,
  ) => switch (verb) {
    'start' => AudTransportRequest.start(at: at),
    'stop' => AudTransportRequest.stop(at: at),
    'seek' => AudTransportRequest.seek(args.number(0), at: at),
    'tempo' => AudTransportRequest.setTempo(args.number(0), at: at),
    'loop' => AudTransportRequest.setLoop(
      start: args.number(0),
      end: args.number(1),
      at: at,
    ),
    'quantum' => AudTransportRequest.setQuantum(args.number(0)),
    'timesig' => AudTransportRequest.setTimeSignature(
      numerator: args.integer(0),
      denominator: args.integer(1),
      at: at,
    ),
    _ => throw args.error('a transport request, not $verb'),
  };
}

// The typed reading of the arguments of a message.
class _Args {
  _Args(this.message);

  final AudOscMessage message;
  int port = 0;

  int get length => message.arguments.length;

  AudOscException error(String expected) => AudOscException(
    message.address,
    bindings.AUD_ERROR_INVALID_ARGUMENT,
    'Expected $expected, got ${message.typeTags}',
  );

  int integer(int index) =>
      optionalInt(index) ?? (throw error('an int at $index'));

  int? optionalInt(int index) {
    if (index >= length) return null;
    final value = message.arguments[index];
    return value is int ? value : throw error('an int at $index');
  }

  double number(int index) =>
      optionalNumber(index) ?? (throw error('a number at $index'));

  double? optionalNumber(int index) {
    if (index >= length) return null;
    final value = message.arguments[index];
    return value is num ? value.toDouble() : throw error('a number at $index');
  }

  String string(int index) {
    if (index >= length) throw error('a string at $index');
    final value = message.arguments[index];
    return value is String ? value : throw error('a string at $index');
  }

  Object? controlValue(int index) {
    if (index >= length) return AudImpulse.instance;
    final value = message.arguments[index];
    if (value is int || value is double || value is bool || value == null) {
      return value;
    }
    if (value is AudImpulse) return value;
    throw error('a number, a bool, nil or an impulse at $index');
  }
}
