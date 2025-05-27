import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sequencer/track.dart';
import 'package:scalemasterguitar/UI/player_page/provider/selected_chords_provider.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';

import '../../../revenue_cat_purchase_flutter/entitlement.dart';
import '../chords_list.dart';
import '../metronome/metronome_display.dart';
import '../metronome/metronome_icon.dart';

class ChordPlayerBar extends ConsumerStatefulWidget {
  const ChordPlayerBar({
    super.key,
    required this.selectedTrack,
    required this.isPlaying,
    required this.isLoading,
    required this.tempo,
    required this.isLooping,
    required this.handleTogglePlayStop,
    required this.clearTracks,
  });

  final bool isPlaying;
  final Track? selectedTrack;
  final bool isLoading;
  final bool isLooping;
  final double tempo;
  final Function() clearTracks;
  final Function() handleTogglePlayStop;

  @override
  ChordPlayerBarState createState() => ChordPlayerBarState();
}

class ChordPlayerBarState extends ConsumerState<ChordPlayerBar> {
  bool _showNoChordSelected = false;

  @override
  Widget build(BuildContext context) {
    final selectedChords = ref.watch(selectedChordsProvider);
    // final entitlement = ref.watch(revenueCatProvider);

    //TODO: Revert this
    final entitlement = Entitlement.premium;

    // Reset _showNoChordSelected when there are changes in selectedChords
    if (selectedChords.isNotEmpty) {
      _showNoChordSelected = false;
    }

    if (widget.selectedTrack == null || selectedChords.isEmpty) {
      if (!_showNoChordSelected) {
        // Show CircularProgressIndicator for 500ms
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _showNoChordSelected = true;
            });
          }
        });
        return const Center(
            child: CircularProgressIndicator(
          color: Colors.orangeAccent,
        ));
      } else {
        // Show "No chord selected!" after the delay
        return const Center(
          child: Text(
            "No chord selected!",
            style: TextStyle(color: Colors.white),
          ),
        );
      }
    }

    if (widget.isLoading) {
      return const Center(
          child: CircularProgressIndicator(
        color: Colors.orangeAccent,
      ));
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          // SEQUENCER
          Opacity(
            opacity: 0.85,
            child: ChordListWidget(chordList: selectedChords),
          ),
          //CLEAR DRUMS BUTTON and TRANSPORT
          Positioned(
            left: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: GestureDetector(
                onTap: entitlement == Entitlement.free
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Upgrade required to use this feature.')),
                        );
                      }
                    : widget.handleTogglePlayStop,
                child: Icon(
                  widget.isPlaying ? Icons.stop : Icons.play_arrow,
                  color: Colors.white70,
                  size: 40,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: widget.clearTracks,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever,
                  size: 30,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 70,
                height: 30.0,
                child: MetronomeDisplay(
                  selectedTempo: widget.tempo,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: MetronomeButton(),
          ),
        ],
      ),
    );
  }
}
