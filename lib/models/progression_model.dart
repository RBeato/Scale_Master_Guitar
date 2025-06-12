import 'dart:convert';
import 'package:scalemasterguitar/models/chord_model.dart';

class ProgressionModel {
  final String id;
  final String name;
  final List<ChordModel> chords;
  final DateTime createdAt;
  final DateTime lastModified;
  final String? description;
  final String? tags;
  final int totalBeats;

  ProgressionModel({
    required this.id,
    required this.name,
    required this.chords,
    required this.createdAt,
    required this.lastModified,
    this.description,
    this.tags,
    required this.totalBeats,
  });

  // Create a copy with updated fields
  ProgressionModel copyWith({
    String? id,
    String? name,
    List<ChordModel>? chords,
    DateTime? createdAt,
    DateTime? lastModified,
    String? description,
    String? tags,
    int? totalBeats,
  }) {
    return ProgressionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      chords: chords ?? this.chords,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      totalBeats: totalBeats ?? this.totalBeats,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'chords': chords.map((chord) => chord.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'description': description,
      'tags': tags,
      'totalBeats': totalBeats,
    };
  }

  // Create from JSON
  factory ProgressionModel.fromJson(Map<String, dynamic> json) {
    return ProgressionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      chords: (json['chords'] as List<dynamic>)
          .map((chordJson) => ChordModel.fromJson(chordJson as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: DateTime.parse(json['lastModified'] as String),
      description: json['description'] as String?,
      tags: json['tags'] as String?,
      totalBeats: json['totalBeats'] as int,
    );
  }

  // Convert to JSON string
  String toJsonString() => jsonEncode(toJson());

  // Create from JSON string
  factory ProgressionModel.fromJsonString(String jsonString) {
    return ProgressionModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  // Generate a unique ID based on timestamp
  static String generateId() {
    return 'prog_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Create a new progression from a list of chords
  factory ProgressionModel.fromChords({
    required String name,
    required List<ChordModel> chords,
    String? description,
    String? tags,
  }) {
    final now = DateTime.now();
    final totalBeats = chords.isNotEmpty 
        ? chords.fold<int>(0, (prev, chord) => prev + chord.duration)
        : 0;

    return ProgressionModel(
      id: generateId(),
      name: name,
      chords: chords,
      createdAt: now,
      lastModified: now,
      description: description,
      tags: tags,
      totalBeats: totalBeats,
    );
  }

  // Get a formatted display string for duration
  String get formattedDuration {
    if (totalBeats == 0) return '0 beats';
    if (totalBeats == 1) return '1 beat';
    return '$totalBeats beats';
  }

  // Get a preview of chord names
  String get chordsPreview {
    if (chords.isEmpty) return 'No chords';
    if (chords.length <= 4) {
      return chords.map((c) => c.completeChordName ?? 'Unknown').join(' - ');
    }
    return '${chords.take(3).map((c) => c.completeChordName ?? 'Unknown').join(' - ')}...';
  }

  // Check if progression is empty
  bool get isEmpty => chords.isEmpty;

  @override
  String toString() {
    return 'ProgressionModel(id: $id, name: $name, chords: ${chords.length}, totalBeats: $totalBeats)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProgressionModel &&
        other.id == id &&
        other.name == name &&
        other.totalBeats == totalBeats;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ totalBeats.hashCode;
  }
}