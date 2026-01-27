import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scalemasterguitar/constants/app_theme.dart';
import 'package:scalemasterguitar/models/saved_fingering.dart';
import 'package:scalemasterguitar/UI/fingerings_library/fingering_preview.dart';

/// Card widget for displaying a saved fingering in the library
class FingeringCard extends StatelessWidget {
  final SavedFingering fingering;
  final bool isOwner;
  final VoidCallback? onTap;
  final VoidCallback? onLoad;
  final VoidCallback? onDelete;
  final VoidCallback? onTogglePublic;
  final VoidCallback? onToggleLike;

  const FingeringCard({
    super.key,
    required this.fingering,
    this.isOwner = false,
    this.onTap,
    this.onLoad,
    this.onDelete,
    this.onTogglePublic,
    this.onToggleLike,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview
              FingeringPreview(
                fingering: fingering,
                width: double.infinity,
                height: 80,
                showFretNumbers: true,
              ),
              const SizedBox(height: 12),

              // Name and visibility indicator
              Row(
                children: [
                  Expanded(
                    child: Text(
                      fingering.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isOwner)
                    Icon(
                      fingering.isPublic ? Icons.public : Icons.lock_outline,
                      size: 18,
                      color: fingering.isPublic
                          ? Colors.lightBlueAccent
                          : Colors.grey,
                    ),
                ],
              ),

              // Description
              if (fingering.description != null &&
                  fingering.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  fingering.description!,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 8),

              // Stats and actions row
              Row(
                children: [
                  // Like button (for public fingerings)
                  if (!isOwner || fingering.isPublic) ...[
                    InkWell(
                      onTap: onToggleLike,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              fingering.isLikedByUser
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                              color: fingering.isLikedByUser
                                  ? Colors.redAccent
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${fingering.likesCount}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Loads count
                  if (fingering.loadsCount > 0) ...[
                    Icon(
                      Icons.download_outlined,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${fingering.loadsCount}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Date
                  Expanded(
                    child: Text(
                      _formatDate(fingering.createdAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ),

                  // Action buttons
                  if (isOwner) ...[
                    // Toggle public
                    IconButton(
                      onPressed: onTogglePublic,
                      icon: Icon(
                        fingering.isPublic
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                      ),
                      color: Colors.grey[400],
                      tooltip:
                          fingering.isPublic ? 'Make private' : 'Share publicly',
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    // Delete
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                      ),
                      color: Colors.grey[400],
                      tooltip: 'Delete',
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],

                  // Load button
                  ElevatedButton.icon(
                    onPressed: onLoad,
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Load'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
