import 'package:flutter/material.dart';

/// Model representing a saved fingering pattern that can be stored in Supabase
class SavedFingering {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final List<List<bool>> dotPositions; // 6 strings x 25 frets
  final List<List<String?>> dotColors; // 6 strings x 25 frets (hex colors)
  final String? sharpFlatPreference; // 'sharps' | 'flats' | null
  final bool showNoteNames;
  final String? fretboardColor; // hex color
  final bool isPublic;
  final int likesCount;
  final int loadsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  bool isLikedByUser; // computed field, not stored in DB

  SavedFingering({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.dotPositions,
    required this.dotColors,
    this.sharpFlatPreference,
    this.showNoteNames = false,
    this.fretboardColor,
    this.isPublic = false,
    this.likesCount = 0,
    this.loadsCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isLikedByUser = false,
  });

  /// Create from Supabase JSON response
  factory SavedFingering.fromJson(Map<String, dynamic> json) {
    // Parse dot_positions from JSONB
    final rawPositions = json['dot_positions'] as List<dynamic>;
    final dotPositions = rawPositions.map((row) {
      return (row as List<dynamic>).map((val) => val as bool).toList();
    }).toList();

    // Parse dot_colors from JSONB
    final rawColors = json['dot_colors'] as List<dynamic>;
    final dotColors = rawColors.map((row) {
      return (row as List<dynamic>).map((val) => val as String?).toList();
    }).toList();

    return SavedFingering(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      dotPositions: dotPositions,
      dotColors: dotColors,
      sharpFlatPreference: json['sharp_flat_preference'] as String?,
      showNoteNames: json['show_note_names'] as bool? ?? false,
      fretboardColor: json['fretboard_color'] as String?,
      isPublic: json['is_public'] as bool? ?? false,
      likesCount: json['likes_count'] as int? ?? 0,
      loadsCount: json['loads_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isLikedByUser: json['is_liked_by_user'] as bool? ?? false,
    );
  }

  /// Convert to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'description': description,
      'dot_positions': dotPositions,
      'dot_colors': dotColors,
      'sharp_flat_preference': sharpFlatPreference,
      'show_note_names': showNoteNames,
      'fretboard_color': fretboardColor,
      'is_public': isPublic,
    };
  }

  /// Create from current fretboard state
  factory SavedFingering.fromFretboardState({
    required String id,
    required String userId,
    required String name,
    String? description,
    required List<List<bool>> dotPositions,
    required List<List<Color?>> dotColors,
    String? sharpFlatPreference,
    bool showNoteNames = false,
    Color? fretboardColor,
    bool isPublic = false,
  }) {
    // Convert Colors to hex strings
    final hexColors = dotColors.map((row) {
      return row.map((color) {
        if (color == null) return null;
        return '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
      }).toList();
    }).toList();

    // Convert fretboard color to hex
    String? fretboardHex;
    if (fretboardColor != null) {
      fretboardHex =
          '#${fretboardColor.toARGB32().toRadixString(16).padLeft(8, '0')}';
    }

    final now = DateTime.now();
    return SavedFingering(
      id: id,
      userId: userId,
      name: name,
      description: description,
      dotPositions: dotPositions,
      dotColors: hexColors,
      sharpFlatPreference: sharpFlatPreference,
      showNoteNames: showNoteNames,
      fretboardColor: fretboardHex,
      isPublic: isPublic,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Get dot colors as Flutter Color objects
  List<List<Color?>> getDotColorsAsColors() {
    return dotColors.map((row) {
      return row.map((hex) {
        if (hex == null) return null;
        return _hexToColor(hex);
      }).toList();
    }).toList();
  }

  /// Get fretboard color as Flutter Color object
  Color? getFretboardColorAsColor() {
    if (fretboardColor == null) return null;
    return _hexToColor(fretboardColor!);
  }

  /// Convert hex string to Color
  static Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add full opacity if not specified
    }
    return Color(int.parse(hex, radix: 16));
  }

  /// Create a copy with updated fields
  SavedFingering copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    List<List<bool>>? dotPositions,
    List<List<String?>>? dotColors,
    String? sharpFlatPreference,
    bool? showNoteNames,
    String? fretboardColor,
    bool? isPublic,
    int? likesCount,
    int? loadsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLikedByUser,
  }) {
    return SavedFingering(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      dotPositions: dotPositions ?? this.dotPositions,
      dotColors: dotColors ?? this.dotColors,
      sharpFlatPreference: sharpFlatPreference ?? this.sharpFlatPreference,
      showNoteNames: showNoteNames ?? this.showNoteNames,
      fretboardColor: fretboardColor ?? this.fretboardColor,
      isPublic: isPublic ?? this.isPublic,
      likesCount: likesCount ?? this.likesCount,
      loadsCount: loadsCount ?? this.loadsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
    );
  }

  /// Check if the fingering has any dots
  bool get hasDots {
    for (final row in dotPositions) {
      for (final dot in row) {
        if (dot) return true;
      }
    }
    return false;
  }

  /// Get the count of dots in this fingering
  int get dotCount {
    int count = 0;
    for (final row in dotPositions) {
      for (final dot in row) {
        if (dot) count++;
      }
    }
    return count;
  }

  @override
  String toString() {
    return 'SavedFingering(id: $id, name: $name, dots: $dotCount, public: $isPublic)';
  }
}
