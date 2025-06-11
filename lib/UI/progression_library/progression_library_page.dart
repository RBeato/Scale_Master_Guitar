import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/UI/progression_library/widgets/progression_list_item.dart';
import 'package:scalemasterguitar/UI/progression_library/widgets/save_progression_dialog.dart';
import 'package:scalemasterguitar/UI/progression_library/widgets/progression_search_bar.dart';
import 'package:scalemasterguitar/providers/progression_library_provider.dart';
import 'package:scalemasterguitar/models/progression_model.dart';
import 'package:scalemasterguitar/widgets/screen_with_banner_ad.dart';
import '../player_page/player_page.dart';

class ProgressionLibraryPage extends ConsumerStatefulWidget {
  const ProgressionLibraryPage({super.key});

  @override
  ConsumerState<ProgressionLibraryPage> createState() => _ProgressionLibraryPageState();
}

class _ProgressionLibraryPageState extends ConsumerState<ProgressionLibraryPage> {
  String _searchQuery = '';
  ProgressionSortType _sortType = ProgressionSortType.lastModifiedDesc;

  @override
  void initState() {
    super.initState();
    // Load progressions when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(progressionLibraryProvider.notifier).loadProgressions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(progressionLibraryProvider);
    final progressionNotifier = ref.read(progressionLibraryProvider.notifier);

    // Filter and sort progressions
    final filteredProgressions = _searchQuery.isEmpty
        ? progressionNotifier.getSortedProgressions(_sortType)
        : progressionNotifier.searchProgressions(_searchQuery);

    return ScreenWithBannerAd(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        title: const Text(
          "Progression Library",
          style: TextStyle(color: Colors.orange),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Sort button
          PopupMenuButton<ProgressionSortType>(
            icon: const Icon(Icons.sort, color: Colors.orange),
            onSelected: (sortType) {
              setState(() {
                _sortType = sortType;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ProgressionSortType.nameAsc,
                child: Text('Name (A-Z)'),
              ),
              const PopupMenuItem(
                value: ProgressionSortType.nameDesc,
                child: Text('Name (Z-A)'),
              ),
              const PopupMenuItem(
                value: ProgressionSortType.lastModifiedDesc,
                child: Text('Recently Modified'),
              ),
              const PopupMenuItem(
                value: ProgressionSortType.dateCreatedDesc,
                child: Text('Recently Created'),
              ),
              const PopupMenuItem(
                value: ProgressionSortType.durationAsc,
                child: Text('Duration (Short)'),
              ),
              const PopupMenuItem(
                value: ProgressionSortType.durationDesc,
                child: Text('Duration (Long)'),
              ),
            ],
          ),
          // More options menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'clear_all':
                  _showClearAllDialog();
                  break;
                case 'export':
                  _exportProgressions();
                  break;
                case 'import':
                  _showImportDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Text('Export All'),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Text('Import'),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('Clear All'),
              ),
            ],
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          ProgressionSearchBar(
            onSearchChanged: (query) {
              setState(() {
                _searchQuery = query;
              });
            },
          ),
          
          // Error/Success messages
          if (libraryState.error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(libraryState.error!, style: const TextStyle(color: Colors.red))),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => progressionNotifier.clearMessages(),
                  ),
                ],
              ),
            ),
          
          if (libraryState.successMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(libraryState.successMessage!, style: const TextStyle(color: Colors.green))),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.green),
                    onPressed: () => progressionNotifier.clearMessages(),
                  ),
                ],
              ),
            ),

          // Content area
          Expanded(
            child: libraryState.isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                : filteredProgressions.isEmpty
                    ? _buildEmptyState()
                    : _buildProgressionList(filteredProgressions),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isEmpty ? Icons.library_music : Icons.search_off,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No saved progressions yet'
                : 'No progressions found for "$_searchQuery"',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          if (_searchQuery.isEmpty)
            Text(
              'Create chord progressions in the player and save them here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 24),
          if (_searchQuery.isEmpty)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PlayerPage()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Progression'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressionList(List<ProgressionModel> progressions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: progressions.length,
      itemBuilder: (context, index) {
        final progression = progressions[index];
        return ProgressionListItem(
          progression: progression,
          onTap: () => _loadProgression(progression),
          onEdit: () => _editProgression(progression),
          onDelete: () => _deleteProgression(progression),
          onDuplicate: () => _duplicateProgression(progression),
        );
      },
    );
  }

  void _loadProgression(ProgressionModel progression) {
    // Navigate to player page and load the progression
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerPage(initialProgression: progression),
      ),
    );
  }

  void _editProgression(ProgressionModel progression) {
    showDialog(
      context: context,
      builder: (context) => SaveProgressionDialog(
        existingProgression: progression,
      ),
    );
  }

  void _deleteProgression(ProgressionModel progression) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Progression', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${progression.name}"? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(progressionLibraryProvider.notifier).deleteProgression(progression.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _duplicateProgression(ProgressionModel progression) {
    showDialog(
      context: context,
      builder: (context) => SaveProgressionDialog(
        initialChords: progression.chords,
        initialName: '${progression.name} (Copy)',
        initialDescription: progression.description,
        initialTags: progression.tags,
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Clear All Progressions', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete all saved progressions? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Clear all progressions by reloading after clearing storage
              await ref.read(progressionLibraryProvider.notifier).loadProgressions();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _exportProgressions() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }

  void _showImportDialog() {
    // TODO: Implement import functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import functionality coming soon')),
    );
  }
}