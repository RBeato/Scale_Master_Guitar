import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/constants/app_theme.dart';
import 'package:scalemasterguitar/models/saved_fingering.dart';
import 'package:scalemasterguitar/services/supabase_service.dart';
import 'package:scalemasterguitar/UI/fingerings_library/fingering_card.dart';

enum LibraryTab { myFingerings, publicLibrary }

class FingeringsLibraryPage extends ConsumerStatefulWidget {
  final Function(SavedFingering)? onLoadFingering;

  const FingeringsLibraryPage({
    super.key,
    this.onLoadFingering,
  });

  @override
  ConsumerState<FingeringsLibraryPage> createState() =>
      _FingeringsLibraryPageState();
}

class _FingeringsLibraryPageState extends ConsumerState<FingeringsLibraryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  List<SavedFingering> _myFingerings = [];
  List<SavedFingering> _publicFingerings = [];
  bool _isLoadingMy = false;
  bool _isLoadingPublic = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadMyFingerings();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    if (_tabController.index == 0 && _myFingerings.isEmpty) {
      _loadMyFingerings();
    } else if (_tabController.index == 1 && _publicFingerings.isEmpty) {
      _loadPublicFingerings();
    }
  }

  Future<void> _loadMyFingerings() async {
    if (_isLoadingMy) return;

    setState(() => _isLoadingMy = true);

    try {
      final supabase = SupabaseService.instance;
      final fingerings = await supabase.getUserFingerings();
      if (mounted) {
        setState(() {
          _myFingerings = fingerings;
          _isLoadingMy = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading my fingerings: $e');
      if (mounted) {
        setState(() => _isLoadingMy = false);
      }
    }
  }

  Future<void> _loadPublicFingerings() async {
    if (_isLoadingPublic) return;

    setState(() => _isLoadingPublic = true);

    try {
      final supabase = SupabaseService.instance;
      final fingerings = await supabase.getPublicFingerings(
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        sortBy: 'likes_count',
      );
      if (mounted) {
        setState(() {
          _publicFingerings = fingerings;
          _isLoadingPublic = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading public fingerings: $e');
      if (mounted) {
        setState(() => _isLoadingPublic = false);
      }
    }
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query);
    if (_tabController.index == 1) {
      _loadPublicFingerings();
    }
  }

  Future<void> _deleteFingering(SavedFingering fingering) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Fingering',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${fingering.name}"?',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final supabase = SupabaseService.instance;
    final success = await supabase.deleteFingering(fingering.id);

    if (success && mounted) {
      setState(() {
        _myFingerings.removeWhere((f) => f.id == fingering.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fingering deleted'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _togglePublic(SavedFingering fingering) async {
    final supabase = SupabaseService.instance;
    final newValue = await supabase.togglePublic(fingering.id);

    if (mounted) {
      setState(() {
        final index = _myFingerings.indexWhere((f) => f.id == fingering.id);
        if (index != -1) {
          _myFingerings[index] =
              _myFingerings[index].copyWith(isPublic: newValue);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(newValue ? 'Fingering shared publicly' : 'Fingering is now private'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _toggleLike(SavedFingering fingering) async {
    final supabase = SupabaseService.instance;
    final isNowLiked = await supabase.toggleLike(fingering.id);

    if (mounted) {
      setState(() {
        // Update in public list
        final publicIndex =
            _publicFingerings.indexWhere((f) => f.id == fingering.id);
        if (publicIndex != -1) {
          final current = _publicFingerings[publicIndex];
          _publicFingerings[publicIndex] = current.copyWith(
            isLikedByUser: isNowLiked,
            likesCount: current.likesCount + (isNowLiked ? 1 : -1),
          );
        }

        // Update in my list if exists
        final myIndex = _myFingerings.indexWhere((f) => f.id == fingering.id);
        if (myIndex != -1) {
          final current = _myFingerings[myIndex];
          _myFingerings[myIndex] = current.copyWith(
            isLikedByUser: isNowLiked,
            likesCount: current.likesCount + (isNowLiked ? 1 : -1),
          );
        }
      });
    }
  }

  void _loadFingering(SavedFingering fingering) {
    // Increment load count
    SupabaseService.instance.incrementLoadCount(fingering.id);

    if (widget.onLoadFingering != null) {
      widget.onLoadFingering!(fingering);
      Navigator.pop(context);
    } else {
      // Return the fingering to the previous screen
      Navigator.pop(context, fingering);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Fingerings Library',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.lightBlueAccent,
          labelColor: Colors.lightBlueAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'My Fingerings'),
            Tab(text: 'Public Library'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar (only for public tab)
          if (_tabController.index == 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search fingerings...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[500]),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: _onSearch,
              ),
            ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyFingeringsTab(),
                _buildPublicLibraryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyFingeringsTab() {
    if (_isLoadingMy) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.lightBlueAccent),
      );
    }

    if (_myFingerings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_music, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No saved fingerings yet',
              style: TextStyle(color: Colors.grey[400], fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Save fingerings from the fretboard page',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    final supabase = SupabaseService.instance;
    final currentUserId = supabase.currentUserId;

    return RefreshIndicator(
      onRefresh: _loadMyFingerings,
      color: Colors.lightBlueAccent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myFingerings.length,
        itemBuilder: (context, index) {
          final fingering = _myFingerings[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FingeringCard(
              fingering: fingering,
              isOwner: fingering.userId == currentUserId,
              onLoad: () => _loadFingering(fingering),
              onDelete: () => _deleteFingering(fingering),
              onTogglePublic: () => _togglePublic(fingering),
              onToggleLike: () => _toggleLike(fingering),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPublicLibraryTab() {
    if (_isLoadingPublic) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.lightBlueAccent),
      );
    }

    if (_publicFingerings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No fingerings found'
                  : 'No public fingerings yet',
              style: TextStyle(color: Colors.grey[400], fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share your fingerings!',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    final supabase = SupabaseService.instance;
    final currentUserId = supabase.currentUserId;

    return RefreshIndicator(
      onRefresh: _loadPublicFingerings,
      color: Colors.lightBlueAccent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _publicFingerings.length,
        itemBuilder: (context, index) {
          final fingering = _publicFingerings[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FingeringCard(
              fingering: fingering,
              isOwner: fingering.userId == currentUserId,
              onLoad: () => _loadFingering(fingering),
              onDelete: fingering.userId == currentUserId
                  ? () => _deleteFingering(fingering)
                  : null,
              onTogglePublic: fingering.userId == currentUserId
                  ? () => _togglePublic(fingering)
                  : null,
              onToggleLike: () => _toggleLike(fingering),
            ),
          );
        },
      ),
    );
  }
}
