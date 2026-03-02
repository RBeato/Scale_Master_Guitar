import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';
import '../../../constants/music_constants.dart';
import '../../../models/drone_chord.dart';

class DroneChordSelector extends StatefulWidget {
  final DroneChord? currentChord;
  final ValueChanged<DroneChord> onChordSelected;

  const DroneChordSelector({
    super.key,
    this.currentChord,
    required this.onChordSelected,
  });

  @override
  State<DroneChordSelector> createState() => _DroneChordSelectorState();
}

class _DroneChordSelectorState extends State<DroneChordSelector> {
  late String _selectedRoot;
  late String _selectedQuality;
  late int _selectedOctave;

  @override
  void initState() {
    super.initState();
    _selectedRoot = 'C';
    _selectedQuality = 'Major';
    _selectedOctave = 4;
  }

  void _apply() {
    final chord = DroneChord.fromRootAndQuality(
      _selectedRoot,
      _selectedQuality,
      octave: _selectedOctave,
    );
    widget.onChordSelected(chord);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          const Text(
            'Custom Drone Chord',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // Root Note Selector
          const Text(
            'Root Note',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: MusicConstants.notesWithFlats.map((note) {
                final isSelected = note == _selectedRoot;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRoot = note),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.orangeAccent
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? null
                            : Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        note,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Chord Quality Selector
          const Text(
            'Chord Type',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: DroneChord.availableQualities.map((quality) {
              final isSelected = quality == _selectedQuality;
              return GestureDetector(
                onTap: () => setState(() => _selectedQuality = quality),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.orangeAccent
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        isSelected ? null : Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    quality,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Octave Selector
          Row(
            children: [
              const Text(
                'Octave',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const Spacer(),
              IconButton(
                onPressed: _selectedOctave > 3
                    ? () => setState(() => _selectedOctave--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline, size: 22),
                color: Colors.white70,
                disabledColor: Colors.white24,
              ),
              Text(
                '$_selectedOctave',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: _selectedOctave < 5
                    ? () => setState(() => _selectedOctave++)
                    : null,
                icon: const Icon(Icons.add_circle_outline, size: 22),
                color: Colors.white70,
                disabledColor: Colors.white24,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Apply',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
