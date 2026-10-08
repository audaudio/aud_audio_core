// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'aud_event.dart';
import 'aud_osc_message.dart';
import 'aud_time.dart';
import 'aud_transport.dart';

// #############################################################################
/// A typed engine command (decision osc-001): numeric handles, parameter
/// indices, event structs and timestamps tagged with their domain. The OSC
/// adapter resolves addresses to these before a command enters a queue.
sealed class AudCommand {
  const AudCommand();

  /// A command from [toJson].
  factory AudCommand.fromJson(Map<String, Object?> json) {
    final at = json.containsKey('at')
        ? AudTimestamp.fromJson(json['at']! as Map<String, Object?>)
        : const AudTimestamp.immediate();
    return switch (json['command']) {
      'setParam' => AudSetParamCommand(
        node: (json['node']! as num).toInt(),
        paramIndex: (json['paramIndex']! as num).toInt(),
        value: (json['value']! as num).toDouble(),
        rampFrames: (json['rampFrames'] as num?)?.toInt() ?? 0,
        at: at,
      ),
      'event' => AudEventCommand(
        node: (json['node']! as num).toInt(),
        event: AudEvent.fromJson(json['event']! as Map<String, Object?>),
        at: at,
        id: (json['id'] as num?)?.toInt() ?? 0,
      ),
      'cancel' => AudCancelCommand(
        node: (json['node'] as num?)?.toInt(),
        id: (json['id'] as num?)?.toInt(),
      ),
      'setString' => AudSetStringCommand(
        node: (json['node']! as num).toInt(),
        key: (json['key']! as num).toInt(),
        value: json['value']! as String,
      ),
      'transport' => AudTransportCommand(
        graph: (json['graph']! as num).toInt(),
        request: AudTransportRequest.fromJson(
          json['request']! as Map<String, Object?>,
        ),
      ),
      _ => throw FormatException('Unknown command', json),
    };
  }

  /// The command as JSON.
  Map<String, Object?> toJson();

  @override
  String toString() => '$runtimeType(${toJson()})';
}

// #############################################################################
/// Sets a parameter of a node, at once or over a ramp.
final class AudSetParamCommand extends AudCommand {
  /// Creates the command.
  const AudSetParamCommand({
    required this.node,
    required this.paramIndex,
    required this.value,
    this.rampFrames = 0,
    this.at = const AudTimestamp.immediate(),
  });

  /// The node handle.
  final int node;

  /// The parameter index in the descriptor.
  final int paramIndex;

  /// The target value.
  final double value;

  /// The ramp length in frames.
  final int rampFrames;

  /// When the change starts.
  final AudTimestamp at;

  @override
  Map<String, Object?> toJson() => {
    'command': 'setParam',
    'node': node,
    'paramIndex': paramIndex,
    'value': value,
    'rampFrames': rampFrames,
    'at': at.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is AudSetParamCommand &&
      other.node == node &&
      other.paramIndex == paramIndex &&
      other.value == value &&
      other.rampFrames == rampFrames &&
      other.at == at;

  @override
  int get hashCode => Object.hash(node, paramIndex, value, rampFrames, at);
}

// #############################################################################
/// Delivers an event to a node at a time; an [id] above zero lets the event
/// be cancelled while it waits.
final class AudEventCommand extends AudCommand {
  /// Creates the command.
  const AudEventCommand({
    required this.node,
    required this.event,
    this.at = const AudTimestamp.immediate(),
    this.id = 0,
  });

  /// The node handle.
  final int node;

  /// The event; its port names the event input.
  final AudEvent event;

  /// When the event fires.
  final AudTimestamp at;

  /// The id of a scheduled event, 0 for none.
  final int id;

  @override
  Map<String, Object?> toJson() => {
    'command': 'event',
    'node': node,
    'event': event.toJson(),
    'at': at.toJson(),
    'id': id,
  };

  @override
  bool operator ==(Object other) =>
      other is AudEventCommand &&
      other.node == node &&
      other.event == event &&
      other.at == at &&
      other.id == id;

  @override
  int get hashCode => Object.hash(node, event, at, id);
}

// #############################################################################
/// Cancels the scheduled event [id], or every pending event of [node].
final class AudCancelCommand extends AudCommand {
  /// Creates the command; one of [node] and [id] is set.
  const AudCancelCommand({this.node, this.id})
    : assert(node != null || id != null, 'node or id');

  /// The node whose pending events are cancelled.
  final int? node;

  /// The id of the event to cancel.
  final int? id;

  @override
  Map<String, Object?> toJson() => {
    'command': 'cancel',
    if (node != null) 'node': node,
    if (id != null) 'id': id,
  };

  @override
  bool operator ==(Object other) =>
      other is AudCancelCommand && other.node == node && other.id == id;

  @override
  int get hashCode => Object.hash(node, id);
}

// #############################################################################
/// Applies a string setting to a node on the control thread.
final class AudSetStringCommand extends AudCommand {
  /// Creates the command.
  const AudSetStringCommand({
    required this.node,
    required this.key,
    required this.value,
  });

  /// The node handle.
  final int node;

  /// The string key of the descriptor.
  final int key;

  /// The value.
  final String value;

  @override
  Map<String, Object?> toJson() => {
    'command': 'setString',
    'node': node,
    'key': key,
    'value': value,
  };

  @override
  bool operator ==(Object other) =>
      other is AudSetStringCommand &&
      other.node == node &&
      other.key == key &&
      other.value == value;

  @override
  int get hashCode => Object.hash(node, key, value);
}

// #############################################################################
/// Sends a request to the transport of a graph.
final class AudTransportCommand extends AudCommand {
  /// Creates the command.
  const AudTransportCommand({required this.graph, required this.request});

  /// The graph id.
  final int graph;

  /// The request.
  final AudTransportRequest request;

  @override
  Map<String, Object?> toJson() => {
    'command': 'transport',
    'graph': graph,
    'request': request.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is AudTransportCommand &&
      other.graph == graph &&
      other.request == request;

  @override
  int get hashCode => Object.hash(graph, request);
}

// #############################################################################
/// The reply and notification vocabulary of the engine, in the
/// SuperCollider manner.
abstract final class AudOscVocabulary {
  /// A command succeeded: `/done <address> ...`.
  static const String done = '/done';

  /// A command failed: `/fail <address> <code> <message>`.
  static const String fail = '/fail';

  /// A node was created: `/notify/node/created <graph> <node> <type>`.
  static const String nodeCreated = '/notify/node/created';

  /// A node was retired: `/notify/node/retired <graph> <node>`.
  static const String nodeRetired = '/notify/node/retired';

  /// A revision runs: `/notify/graph/revision <graph> <revision>`.
  static const String revisionAdopted = '/notify/graph/revision';

  /// A meter reading: `/notify/meter <address> <peak> <rms>`.
  static const String meter = '/notify/meter';

  /// A diagnostic: `/notify/diagnostic <code> <message> [<address>]`.
  static const String diagnostic = '/notify/diagnostic';
}

// #############################################################################
/// A reply of the engine to a command.
sealed class AudReply {
  const AudReply();

  /// The reply as an OSC message.
  AudOscMessage toOsc();

  @override
  String toString() => '$runtimeType(${toOsc()})';
}

// #############################################################################
/// A command succeeded.
final class AudDone extends AudReply {
  /// Creates the reply for the command sent to [address].
  const AudDone(this.address, [this.arguments = const []]);

  /// The address of the command.
  final String address;

  /// Further results.
  final List<Object?> arguments;

  @override
  AudOscMessage toOsc() =>
      AudOscMessage(AudOscVocabulary.done, [address, ...arguments]);

  @override
  bool operator ==(Object other) =>
      other is AudDone && other.toOsc() == toOsc();

  @override
  int get hashCode => toOsc().hashCode;
}

// #############################################################################
/// A command failed.
final class AudFail extends AudReply {
  /// Creates the reply for the command sent to [address].
  const AudFail(this.address, this.code, this.message);

  /// The address of the command.
  final String address;

  /// The result code of the ABI.
  final int code;

  /// What went wrong.
  final String message;

  @override
  AudOscMessage toOsc() =>
      AudOscMessage(AudOscVocabulary.fail, [address, code, message]);

  @override
  bool operator ==(Object other) =>
      other is AudFail && other.toOsc() == toOsc();

  @override
  int get hashCode => toOsc().hashCode;
}

// #############################################################################
/// A notification of the engine.
sealed class AudNotification {
  const AudNotification();

  /// The notification as an OSC message.
  AudOscMessage toOsc();

  @override
  bool operator ==(Object other) =>
      other is AudNotification && other.toOsc() == toOsc();

  @override
  int get hashCode => toOsc().hashCode;

  @override
  String toString() => '$runtimeType(${toOsc()})';
}

// #############################################################################
/// A node was created.
final class AudNodeCreated extends AudNotification {
  /// Creates the notification.
  const AudNodeCreated({
    required this.graph,
    required this.node,
    required this.typeId,
  });

  /// The graph id.
  final int graph;

  /// The node id.
  final int node;

  /// The type id of the node.
  final String typeId;

  @override
  AudOscMessage toOsc() =>
      AudOscMessage(AudOscVocabulary.nodeCreated, [graph, node, typeId]);
}

// #############################################################################
/// A node was retired.
final class AudNodeRetired extends AudNotification {
  /// Creates the notification.
  const AudNodeRetired({required this.graph, required this.node});

  /// The graph id.
  final int graph;

  /// The node id.
  final int node;

  @override
  AudOscMessage toOsc() =>
      AudOscMessage(AudOscVocabulary.nodeRetired, [graph, node]);
}

// #############################################################################
/// The audio thread adopted a revision of a graph.
final class AudRevisionAdopted extends AudNotification {
  /// Creates the notification.
  const AudRevisionAdopted({required this.graph, required this.revision});

  /// The graph id.
  final int graph;

  /// The revision.
  final int revision;

  @override
  AudOscMessage toOsc() =>
      AudOscMessage(AudOscVocabulary.revisionAdopted, [graph, revision]);
}

// #############################################################################
/// A meter reading of an addressed point of the graph.
final class AudMeter extends AudNotification {
  /// Creates the notification.
  const AudMeter({
    required this.address,
    required this.peak,
    required this.rms,
  });

  /// The address of the meter.
  final String address;

  /// The peak, 0 to 1.
  final double peak;

  /// The root mean square, 0 to 1.
  final double rms;

  @override
  AudOscMessage toOsc() =>
      AudOscMessage(AudOscVocabulary.meter, [address, peak, rms]);
}

// #############################################################################
/// A diagnostic: a late event, an overflow, an xrun.
final class AudDiagnostic extends AudNotification {
  /// Creates the notification.
  const AudDiagnostic({
    required this.code,
    required this.message,
    this.address,
  });

  /// The result code of the ABI.
  final int code;

  /// What happened.
  final String message;

  /// The address it concerns, if any.
  final String? address;

  @override
  AudOscMessage toOsc() => AudOscMessage(AudOscVocabulary.diagnostic, [
    code,
    message,
    if (address != null) address,
  ]);
}
