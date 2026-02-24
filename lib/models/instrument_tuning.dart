import 'dart:convert';

enum InstrumentType { guitar, bass, sevenString, ukulele, custom }

class InstrumentTuning {
  final String id;
  final String name;
  final InstrumentType type;
  final List<String> openNotes; // high to low (index 0 = thinnest string)
  final int fretCount;

  const InstrumentTuning({
    required this.id,
    required this.name,
    required this.type,
    required this.openNotes,
    this.fretCount = 24,
  });

  int get stringCount => openNotes.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'open_notes': openNotes,
        'fret_count': fretCount,
      };

  factory InstrumentTuning.fromJson(Map<String, dynamic> json) {
    return InstrumentTuning(
      id: json['id'] as String,
      name: json['name'] as String,
      type: InstrumentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => InstrumentType.custom,
      ),
      openNotes: (json['open_notes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      fretCount: json['fret_count'] as int? ?? 24,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory InstrumentTuning.fromJsonString(String jsonString) {
    return InstrumentTuning.fromJson(jsonDecode(jsonString));
  }

  InstrumentTuning copyWith({
    String? id,
    String? name,
    InstrumentType? type,
    List<String>? openNotes,
    int? fretCount,
  }) {
    return InstrumentTuning(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      openNotes: openNotes ?? this.openNotes,
      fretCount: fretCount ?? this.fretCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstrumentTuning &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          fretCount == other.fretCount &&
          _listEquals(openNotes, other.openNotes);

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      type.hashCode ^
      fretCount.hashCode ^
      openNotes.hashCode;

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'InstrumentTuning($name, ${openNotes.reversed.join("-")})';
}
