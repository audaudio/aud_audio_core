// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:typed_data';

import 'aud_event.dart';
import 'aud_osc_address.dart';

// #############################################################################
/// An OSC timetag: NTP seconds since 1900 and a 32-bit fraction; the
/// special value 1 means immediately.
class AudOscTimetag {
  /// Creates a timetag.
  const AudOscTimetag({required this.seconds, required this.fraction});

  /// The timetag of [time].
  factory AudOscTimetag.fromDateTime(DateTime time) =>
      AudOscTimetag.fromUnixNanoseconds(time.microsecondsSinceEpoch * 1000);

  /// The timetag of a Unix time in [nanoseconds].
  factory AudOscTimetag.fromUnixNanoseconds(int nanoseconds) {
    final seconds = nanoseconds ~/ 1000000000;
    final rest = nanoseconds - seconds * 1000000000;
    return AudOscTimetag(
      seconds: seconds + ntpEpochOffset,
      fraction: (rest * 4294967296 / 1000000000).round() & 0xFFFFFFFF,
    );
  }

  /// A timetag from [toJson].
  factory AudOscTimetag.fromJson(Map<String, Object?> json) => AudOscTimetag(
    seconds: (json['seconds']! as num).toInt(),
    fraction: (json['fraction']! as num).toInt(),
  );

  // ...........................................................................
  /// Immediately: the timetag 1.
  static const AudOscTimetag immediate = AudOscTimetag(seconds: 0, fraction: 1);

  /// The seconds between the NTP epoch (1900) and the Unix epoch (1970).
  static const int ntpEpochOffset = 2208988800;

  /// The seconds since 1900.
  final int seconds;

  /// The fraction of a second in units of 2^-32.
  final int fraction;

  /// Whether the timetag means immediately.
  bool get isImmediate => seconds == 0 && fraction == 1;

  /// The Unix time in nanoseconds.
  int get unixNanoseconds =>
      (seconds - ntpEpochOffset) * 1000000000 +
      (fraction * 1000000000 / 4294967296).round();

  /// The timetag as a UTC time.
  DateTime toDateTime() =>
      DateTime.fromMicrosecondsSinceEpoch(unixNanoseconds ~/ 1000, isUtc: true);

  /// The timetag as JSON.
  Map<String, Object?> toJson() => {'seconds': seconds, 'fraction': fraction};

  @override
  bool operator ==(Object other) =>
      other is AudOscTimetag &&
      other.seconds == seconds &&
      other.fraction == fraction;

  @override
  int get hashCode => Object.hash(seconds, fraction);

  @override
  String toString() => isImmediate
      ? 'AudOscTimetag.immediate'
      : 'AudOscTimetag($seconds, $fraction)';
}

// #############################################################################
/// The OSC 1.1 type tags of the arguments the engine speaks: `i` int, `f`
/// float, `s` string, `b` blob, `T` true, `F` false, `N` nil, `I` impulse
/// and `t` timetag.
abstract final class AudOscTypeTags {
  /// The type tag of [argument].
  static String of(Object? argument) => switch (argument) {
    int() => 'i',
    double() => 'f',
    String() => 's',
    Uint8List() => 'b',
    true => 'T',
    false => 'F',
    null => 'N',
    AudImpulse() => 'I',
    AudOscTimetag() => 't',
    _ => throw ArgumentError.value(argument, 'argument', 'Not an OSC type'),
  };

  /// The type tag string of [arguments], e.g. `,if`.
  static String ofArguments(List<Object?> arguments) =>
      ',${arguments.map(of).join()}';

  /// The JSON form of [argument]: a tagged object for the types JSON has no
  /// form for.
  static Object? toJson(Object? argument) => switch (argument) {
    int() => {'i': argument},
    double() => {'f': argument},
    String() => {'s': argument},
    Uint8List() => {'b': base64Encode(argument)},
    AudImpulse() => {'I': true},
    AudOscTimetag() => {'t': argument.toJson()},
    _ => argument,
  };

  /// The argument of its JSON form of [toJson].
  static Object? fromJson(Object? json) => switch (json) {
    {'i': final num value} => value.toInt(),
    {'f': final num value} => value.toDouble(),
    {'s': final String value} => value,
    {'b': final String value} => base64Decode(value),
    {'I': true} => AudImpulse.instance,
    {'t': final Map<String, Object?> value} => AudOscTimetag.fromJson(value),
    bool() => json,
    null => null,
    _ => throw FormatException('Not an OSC argument', json),
  };
}

// #############################################################################
/// An OSC message: an address pattern and typed arguments.
class AudOscMessage {
  /// Creates a message to [address] with [arguments]; every argument must
  /// have a type tag of [AudOscTypeTags].
  AudOscMessage(this.address, [this.arguments = const []]) {
    if (address.length < 2 || !address.startsWith('/')) {
      throw FormatException('Not an OSC address', address);
    }
    for (final argument in arguments) {
      AudOscTypeTags.of(argument);
    }
  }

  /// A message from [toJson].
  factory AudOscMessage.fromJson(Map<String, Object?> json) =>
      AudOscMessage(json['address']! as String, [
        for (final argument in (json['arguments'] as List?) ?? const [])
          AudOscTypeTags.fromJson(argument),
      ]);

  // ...........................................................................
  /// The address, which may be a pattern.
  final String address;

  /// The arguments.
  final List<Object?> arguments;

  /// The type tag string, e.g. `,if`.
  String get typeTags => AudOscTypeTags.ofArguments(arguments);

  /// Whether the address contains pattern characters.
  bool get hasPattern => AudOscPattern.isPattern(address);

  /// The message as JSON.
  Map<String, Object?> toJson() => {
    'address': address,
    'arguments': [
      for (final argument in arguments) AudOscTypeTags.toJson(argument),
    ],
  };

  @override
  bool operator ==(Object other) =>
      other is AudOscMessage &&
      jsonEncode(other.toJson()) == jsonEncode(toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;

  @override
  String toString() => 'AudOscMessage($address $typeTags $arguments)';
}

// #############################################################################
/// An OSC bundle: a timetag and messages or bundles that take effect at it.
class AudOscBundle {
  /// Creates a bundle of [elements] at [timetag]; elements are messages or
  /// bundles.
  AudOscBundle({
    this.timetag = AudOscTimetag.immediate,
    this.elements = const [],
  }) {
    for (final element in elements) {
      if (element is! AudOscMessage && element is! AudOscBundle) {
        throw ArgumentError.value(element, 'elements', 'Not a message');
      }
    }
  }

  /// A bundle from [toJson].
  factory AudOscBundle.fromJson(Map<String, Object?> json) => AudOscBundle(
    timetag: json.containsKey('timetag')
        ? AudOscTimetag.fromJson(json['timetag']! as Map<String, Object?>)
        : AudOscTimetag.immediate,
    elements: [
      for (final element in (json['elements'] as List?) ?? const [])
        if ((element as Map<String, Object?>).containsKey('elements'))
          AudOscBundle.fromJson(element)
        else
          AudOscMessage.fromJson(element),
    ],
  );

  // ...........................................................................
  /// When the elements take effect.
  final AudOscTimetag timetag;

  /// The messages and bundles.
  final List<Object> elements;

  /// The bundle as JSON.
  Map<String, Object?> toJson() => {
    'timetag': timetag.toJson(),
    'elements': [
      for (final element in elements)
        if (element is AudOscMessage)
          element.toJson()
        else
          (element as AudOscBundle).toJson(),
    ],
  };

  @override
  bool operator ==(Object other) =>
      other is AudOscBundle &&
      jsonEncode(other.toJson()) == jsonEncode(toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;

  @override
  String toString() => 'AudOscBundle($timetag, ${elements.length} elements)';
}
