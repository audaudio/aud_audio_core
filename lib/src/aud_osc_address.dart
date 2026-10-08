// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// #############################################################################
/// An OSC 1.1 address of the engine (decision osc-001), e.g.
/// `/graph/1/node/2/param/gain`. Addresses are concrete; patterns with
/// wildcards are [AudOscPattern]s.
class AudOscAddress {
  /// Creates an address; throws a [FormatException] for an invalid one.
  factory AudOscAddress(String address) {
    if (!isValid(address)) {
      throw FormatException('Not an OSC address', address);
    }
    return AudOscAddress._(address, address.substring(1).split('/'));
  }

  const AudOscAddress._(this.value, this.segments);

  /// The address of a graph.
  factory AudOscAddress.graph(Object graphId) =>
      AudOscAddress('/graph/$graphId');

  /// The address of the transport of a graph.
  factory AudOscAddress.transport(Object graphId) =>
      AudOscAddress('/graph/$graphId/transport');

  /// The address of a node.
  factory AudOscAddress.node({
    required Object graphId,
    required Object nodeId,
  }) => AudOscAddress('/graph/$graphId/node/$nodeId');

  /// The address of a parameter.
  factory AudOscAddress.param({
    required Object graphId,
    required Object nodeId,
    required String param,
  }) => AudOscAddress('/graph/$graphId/node/$nodeId/param/$param');

  /// The address of an event input.
  factory AudOscAddress.inlet({
    required Object graphId,
    required Object nodeId,
    required String inlet,
  }) => AudOscAddress('/graph/$graphId/node/$nodeId/inlet/$inlet');

  /// The address of an event output.
  factory AudOscAddress.outlet({
    required Object graphId,
    required Object nodeId,
    required String outlet,
  }) => AudOscAddress('/graph/$graphId/node/$nodeId/outlet/$outlet');

  /// The address of a string setting.
  factory AudOscAddress.string({
    required Object graphId,
    required Object nodeId,
    required String key,
  }) => AudOscAddress('/graph/$graphId/node/$nodeId/string/$key');

  // ...........................................................................
  /// The characters a segment may not contain: the OSC pattern characters,
  /// the separator, blanks and the type tag marker.
  static final RegExp segmentPattern = RegExp(r'^[^\s#*,/?\[\]{}]+$');

  /// Whether [address] is a valid, concrete OSC address.
  static bool isValid(String address) {
    if (address.length < 2 || !address.startsWith('/')) return false;
    return address
        .substring(1)
        .split('/')
        .every((segment) => segmentPattern.hasMatch(segment));
  }

  // ...........................................................................
  /// The address, e.g. `/graph/1/node/2/param/gain`.
  final String value;

  /// The segments between the slashes.
  final List<String> segments;

  /// The last segment.
  String get last => segments.last;

  /// The address without its last segment; null for a root address.
  AudOscAddress? get parent => segments.length < 2
      ? null
      : AudOscAddress._(
          '/${segments.sublist(0, segments.length - 1).join('/')}',
          segments.sublist(0, segments.length - 1),
        );

  /// The address with [segment] appended.
  AudOscAddress child(String segment) => AudOscAddress('$value/$segment');

  /// Whether this address is [other] or lies below it.
  bool isWithin(AudOscAddress other) =>
      value == other.value || value.startsWith('${other.value}/');

  @override
  bool operator ==(Object other) =>
      other is AudOscAddress && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

// #############################################################################
/// An OSC 1.1 address pattern: `?` matches one character, `*` any run of
/// characters inside a segment, `[a-z]` and `[!a]` character classes,
/// `{a,b}` alternatives and `//` any number of segments.
class AudOscPattern {
  /// Creates a pattern; throws a [FormatException] for an invalid one.
  factory AudOscPattern(String pattern) {
    if (pattern.length < 2 ||
        !pattern.startsWith('/') ||
        pattern.endsWith('/')) {
      throw FormatException('Not an OSC address pattern', pattern);
    }
    final parts = <RegExp?>[];
    for (final segment in pattern.substring(1).split('/')) {
      if (segment.isEmpty) {
        if (parts.isNotEmpty && parts.last == null) {
          throw FormatException('Not an OSC address pattern', pattern);
        }
        parts.add(null);
      } else {
        parts.add(compileSegment(segment));
      }
    }
    return AudOscPattern._(pattern, parts);
  }

  const AudOscPattern._(this.value, this._parts);

  // ...........................................................................
  /// Whether [address] contains pattern characters or `//`.
  static bool isPattern(String address) =>
      RegExp(r'[*?\[\]{}]').hasMatch(address) || address.contains('//');

  /// The regular expression matching one segment of a pattern.
  static RegExp compileSegment(String segment) {
    final buffer = StringBuffer('^');
    var i = 0;
    while (i < segment.length) {
      final char = segment[i];
      switch (char) {
        case '?':
          buffer.write('[^/]');
        case '*':
          buffer.write('[^/]*');
        case '[':
          final end = segment.indexOf(']', i);
          if (end < 0) throw FormatException('Unclosed [', segment);
          var body = segment.substring(i + 1, end);
          if (body.startsWith('!')) body = '^${body.substring(1)}';
          buffer.write('[${body.replaceAll(r'\', r'\\')}]');
          i = end;
        case '{':
          final end = segment.indexOf('}', i);
          if (end < 0) throw FormatException('Unclosed {', segment);
          final alternatives = segment
              .substring(i + 1, end)
              .split(',')
              .map(RegExp.escape)
              .join('|');
          buffer.write('(?:$alternatives)');
          i = end;
        default:
          buffer.write(RegExp.escape(char));
      }
      i++;
    }
    buffer.write(r'$');
    return RegExp(buffer.toString());
  }

  // ...........................................................................
  /// The pattern, e.g. `/graph/1/node/*/param/gain`.
  final String value;

  /// The compiled segments; null stands for `//`.
  final List<RegExp?> _parts;

  /// Whether the pattern matches [address], an [AudOscAddress] or a string.
  bool matches(Object address) {
    final segments = switch (address) {
      AudOscAddress() => address.segments,
      String() => AudOscAddress(address).segments,
      _ => throw ArgumentError.value(address, 'address', 'Not an address'),
    };
    return _match(0, segments, 0);
  }

  bool _match(int part, List<String> segments, int segment) {
    if (part == _parts.length) return segment == segments.length;
    final expression = _parts[part];
    if (expression == null) {
      for (var skip = segment; skip <= segments.length; skip++) {
        if (_match(part + 1, segments, skip)) return true;
      }
      return false;
    }
    return segment < segments.length &&
        expression.hasMatch(segments[segment]) &&
        _match(part + 1, segments, segment + 1);
  }

  @override
  bool operator ==(Object other) =>
      other is AudOscPattern && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
