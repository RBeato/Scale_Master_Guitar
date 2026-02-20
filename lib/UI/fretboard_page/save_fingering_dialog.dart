import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/constants/app_theme.dart';
import 'package:scalemasterguitar/models/saved_fingering.dart';
import 'package:scalemasterguitar/services/supabase_service.dart';
import 'package:scalemasterguitar/services/in_app_review_service.dart';
import 'package:uuid/uuid.dart';

class SaveFingeringDialog extends ConsumerStatefulWidget {
  final List<List<bool>> dotPositions;
  final List<List<Color?>> dotColors;
  final String? sharpFlatPreference;
  final bool showNoteNames;
  final Color? fretboardColor;

  const SaveFingeringDialog({
    super.key,
    required this.dotPositions,
    required this.dotColors,
    this.sharpFlatPreference,
    this.showNoteNames = false,
    this.fretboardColor,
  });

  @override
  ConsumerState<SaveFingeringDialog> createState() =>
      _SaveFingeringDialogState();
}

class _SaveFingeringDialogState extends ConsumerState<SaveFingeringDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveFingering() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final supabase = SupabaseService.instance;
      final userId = supabase.currentUserId;

      if (userId == null) {
        _showError('Not signed in. Please restart the app.');
        return;
      }

      final fingering = SavedFingering.fromFretboardState(
        id: const Uuid().v4(),
        userId: userId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        dotPositions: widget.dotPositions,
        dotColors: widget.dotColors,
        sharpFlatPreference: widget.sharpFlatPreference,
        showNoteNames: widget.showNoteNames,
        fretboardColor: widget.fretboardColor,
        isPublic: _isPublic,
      );

      final saved = await supabase.saveFingering(fingering);

      if (saved != null) {
        // Track positive action & request review
        InAppReviewService().trackKeyAction();
        InAppReviewService().requestReviewIfReady();

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isPublic
                    ? 'Fingering saved and shared publicly!'
                    : 'Fingering saved to your library!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showError('Failed to save. Please try again.');
      }
    } catch (e) {
      debugPrint('Error saving fingering: $e');
      _showError('Error saving fingering. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Save to Library',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Name *',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  hintText: 'e.g., C Major Scale, Pentatonic Box 1',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.error),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.error),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  if (value.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  hintText: 'Add notes about this fingering...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Public toggle
              SwitchListTile(
                title: const Text(
                  'Share publicly',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  _isPublic
                      ? 'Others can discover and use this fingering'
                      : 'Only you can see this fingering',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                value: _isPublic,
                onChanged: (value) => setState(() => _isPublic = value),
                activeTrackColor: Colors.lightBlueAccent.withValues(alpha: 0.5),
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.lightBlueAccent;
                  }
                  return Colors.grey;
                }),
                contentPadding: EdgeInsets.zero,
              ),

              // Info text
              const SizedBox(height: 8),
              Text(
                'Your fingering will be saved with the current colors and settings.',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveFingering,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlueAccent,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
