import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/models/progression_model.dart';
import 'package:scalemasterguitar/models/chord_model.dart';
import 'package:scalemasterguitar/providers/progression_library_provider.dart';
import 'package:scalemasterguitar/constants/app_theme.dart';

class SaveProgressionDialog extends ConsumerStatefulWidget {
  final List<ChordModel>? initialChords;
  final String? initialName;
  final String? initialDescription;
  final String? initialTags;
  final ProgressionModel? existingProgression;

  const SaveProgressionDialog({
    super.key,
    this.initialChords,
    this.initialName,
    this.initialDescription,
    this.initialTags,
    this.existingProgression,
  });

  @override
  ConsumerState<SaveProgressionDialog> createState() => _SaveProgressionDialogState();
}

class _SaveProgressionDialogState extends ConsumerState<SaveProgressionDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _nameFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _tagsFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.existingProgression != null) {
      _nameController.text = widget.existingProgression!.name;
      _descriptionController.text = widget.existingProgression!.description ?? '';
      _tagsController.text = widget.existingProgression!.tags ?? '';
    } else {
      _nameController.text = widget.initialName ?? '';
      _descriptionController.text = widget.initialDescription ?? '';
      _tagsController.text = widget.initialTags ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _nameFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _tagsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingProgression != null;

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside text fields
        FocusScope.of(context).unfocus();
      },
      child: AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          isEditing ? 'Edit Progression' : 'Save Progression',
          style: const TextStyle(color: Colors.white),
        ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name field
              TextFormField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                autofocus: false,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Name *',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: 'Enter progression name',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Description field
              TextFormField(
                controller: _descriptionController,
                focusNode: _descriptionFocusNode,
                autofocus: false,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: 'Optional description...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Tags field
              TextFormField(
                controller: _tagsController,
                focusNode: _tagsFocusNode,
                autofocus: false,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Tags',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: 'jazz, blues, rock (comma-separated)',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                ),
              ),
              
              // Preview info
              if (!isEditing && widget.initialChords != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Progression Preview:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getProgressionPreview(),
                        style: const TextStyle(color: Colors.orange),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.initialChords!.length} chords, ${_getTotalBeats()} beats',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            ),
          ),
        ),
        ),
        actions: [
        TextButton(
          onPressed: _isLoading ? null : () {
            FocusScope.of(context).unfocus();
            Navigator.pop(context);
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProgression,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(isEditing ? 'Update' : 'Save'),
        ),
      ],
      ),
    );
  }

  String _getProgressionPreview() {
    if (widget.initialChords == null || widget.initialChords!.isEmpty) {
      return 'No chords';
    }
    
    final chordNames = widget.initialChords!
        .map((chord) => chord.completeChordName ?? chord.noteName)
        .toList();
    
    if (chordNames.length <= 4) {
      return chordNames.join(' - ');
    }
    
    return '${chordNames.take(3).join(' - ')}...';
  }

  int _getTotalBeats() {
    if (widget.initialChords == null) return 0;
    return widget.initialChords!.fold<int>(
      0,
      (total, chord) => total + chord.duration,
    );
  }

  Future<void> _saveProgression() async {
    if (!_formKey.currentState!.validate()) return;

    // Dismiss keyboard before saving
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final tags = _tagsController.text.trim();

      final progressionNotifier = ref.read(progressionLibraryProvider.notifier);
      bool success = false;

      if (widget.existingProgression != null) {
        // Update existing progression
        final updatedProgression = widget.existingProgression!.copyWith(
          name: name,
          description: description.isEmpty ? null : description,
          tags: tags.isEmpty ? null : tags,
        );
        success = await progressionNotifier.updateProgression(updatedProgression);
      } else {
        // Create new progression
        final chords = widget.initialChords ?? [];
        final progression = ProgressionModel.fromChords(
          name: name,
          chords: chords,
          description: description.isEmpty ? null : description,
          tags: tags.isEmpty ? null : tags,
        );
        success = await progressionNotifier.saveProgression(progression);
      }

      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving progression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}