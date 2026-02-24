import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/constants/instrument_presets.dart';
import 'package:scalemasterguitar/models/instrument_tuning.dart';
import 'package:scalemasterguitar/providers/custom_tunings_provider.dart';
import 'package:scalemasterguitar/providers/tuning_provider.dart';
import 'package:uuid/uuid.dart';

class CustomTuningCreator extends ConsumerStatefulWidget {
  const CustomTuningCreator({super.key});

  @override
  ConsumerState<CustomTuningCreator> createState() =>
      _CustomTuningCreatorState();
}

class _CustomTuningCreatorState extends ConsumerState<CustomTuningCreator> {
  final _nameController = TextEditingController(text: 'My Custom Tuning');
  int _stringCount = 6;
  late List<String> _openNotes;

  // Standard guitar tuning as starting point (high to low)
  static const _defaultNotes = ['E', 'B', 'G', 'D', 'A', 'E', 'B', 'F#'];

  @override
  void initState() {
    super.initState();
    _openNotes = List.from(_defaultNotes);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Create Custom Tuning',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name field
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Tuning Name',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // String count selector
            Row(
              children: [
                const Text(
                  'Number of strings: ',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(width: 8),
                _buildStringCountButton(4),
                _buildStringCountButton(5),
                _buildStringCountButton(6),
                _buildStringCountButton(7),
                _buildStringCountButton(8),
              ],
            ),
            const SizedBox(height: 16),

            // Per-string note selectors
            const Text(
              'String Tuning (low to high):',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            // Display from LOW string to HIGH string for user clarity
            ...List.generate(_stringCount, (index) {
              // Reverse order: index 0 = lowest string = last in openNotes
              final stringIndex = _stringCount - 1 - index;
              return _buildStringNoteSelector(
                stringNumber: _stringCount - index,
                noteIndex: stringIndex,
              );
            }),
            const SizedBox(height: 16),

            // Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tuning: ${_openNotes.sublist(0, _stringCount).reversed.join(" - ")}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _saveTuning,
                child: const Text('Save & Apply Tuning'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStringCountButton(int count) {
    final isSelected = _stringCount == count;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () {
          setState(() {
            _stringCount = count;
          });
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Colors.orange
                  : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStringNoteSelector({
    required int stringNumber,
    required int noteIndex,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              'String $stringNumber',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: InstrumentPresets.chromaticNotes.length,
                itemBuilder: (context, i) {
                  final note = InstrumentPresets.chromaticNotes[i];
                  final isSelected = _openNotes[noteIndex] == note;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _openNotes[noteIndex] = note;
                        });
                      },
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 32),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.orange
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? Colors.orange
                                : Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          note,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isSelected ? Colors.white : Colors.grey,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveTuning() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final tuning = InstrumentTuning(
      id: 'custom_${const Uuid().v4()}',
      name: name,
      type: InstrumentType.custom,
      openNotes: _openNotes.sublist(0, _stringCount),
      fretCount: 24,
    );

    ref.read(customTuningsProvider.notifier).addTuning(tuning);
    ref.read(tuningProvider.notifier).setTuning(tuning);

    Navigator.pop(context);
  }
}
